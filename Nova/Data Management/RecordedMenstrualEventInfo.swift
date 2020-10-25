//
//  RecordedMenstrualEventInfo.swift
//  Nova
//
//  Created by Anna Quinlan on 10/22/20.
//  Copyright © 2020 Anna Quinlan. All rights reserved.
//

import Foundation
//func save(sample: MenstrualSample?, date: Date, newVolume: Int

struct RecordedMenstrualEventInfo {
    let sample: MenstrualSample?
    let date: Date
    let volume: Int
}


extension RecordedMenstrualEventInfo: RawRepresentable {
    typealias RawValue = [String: Any]
    
    static let name = "RecordedMenstrualEventInfo"

    init?(rawValue: RawValue) {
        guard rawValue["name"] as? String == RecordedMenstrualEventInfo.name, let date = rawValue["date"] as? Date,
            let volume = rawValue["volume"] as? Int else
        {
            return nil
        }

        self.volume = volume
        self.date = date
        self.sample = (rawValue["sample"] as? MenstrualSample.RawValue).flatMap(MenstrualSample.init(rawValue:))
    }

    var rawValue: RawValue {
        var raw: RawValue = [
            "name": RecordedMenstrualEventInfo.name,
            "date": date,
            "volume": volume
        ]

        if let sample = sample {
            raw["sample"] = sample.rawValue
        }

        return raw
    }
}
