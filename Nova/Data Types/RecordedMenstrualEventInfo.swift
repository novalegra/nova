//
//  RecordedMenstrualEventInfo.swift
//  Nova
//
//  Created by Anna Quinlan on 10/22/20.
//  Copyright © 2020 Anna Quinlan. All rights reserved.
//

import Foundation

struct RecordedMenstrualEventInfo {
    let sample: MenstrualSample?
    let date: Date
    let volume: Double
    let selectionState: SelectionState
}

/// RawRepresentable protocol conformance is needed so this class can be passed over a WCSession
extension RecordedMenstrualEventInfo: RawRepresentable {
    typealias RawValue = [String: Any]
    
    static let name = "RecordedMenstrualEventInfo"

    init?(rawValue: RawValue) {
        guard rawValue["name"] as? String == RecordedMenstrualEventInfo.name, let date = rawValue["date"] as? Date,
            let volume = rawValue["volume"] as? Double,
            let selection = (rawValue["selectionState"] as? SelectionState.RawValue).flatMap(SelectionState.init(rawValue:)) else
        {
            return nil
        }

        self.volume = volume
        self.date = date
        self.sample = (rawValue["sample"] as? MenstrualSample.RawValue).flatMap(MenstrualSample.init(rawValue:))
        self.selectionState = selection
    }

    var rawValue: RawValue {
        var raw: RawValue = [
            "name": RecordedMenstrualEventInfo.name,
            "date": date,
            "volume": volume,
            "selectionState": selectionState.rawValue
        ]

        if let sample = sample {
            raw["sample"] = sample.rawValue
        }

        return raw
    }
}
