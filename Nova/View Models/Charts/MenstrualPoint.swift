//
//  MenstrualPoint.swift
//  Nova
//
//  Created by Anna Quinlan on 12/27/22.
//  Copyright © 2022 Anna Quinlan. All rights reserved.
//

import Foundation
import HealthKit

struct MenstrualPoint: Identifiable {
    /// Description of the point instance (ex: "1")
    /// _Must_ be unique
    let description: String
    
    /// Numberic quantity the point represents
    let value: Double
    
    /// Detailed description of point instance (ex: "Day 1") that
    /// is displayed when the user selects the item
    let detailDescription: String
    
    /// Used internally within SwiftCharts. Displayed to describe the value's type (ex: "Volume")
    let valueDescription: String
    
    init(start: Date, end: Date, flowVolume: Double) {
        let (uniqueTitle, detailedTitle) = Self.titles(start: start, end: end)
        
        self.init(uniqueTitle: uniqueTitle,
                  detailedTitle: detailedTitle,
                  flowVolume: flowVolume)
    }
    
    /// `uniqueTitle` will be displayed on the axis and `description` will be displayed when a user scrubs over
    init(uniqueTitle: String, detailedTitle: String, flowVolume: Double) {
        self.description = uniqueTitle
        self.value = flowVolume
        self.detailDescription = "\(String(format: "%.2f", value)) mL \n\(detailedTitle)"
        self.valueDescription = "Volume"
    }
    
    init(start: Date, end: Date, days: Int) {
        let (uniqueTitle, detailedTitle) = Self.titles(start: start, end: end)
        
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.day]
        let components = DateComponents(day: days)
        
        self.description = uniqueTitle
        self.value = Double(days)
        self.detailDescription = "\(formatter.string(from: components) ?? "") \n\(detailedTitle)"
        self.valueDescription = "Days"
    }
    
    var id: String {
        description
    }
}

// MARK: - Initialization Helpers
extension MenstrualPoint {
    static func titles(start: Date, end: Date) -> (uniqueTitle: String, detailedTitle: String) {
        let startString = start.formatted(
            .dateTime
            .month(.twoDigits).day()
        )
        
        let endString = end.formatted(
            .dateTime
            .month(.twoDigits).day()
        )
        
        // FIXME: newline hack to prevent SwiftCharts from cutting off the strings
        let startEndSpacer = "\n" + String(repeating: " ", count: max(0, startString.count - 2)) + "→\n"
        
        return (uniqueTitle: startString + startEndSpacer + endString,
                detailedTitle: startString + "-" + endString)
    }
}
