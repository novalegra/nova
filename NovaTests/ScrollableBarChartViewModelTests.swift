//
//  ScrollableBarChartViewModelTests.swift
//  NovaTests
//
//  Created by Anna Quinlan on 12/30/22.
//  Copyright © 2022 Anna Quinlan. All rights reserved.
//

import XCTest
import Algorithms
@testable import Nova

class ScrollableBarChartViewModelTests: XCTestCase {
    var viewModel: ScrollableBarChartViewModel!
    
    func setUp(for type: ChartType) throws {
        super.setUp()
        
        let points = type.testPoints
        viewModel = ScrollableBarChartViewModel(points: points, type: type)
    }
}

fileprivate extension ChartType {
    var testPoints: [ScrollableChartPoint] {
        let now = Date()
        let dates = (0...10).map { now.addingTimeInterval(TimeInterval(days: Double($0))) }.adjacentPairs()
        
        switch self {
        case .totalVolume, .dailyVolume:
            return dates.enumerated().map { ScrollableChartPoint(start: $1.0, end: $1.1, flowVolume: Double($0) * 5) }
        case .periodLength:
            return dates.enumerated().map { ScrollableChartPoint(start: $1.0, end: $1.1, days: $0 / 2 + $0 % 2) }
        }
    }
}
