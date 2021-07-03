//
//  HKCategorySample+MenstrualSample.swift
//  Nova
//
//  Created by Anna Quinlan on 9/7/20.
//  Copyright © 2020 Anna Quinlan. All rights reserved.
//

import HealthKit

let MetadataKeyMenstrualVolume = "com.nova.HKMetadataKey.MenstrualVolume"
let MetadataKeyUUID = "com.nova.HKMetadataKey.UUID"
let MetadataKeySyncIDBase = "com.Nova.HkMetadataKey.SyncId."

extension HKCategorySample {
    convenience init(entry: MenstrualSample) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        let metadata: [String: Any] = [
            MetadataKeyMenstrualVolume: entry.volume ?? -1,
            HKMetadataKeyMenstrualCycleStart: 0,
            HKMetadataKeySyncIdentifier: MetadataKeySyncIDBase + formatter.string(from: entry.startDate),
            HKMetadataKeySyncVersion: entry.syncVersion
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

    var volume: Double? {
        return metadata?[MetadataKeyMenstrualVolume] as? Double
    }
    
    var version: Int {
        return metadata?[HKMetadataKeySyncVersion] as? Int ?? 1
    }
}
