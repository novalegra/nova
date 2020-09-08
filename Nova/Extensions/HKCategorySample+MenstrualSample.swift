//
//  HKCategorySample+MenstrualSample.swift
//  Nova
//
//  Created by Anna Quinlan on 9/7/20.
//  Copyright © 2020 Anna Quinlan. All rights reserved.
//

import HealthKit

let MetadataKeyMenstrualVolume = "com.nova.HKMetadataKey.MenstrualVolume"

extension HKCategorySample {
    convenience init?(entry: MenstrualSample) {
        let metadata: [String: Any] = [
            MetadataKeyMenstrualVolume: entry.volume ?? -1
        ]
        let type = HKObjectType.categoryType(forIdentifier: .menstrualFlow)!
    
        self.init(
            type: type,
            value: entry.flowLevel.rawValue,
            start: entry.startDate,
            end: entry.endDate,
            metadata: metadata
        )
    }

    var volume: Int? {
        guard let volume = metadata?[MetadataKeyMenstrualVolume] as? Int else {
            return nil
        }
        return volume
    }
}
