//
//  File.swift
//  Nova
//
//  Created by Anna Quinlan on 10/23/22.
//  Copyright © 2022 Anna Quinlan. All rights reserved.
//

import Foundation

struct MenstrualVolumePoint: Identifiable {
    let title: String
    private let description: String?
    let flowVolume: Double
    
    init(start: Date, end: Date, flowVolume: Double) {
        let startString = start.formatted(
            .dateTime
            .month(.twoDigits).day()
        )
        
        let endString = end.formatted(
            .dateTime
            .month(.twoDigits).day()
        )
        
        // FIXME: hack since SwiftCharts cuts off strings
        let startEndSpacer = "\n" + String(repeating: " ", count: max(0, startString.count - 1)) + "-\n"
        
        self.init(uniqueTitle: startString + startEndSpacer + endString,
                  description: startString + "-" + endString,
                  flowVolume: flowVolume)
    }
    
    /// `uniqueTitle` will be displayed on the axis and `description` will be displayed when a user scrubs over
    init(uniqueTitle: String, description: String? = nil, flowVolume: Double) {
        self.title = uniqueTitle
        self.description = description
        self.flowVolume = flowVolume
    }
    
    var id: String {
        title
    }
    
    var detailDescription: String {
        "\(flowVolume) mL \n\(description ?? title)"
    }
}

class VolumeViewModel: ObservableObject {
    @Published var selected: MenstrualVolumePoint.ID? = nil
    
    let points: [MenstrualVolumePoint]
    let title: String
    let xAxisLabel: String
    
    init(points: [MenstrualVolumePoint], type: ChartType) {
        self.points = points
        self.title = type.title
        self.xAxisLabel = type.xAxisLabel
    }
    
    func point(id: MenstrualVolumePoint.ID) -> MenstrualVolumePoint? {
        points.first(where: { $0.id == id })
    }
    
    func point(titled title: String) -> MenstrualVolumePoint? {
        points.first(where: { $0.title == title })
    }
    
    func didSelect(title: String) {
        if let point = point(titled: title), point.id != selected {
            selected = point.id
        /// If it's a repeat-tap event, deselect
        } else {
            selected = nil
        }
    }
    
    func didSlideOver(title: String) {
        if let point = point(titled: title) {
            selected = point.id
        }
    }
    
    func didFinishSelecting() {
        selected = nil
    }
}

fileprivate extension MenstrualPeriod {
    var totalVolumePoint: MenstrualVolumePoint {
        MenstrualVolumePoint(start: startDate, end: endDate, flowVolume: totalFlow)
    }
}

extension MenstrualDataManager {
    func makeTotalVolumeViewModel() -> VolumeViewModel {
        VolumeViewModel(points: periods.map { $0.totalVolumePoint },
                        type: .totalVolume)
    }
    
    func makeDailyVolumeViewModel() -> VolumeViewModel {
        guard
            let maxPeriodLength = periods.map({ $0.duration }).max(),
            maxPeriodLength > 0
        else {
            return VolumeViewModel(points: [], type: .dailyVolume)
        }
        
        let volumesByDay = (0...maxPeriodLength-1).map({ dayNumber in
            periods
                .filter { $0.events.count >  dayNumber }
                .compactMap { $0.events[dayNumber].volume }
                .average()
        })
        
        let points = volumesByDay.enumerated().compactMap { (idx, volume) in
            guard volume > 0 else {
                let nilReturn: MenstrualVolumePoint? = nil // FIXME: this explicit type is needed to avoid compiler error
                return nilReturn
            }
            
            let dateNum = idx + 1
            
            return MenstrualVolumePoint(
                uniqueTitle: String(dateNum),
                description: "Day \(dateNum)", // ANNA TODO: localize
                flowVolume: volume
            )
        }
        
        return VolumeViewModel(points: points, type: .dailyVolume)
    }
}
