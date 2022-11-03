//
//  ChartConstants.swift
//  Nova
//
//  Created by Anna Quinlan on 11/2/22.
//  Copyright © 2022 Anna Quinlan. All rights reserved.
//

import Foundation

enum ChartType {
    case totalVolume
    case dailyVolume
    
    var title: String {
        switch self {
        case .totalVolume:
            return "Typical Period Volume"
        case .dailyVolume:
            return "Typical Daily Volume"
        }
    }
    
    var xAxisLabel: String {
        switch self {
        case .totalVolume:
            return "Period Dates"
        case .dailyVolume:
            return ""
        }
    }
}

struct ChartConstants {
    static let scrollWidth = 450.0
    static let dragMinimum = 5.0
}
