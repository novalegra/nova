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
}

