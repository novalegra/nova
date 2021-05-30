//
//  VolumeType.swift
//  Nova
//
//  Created by Anna Quinlan on 10/14/20.
//  Copyright © 2020 Anna Quinlan. All rights reserved.
//

enum VolumeType: String, Equatable, CaseIterable {
    case mL = "Milliliters"
    case percentOfCup = "Percent of Cup Size"
    
    var shortUnit: String {
        switch self {
        case .mL:
            return "mL"
        case .percentOfCup:
            return "% of cup"
        }
    }
}
