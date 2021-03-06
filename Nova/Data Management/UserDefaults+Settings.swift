//
//  UserDefaults+Settings.swift
//  Nova
//
//  Created by Anna Quinlan on 9/16/20.
//  Copyright © 2020 Anna Quinlan. All rights reserved.
//
import Foundation

extension UserDefaults {

    private enum Key: String {
        case volumeUnit = "com.novalegra.Nova.VolumeType"
        case menstrualCupType = "com.novalegra.Nova.MenstrualCupType"
    }

    public static let app = UserDefaults(suiteName: "Nova")

    var volumeType: VolumeType? {
        get {
            if let rawValue = string(forKey: Key.volumeUnit.rawValue) {
                return VolumeType(rawValue: rawValue)
            } else {
                return nil
            }
        }
        set {
            set(newValue?.rawValue, forKey: Key.volumeUnit.rawValue)
        }
    }
    
    var menstrualCupType: MenstrualCupType? {
        get {
            if let rawValue = string(forKey: Key.menstrualCupType.rawValue) {
                return MenstrualCupType(rawValue: rawValue)
            } else {
                return nil
            }
        }
        set {
            set(newValue?.rawValue, forKey: Key.menstrualCupType.rawValue)
        }
    }
}

