//
//  ScrollableBarChartViewModel.swift
//  Nova
//
//  Created by Anna Quinlan on 10/23/22.
//  Copyright © 2022 Anna Quinlan. All rights reserved.
//

import Foundation
import Charts

// TODO: unit test chart interactivity
class ScrollableBarChartViewModel: ObservableObject {
    @Published var selected: ScrollableChartPoint.ID? = nil
    
    let points: [ScrollableChartPoint]
    let title: String
    let xAxisLabel: String
    
    var selectionDetailPosition: AnnotationPosition? {
        guard let selected else {
            return nil
        }
        
        /// Avoid the first description being cut off
        return selected == points.first?.id ? .trailing : .leading
    }
    
    init(points: [ScrollableChartPoint], type: ChartType) {
        self.points = points
        self.title = type.title
        self.xAxisLabel = type.xAxisLabel
    }
    
    func point(id: ScrollableChartPoint.ID) -> ScrollableChartPoint? {
        points.first(where: { $0.id == id })
    }
    
    func point(titled title: String) -> ScrollableChartPoint? {
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
    var totalVolumePoint: ScrollableChartPoint {
        ScrollableChartPoint(start: startDate, end: endDate, flowVolume: totalFlow)
    }
    
    var lengthPoint: ScrollableChartPoint {
        ScrollableChartPoint(start: startDate, end: endDate, days: duration)
    }
}

extension MenstrualDataManager {
    func makeTotalVolumeViewModel() -> ScrollableBarChartViewModel {
        ScrollableBarChartViewModel(points: periods.map { $0.totalVolumePoint },
                        type: .totalVolume)
    }
    
    func makePeriodLengthViewModel() -> ScrollableBarChartViewModel {
        ScrollableBarChartViewModel(points: periods.map { $0.lengthPoint },
                        type: .periodLength)
    }
    
    func makeDailyVolumeViewModel() -> ScrollableBarChartViewModel {
        guard
            let maxPeriodLength = periods.map({ $0.duration }).max(),
            maxPeriodLength > 0
        else {
            return ScrollableBarChartViewModel(points: [], type: .dailyVolume)
        }
        
        let volumesByDay = (0...maxPeriodLength-1).map({ dayNumber in
            periods
                .filter { $0.events.count >  dayNumber }
                .compactMap { $0.events[dayNumber].volume }
                .average()
        })
        
        let points = volumesByDay.enumerated().compactMap { (idx, volume) in
            guard volume > 0 else {
                let nilReturn: ScrollableChartPoint? = nil // FIXME: this explicit type is needed to avoid compiler error
                return nilReturn
            }
            
            let dateNum = idx + 1
            
            return ScrollableChartPoint(
                uniqueDescription: String(dateNum),
                detailedDescription: "Day \(dateNum)",
                flowVolume: volume
            )
        }
        
        return ScrollableBarChartViewModel(points: points, type: .dailyVolume)
    }
}