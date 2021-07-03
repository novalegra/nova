//
//  MenstrualSample.swift
//  Nova
//
//  Created by Anna Quinlan on 9/7/20.
//  Copyright © 2020 Anna Quinlan. All rights reserved.
//

import HealthKit

class MenstrualSample: Codable, RawRepresentable {
    typealias RawValue = [String: Any]
    
    let startDate: Date
    let endDate: Date
    var flowLevel: HKCategoryValueMenstrualFlow
    var volume: Double? // in mL
    let uuid: UUID
    var syncVersion: Int
    
    init(startDate: Date, endDate: Date, flowLevel: HKCategoryValueMenstrualFlow, volume: Double? = nil, uuid: UUID = UUID(), version: Int = 1) {
        guard startDate <= endDate else {
            fatalError("Can't create menstrual event where start is less than end")
        }
        
        self.startDate = startDate
        self.endDate = endDate
        self.flowLevel = flowLevel
        self.volume = volume
        self.uuid = uuid
        self.syncVersion = version
    }
    
    required convenience init?(rawValue: RawValue) {
        guard
            let startDate = rawValue["startDate"] as? Date,
            let endDate = rawValue["endDate"] as? Date,
            let flow = (rawValue["flow"] as? HKCategoryValueMenstrualFlow.RawValue).flatMap(HKCategoryValueMenstrualFlow.init(rawValue:)),
            let uuid = (rawValue["uuid"] as? UUID.RawValue).flatMap(UUID.init(rawValue:)),
            let version = rawValue["version"] as? Int
        else {
            return nil
        }

        self.init(
            startDate: startDate,
            endDate: endDate,
            flowLevel: flow,
            volume: rawValue["volume"] as? Double,
            uuid: uuid,
            version: version
        )
    }

    var rawValue: RawValue {
        var rawValue: RawValue = [
            "startDate": startDate,
            "endDate": endDate,
            "flow": flowLevel.rawValue,
            "uuid": uuid.rawValue,
            "version": syncVersion
        ]
        
        rawValue["volume"] = volume

        return rawValue
    }
    
    convenience init(sample: HKCategorySample, flowLevel: HKCategoryValueMenstrualFlow) {
        self.init(startDate: sample.startDate, endDate: sample.endDate, flowLevel: flowLevel, volume: sample.volume, uuid: sample.uuid, version: sample.version)
    }
    
    enum CodingKeys: String, CodingKey {
        case start
        case end
        case flow
        case volume
        case id
        case version
    }

    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let startDate: Date = try container.decode(Date.self, forKey: .start)
        let endDate: Date = try container.decode(Date.self, forKey: .end)
        let flowLevel: HKCategoryValueMenstrualFlow = try container.decode(HKCategoryValueMenstrualFlow.self, forKey: .flow)
        let volume: Double? = try container.decodeIfPresent(Double.self, forKey: .volume)
        let uuid: UUID = try container.decode(UUID.self, forKey: .id)
        let version: Int = try container.decode(Int.self, forKey: .version)
        
        self.init(startDate: startDate, endDate: endDate, flowLevel: flowLevel, volume: volume, uuid: uuid, version: version)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(startDate, forKey: .start)
        try container.encode(endDate, forKey: .end)
        try container.encode(flowLevel, forKey: .flow)
        try container.encodeIfPresent(volume, forKey: .volume)
        try container.encode(uuid, forKey: .id)
        try container.encode(syncVersion, forKey: .version)
    }
}

extension HKCategoryValueMenstrualFlow: Codable { }

extension UUID: RawRepresentable {
    public typealias RawValue = String

    public init?(rawValue: String) {
        guard let id = UUID(uuidString: rawValue) else {
            return nil
        }
        self = id
    }

    public var rawValue: String {
        return self.uuidString
    }
}
