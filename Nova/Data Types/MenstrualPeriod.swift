//
//  MenstrualPeriod.swift
//  Nova
//
//  Created by Anna Quinlan on 9/12/20.
//  Copyright © 2020 Anna Quinlan. All rights reserved.
//

import Foundation

class MenstrualPeriod {
    let events: [MenstrualSample]
    let startDate: Date
    let endDate: Date
    
    init(events: [MenstrualSample]) {
        guard
            let minDate = events.min(by: { $0.startDate < $1.startDate })?.startDate,
            let maxDate = events.max(by: { $0.startDate < $1.startDate })?.startDate
        else {
            fatalError("Tried to init menstrual period without any events")
        }

        self.events = events
        self.startDate = minDate
        self.endDate = maxDate
    }
    
    var totalFlow: Double {
        return events.reduce(0) {sum, event in
            let volume = flow(event)
            if volume != -1 {
                return sum + volume
            }
            return sum
        }
    }
    
    var averageDailyFlow: Double {
        var totalVolume = 0.0
        var totalEvents = 0.0
        
        for event in events {
            let volume = flow(event)
            if volume != -1 {
                totalVolume += volume
                totalEvents += 1
            }
        }
        
        guard totalEvents > 0 else {
            return 0
        }
        
        return totalVolume / totalEvents
    }
    
    private func flow(_ event: MenstrualSample) -> Double {
        if event.flowLevel != .none, let volume = event.volume, volume > 0 {
            return volume
        }
        return -1
    }
    
    // Duration of period in days
    var duration: Int {
        guard let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day else {
            return 0
        }
        return days + 1
    }
}

extension MenstrualPeriod: Equatable {
    /// 2 menstrual periods are the same if they're the same periods in the same order
    static func == (lhs: MenstrualPeriod, rhs: MenstrualPeriod) -> Bool {
        return (
            lhs.startDate == rhs.startDate
            && lhs.endDate == rhs.endDate
            && zip(lhs.events, rhs.events).reduce(true) { partialResult, elementPair in
                partialResult && elementPair.0 == elementPair.1
            }
        )
    }
}
