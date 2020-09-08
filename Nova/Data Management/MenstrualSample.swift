//
//  MenstrualSample.swift
//  Nova
//
//  Created by Anna Quinlan on 9/7/20.
//  Copyright © 2020 Anna Quinlan. All rights reserved.
//

import HealthKit

class MenstrualSample {
    let startDate: Date
    let endDate: Date
    let flowLevel: HKCategoryValueMenstrualFlow
    let volume: Int? // in mL
    
    init(startDate: Date, endDate: Date, flowLevel: HKCategoryValueMenstrualFlow, volume: Int? = nil) {
        self.startDate = startDate
        self.endDate = endDate
        self.flowLevel = flowLevel
        self.volume = volume
    }
    
    convenience init(sample: HKCategorySample, flowLevel: HKCategoryValueMenstrualFlow) {
        self.init(startDate: sample.startDate, endDate: sample.endDate, flowLevel: flowLevel, volume: sample.volume)
    }
}
