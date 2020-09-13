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
        guard let first = events.first else {
            fatalError("Tried to init menstrual period without any events")
        }
        
        var minDate = first.startDate
        var maxDate = first.endDate
        
        for event in events {
            minDate = min(minDate, event.startDate)
            maxDate = max(maxDate, event.endDate)
        }
        
        self.events = events
        self.startDate = minDate
        self.endDate = maxDate
    }
    
    var totalFlow: Int {
        return events.reduce(0) {sum, event in
            let volume = flow(event)
            if volume != -1 {
                return sum + volume
            }
            return sum
        }
    }
    
    var averageDailyFlow: Double {
        var totalVolume = 0
        var totalEvents = 0
        
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
        
        return Double(totalVolume) / Double(totalEvents)
    }
    
    private func flow(_ event: MenstrualSample) -> Int {
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

