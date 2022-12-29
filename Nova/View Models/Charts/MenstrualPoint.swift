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
        let (uniqueDescription, detailedDescription) = Self.descriptions(start: start, end: end)
        
        self.init(uniqueDescription: uniqueDescription,
                  detailedDescription: detailedDescription,
                  flowVolume: flowVolume)
    }
    
    /// `uniqueDescription` will be displayed on the axis and `detailedDescription` will be displayed when a user scrubs over
    init(uniqueDescription: String, detailedDescription: String, flowVolume: Double) {
        self.description = uniqueDescription
        self.value = flowVolume
        self.detailDescription = "\(String(format: "%.2f", value)) mL \n\(detailedDescription)"
        self.valueDescription = "Volume"
    }
    
    init(start: Date, end: Date, days: Int) {
        let (uniqueDescription, detailedDescription) = Self.descriptions(start: start, end: end)
        
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.day]
        let components = DateComponents(day: days)
        
        self.description = uniqueDescription
        self.value = Double(days)
        self.detailDescription = "\(formatter.string(from: components) ?? "") \n\(detailedDescription)"
        self.valueDescription = "Days"
    }
    
    var id: String {
        description
    }
}

// MARK: - Initialization Helpers
extension MenstrualPoint {
    static func descriptions(start: Date, end: Date) -> (uniqueDescription: String, detailedDescription: String) {
        let startString = start.formatted(
            .dateTime
            .month(.twoDigits).day()
        )
        
        let endString = end.formatted(
            .dateTime
            .month(.twoDigits).day()
        )
        
        let detailedEndString = end.formatted(
            .dateTime
            .month(.twoDigits).day().year()
        )
        
        // FIXME: newline hack to prevent SwiftCharts from cutting off the strings
        let startEndSpacer = "\n" + String(repeating: " ", count: max(0, startString.count - 2)) + "→\n"
        
        return (uniqueDescription: startString + startEndSpacer + endString,
                detailedDescription: startString + "-" + detailedEndString)
    }
}
