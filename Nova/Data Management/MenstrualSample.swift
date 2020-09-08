//
//  MenstrualSample.swift
//  Nova
//
//  Created by Anna Quinlan on 9/7/20.
//  Copyright © 2020 Anna Quinlan. All rights reserved.
//

import HealthKit

struct MenstrualSample {
    let startDate: Date
    let endDate: Date
    // TODO: flow type
    let volume: Int? // in mL
    
    init(startDate: Date, endDate: Date, volume: Int? = nil) {
        self.startDate = startDate
        self.endDate = endDate
        self.volume = volume
    }
    
    init(sample: HKCategorySample) {
        self.init(startDate: sample.startDate, endDate: sample.endDate)
    }
}
