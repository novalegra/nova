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
    var flowLevel: HKCategoryValueMenstrualFlow
    var volume: Int? // in mL
    let uuid: UUID
    
    init(startDate: Date, endDate: Date, flowLevel: HKCategoryValueMenstrualFlow, volume: Int? = nil, uuid: UUID = UUID()) {
        self.startDate = startDate
        self.endDate = endDate
        self.flowLevel = flowLevel
        self.volume = volume
        self.uuid = uuid
    }
    
    convenience init(sample: HKCategorySample, flowLevel: HKCategoryValueMenstrualFlow) {
        self.init(startDate: sample.startDate, endDate: sample.endDate, flowLevel: flowLevel, volume: sample.volume, uuid: sample.uuid)
    }
}
