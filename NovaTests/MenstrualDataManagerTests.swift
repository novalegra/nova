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

    // MARK: UserDefaults settings
    func testSavingVolumeUnit() {
        menstrualDataManager.volumeUnit = .mL
        XCTAssertEqual(UserDefaults.app?.volumeType, .mL)
        
        menstrualDataManager.volumeUnit = .percentOfCup
        XCTAssertEqual(UserDefaults.app?.volumeType, .percentOfCup)
    }

    func testSavingCupType() {
        menstrualDataManager.cupType = .melunaShortLarge
        XCTAssertEqual(UserDefaults.app?.menstrualCupType, .melunaShortLarge)
        
        menstrualDataManager.cupType = .juneSmall
        XCTAssertEqual(UserDefaults.app?.menstrualCupType, .juneSmall)
        
        menstrualDataManager.cupType = .divaLarge
        XCTAssertEqual(UserDefaults.app?.menstrualCupType, .divaLarge)
    }
    
    func testSavingNotificationPref() {
        menstrualDataManager.notificationsEnabled = true
        XCTAssertEqual(UserDefaults.app?.notificationsEnabled, true)
        
        menstrualDataManager.notificationsEnabled = false
        XCTAssertEqual(UserDefaults.app?.notificationsEnabled, false)
    }

    func testSavingCustomCupVolume() {
        menstrualDataManager.customCupVolume = 30
        XCTAssertEqual(UserDefaults.app?.customCupVolume, 30)
        
        // Zero or negative volume shouldn't be saved
        menstrualDataManager.customCupVolume = 0
        XCTAssertEqual(UserDefaults.app?.customCupVolume, 30)
        
        menstrualDataManager.customCupVolume = -1
        XCTAssertEqual(UserDefaults.app?.customCupVolume, 30)
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
    
    func testProcessingSamplesToPeriods() {
        let p1 = [
            testDate,
            testDate.addingTimeInterval(TimeInterval(days: 1)),
            testDate.addingTimeInterval(TimeInterval(days: 3))
        ]
            .map { MenstrualSample(startDate: $0, endDate: $0, flowLevel: .medium) }
        
        let nonPeriod = [testDate.addingTimeInterval(TimeInterval(days: 5))]
            .map { MenstrualSample(startDate: $0, endDate: $0, flowLevel: .none) }
        
        let p2 = [testDate.addingTimeInterval(TimeInterval(days: 6))]
            .map { MenstrualSample(startDate: $0, endDate: $0, flowLevel: .heavy) }
        
        let p3 = [
            testDate.addingTimeInterval(TimeInterval(days: 10)),
            testDate.addingTimeInterval(TimeInterval(days: 11))
        ]
            .map { MenstrualSample(startDate: $0, endDate: $0, flowLevel: .heavy) }
        
        let samples = Array([p1, nonPeriod, p2, p3].joined())
        
        let output = menstrualDataManager.processHealthKitQuery(samples: samples)
        let expected = [
            MenstrualPeriod(events: p1),
            MenstrualPeriod(events: p2),
            MenstrualPeriod(events: p3)
        ]
        
        XCTAssertEqual(output, expected)
    }
}
