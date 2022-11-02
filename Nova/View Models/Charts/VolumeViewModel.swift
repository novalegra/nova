//
//  File.swift
//  Nova
//
//  Created by Anna Quinlan on 10/23/22.
//  Copyright © 2022 Anna Quinlan. All rights reserved.
//

import Foundation

struct MenstrualVolumePoint: Identifiable {
    let start: Date
    let end: Date
    let flowVolume: Double
    
    var title: String {
        start.formatted(
            .dateTime
            .month(.twoDigits).day()
        ) + "-" + end.formatted(
            .dateTime
            .month(.twoDigits).day()
        )
    }
    
    var id: Date {
        start
    }
}

class TotalVolumeViewModel: ObservableObject {
    let points: [MenstrualVolumePoint]
    
    init(points: [MenstrualVolumePoint]) {
        self.points = points
    }
}

fileprivate extension MenstrualPeriod {
    var totalVolumePoint: MenstrualVolumePoint {
        MenstrualVolumePoint(start: startDate, end: endDate, flowVolume: totalFlow)
    }
}

extension MenstrualDataManager {
    func makeTotalVolumeViewModel() -> TotalVolumeViewModel {
        TotalVolumeViewModel(points: periods.map { $0.totalVolumePoint })
    }
}
