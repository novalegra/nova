//
//  File.swift
//  Nova
//
//  Created by Anna Quinlan on 10/23/22.
//  Copyright © 2022 Anna Quinlan. All rights reserved.
//

import Foundation

class VolumeViewModel: ObservableObject {
    @Published var selected: MenstrualPoint.ID? = nil
    
    let points: [MenstrualPoint]
    let title: String
    let xAxisLabel: String
    
    init(points: [MenstrualPoint], type: ChartType) {
        self.points = points
        self.title = type.title
        self.xAxisLabel = type.xAxisLabel
    }
    
    func point(id: MenstrualPoint.ID) -> MenstrualPoint? {
        points.first(where: { $0.id == id })
    }
    
    func point(titled title: String) -> MenstrualPoint? {
        points.first(where: { $0.description == title })
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
    var totalVolumePoint: MenstrualPoint {
        MenstrualPoint(start: startDate, end: endDate, flowVolume: totalFlow)
    }
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
                let nilReturn: MenstrualPoint? = nil // FIXME: this explicit type is needed to avoid compiler error
                return nilReturn
            }
            
            let dateNum = idx + 1
            
            return MenstrualPoint(
                uniqueTitle: String(dateNum),
                detailedTitle: "Day \(dateNum)", // ANNA TODO: localize
                flowVolume: volume
            )
        }
        
        return VolumeViewModel(points: points, type: .dailyVolume)
    }
}
