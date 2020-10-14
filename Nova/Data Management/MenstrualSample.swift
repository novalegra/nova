//
//  MenstrualSample.swift
//  Nova
//
//  Created by Anna Quinlan on 9/7/20.
//  Copyright © 2020 Anna Quinlan. All rights reserved.
//

import HealthKit

class MenstrualSample: Codable {
    let startDate: Date
    let endDate: Date
    var flowLevel: HKCategoryValueMenstrualFlow
    var volume: Int? // in mL
    let uuid: UUID
    
    init(startDate: Date, endDate: Date, flowLevel: HKCategoryValueMenstrualFlow, volume: Int? = nil, uuid: UUID = UUID()) {
        guard startDate <= endDate else {
            fatalError("Can't create menstrual event where start is less than end")
        }
        
        self.startDate = startDate
        self.endDate = endDate
        self.flowLevel = flowLevel
        self.volume = volume
        self.uuid = uuid
    }
    
    convenience init(sample: HKCategorySample, flowLevel: HKCategoryValueMenstrualFlow) {
        self.init(startDate: sample.startDate, endDate: sample.endDate, flowLevel: flowLevel, volume: sample.volume, uuid: sample.uuid)
    }
    
    enum CodingKeys: String, CodingKey {
        case start
        case end
        case flow
        case volume
        case id
    }

    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let startDate: Date = try container.decode(Date.self, forKey: .start)
        let endDate: Date = try container.decode(Date.self, forKey: .end)
        let flowLevel: HKCategoryValueMenstrualFlow = try container.decode(HKCategoryValueMenstrualFlow.self, forKey: .flow)
        let volume: Int? = try container.decodeIfPresent(Int.self, forKey: .volume)
        let uuid: UUID = try container.decode(UUID.self, forKey: .id)
        
        self.init(startDate: startDate, endDate: endDate, flowLevel: flowLevel, volume: volume, uuid: uuid)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(startDate, forKey: .start)
        try container.encode(endDate, forKey: .end)
        try container.encode(flowLevel, forKey: .flow)
        try container.encodeIfPresent(volume, forKey: .volume)
        try container.encode(uuid, forKey: .id)
    }
}

extension HKCategoryValueMenstrualFlow: Codable { }
