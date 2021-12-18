//
//  MenstrualDataManagerTests.swift
//  NovaTests
//
//  Created by Anna Quinlan on 12/18/21.
//  Copyright © 2021 Anna Quinlan. All rights reserved.
//

import XCTest
@testable import Nova

class MenstrualDataManagerTests: XCTestCase {
    let testDate = Date(timeIntervalSince1970: TimeInterval(30))
    let maxPercentOfCup: Double = 600
    let maxML: Double = 240
    
    var menstrualDataManager: MenstrualDataManager!
    var mockSample1: MenstrualSample!
    var mockSample2: MenstrualSample!
    
    override func setUpWithError() throws {
        super.setUp()
        
        mockSample1 = MenstrualSample(startDate: testDate, endDate: testDate, flowLevel: .light)
        mockSample2 = MenstrualSample(startDate: testDate.addingTimeInterval(TimeInterval(360000)), endDate: testDate.addingTimeInterval(TimeInterval(360000)), flowLevel: .heavy)
        
        let healthStore = HKHealthStoreMock()
        let menstrualStore = MenstrualStore(healthStore: healthStore)
        
        menstrualDataManager = MenstrualDataManager(store: menstrualStore)
        
    }

    override func tearDownWithError() throws {
        menstrualDataManager = nil
        try super.tearDownWithError()
    }

    // MARK: volumeUnit
    func testDefaultVolumeUnit() {
        XCTAssertEqual(menstrualDataManager.volumeUnit, .percentOfCup)
    }
    
    func testSavingVolumeUnit() {
        menstrualDataManager.volumeUnit = .mL
        XCTAssertEqual(menstrualDataManager.volumeUnit, .mL)
        
        menstrualDataManager.volumeUnit = .percentOfCup
        XCTAssertEqual(menstrualDataManager.volumeUnit, .percentOfCup)
    }
    
    // MARK: cupType
    func testSavingCupType() {
        menstrualDataManager.cupType = .melunaShortLarge
        XCTAssertEqual(menstrualDataManager.cupType, .melunaShortLarge)
        
        menstrualDataManager.cupType = .juneSmall
        XCTAssertEqual(menstrualDataManager.cupType, .juneSmall)
        
        menstrualDataManager.cupType = .divaLarge
        XCTAssertEqual(menstrualDataManager.cupType, .divaLarge)
    }
    
    // MARK: flowPickerNumbers
    func testPercentCupFlowPickerNumbers() {
        menstrualDataManager.volumeUnit = .percentOfCup
        XCTAssertEqual(menstrualDataManager.flowPickerNumbers.first!, 0)
        XCTAssertEqual(menstrualDataManager.flowPickerNumbers[1], 5)
        XCTAssertEqual(menstrualDataManager.flowPickerNumbers.last!, maxPercentOfCup)
    }
    
    func testMLFlowPickerNumbers() {
        menstrualDataManager.volumeUnit = .mL
        XCTAssertEqual(menstrualDataManager.flowPickerNumbers.first!, 0)
        XCTAssertEqual(menstrualDataManager.flowPickerNumbers[1], 1)
        XCTAssertEqual(menstrualDataManager.flowPickerNumbers.last!, maxML)
    }
    
    // MARK: closestNumberOnPicker
    func testClosestNumberSameNumberPercentCup() {
        menstrualDataManager.volumeUnit = .percentOfCup
        XCTAssertEqual(menstrualDataManager.closestNumberOnPicker(num: 10), 10)
    }
    
    func testClosestNumberSameNumberML() {
        menstrualDataManager.volumeUnit = .mL
        XCTAssertEqual(menstrualDataManager.closestNumberOnPicker(num: 7), 7)
        XCTAssertEqual(menstrualDataManager.closestNumberOnPicker(num: 10), 10)
    }
    
    func testClosestNumberInBetween() {
        menstrualDataManager.volumeUnit = .percentOfCup
        XCTAssertEqual(menstrualDataManager.closestNumberOnPicker(num: 11), 10)
        XCTAssertEqual(menstrualDataManager.closestNumberOnPicker(num: 12), 10)
        XCTAssertEqual(menstrualDataManager.closestNumberOnPicker(num: 13), 15)
        XCTAssertEqual(menstrualDataManager.closestNumberOnPicker(num: 14), 15)
    }

    func testClosestNumberBelowMin() {
        menstrualDataManager.volumeUnit = .percentOfCup
        XCTAssertEqual(menstrualDataManager.closestNumberOnPicker(num: -5), 0)
    }
    
    func testClosestNumberAboveMax()  {
        menstrualDataManager.volumeUnit = .percentOfCup
        XCTAssertEqual(menstrualDataManager.closestNumberOnPicker(num: maxPercentOfCup + 5), maxPercentOfCup)
    }
}
