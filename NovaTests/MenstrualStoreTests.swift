//
//  NovaTests.swift
//  NovaTests
//
//  Created by Anna Quinlan on 12/18/21.
//  Copyright © 2021 Anna Quinlan. All rights reserved.
//

import XCTest
@testable import Nova

class MenstrualStoreTests: XCTestCase {
    let testDate = Date(timeIntervalSince1970: TimeInterval(30))
    
    var menstrualStore: MenstrualStore!
    var mockSample1: MenstrualSample!
    var mockSample2: MenstrualSample!

    override func setUpWithError() throws {
        super.setUp()
        let healthStore = HKHealthStoreMock()

        menstrualStore = MenstrualStore(healthStore: healthStore)
        mockSample1 = MenstrualSample(startDate: testDate, endDate: testDate, flowLevel: .light)
        mockSample2 = MenstrualSample(startDate: testDate.addingTimeInterval(TimeInterval(360000)), endDate: testDate.addingTimeInterval(TimeInterval(360000)), flowLevel: .heavy)
    }

    override func tearDownWithError() throws {
        menstrualStore = nil
        try super.tearDownWithError()
    }

    // MARK: authorize
    func testNoAuthorizationCall_NotDetermined() throws {
        XCTAssertTrue(menstrualStore.authorizationRequired)
    }
    
    func testAuthorizationCall_UpdatesAuthStatus() async throws {
        try await menstrualStore.authorize()
        XCTAssertFalse(menstrualStore.authorizationRequired)
    }

    // MARK: hasMenstrualFlow
    func testHasMenstrualFlowWithSameSampleDate() {
        menstrualStore.menstrualEvents = [mockSample1]
        
        XCTAssertTrue(menstrualStore.hasMenstrualFlow(at: Date(timeIntervalSince1970: TimeInterval(30))))
    }
    
    func testHasMenstrualFlowWithSampleNotOnDate() {
        menstrualStore.menstrualEvents = [mockSample2]
        XCTAssertFalse(menstrualStore.hasMenstrualFlow(at: Date(timeIntervalSince1970: TimeInterval(30))))
    }
    
    func testHasMenstrualFlowWithNoSamples() {
        XCTAssertFalse(menstrualStore.hasMenstrualFlow(at: Date(timeIntervalSince1970: TimeInterval(30))))
    }
    
    // MARK: menstrualEventIfPresent
    func testMenstrualEventWithSameSampleDate() {
        menstrualStore.menstrualEvents = [mockSample1]
        
        XCTAssertEqual(menstrualStore.menstrualEventIfPresent(for: testDate), mockSample1)
    }
    
    func testMenstrualEventWithSampleNotOnDate() {
        menstrualStore.menstrualEvents = [mockSample2]
        XCTAssertNil(menstrualStore.menstrualEventIfPresent(for: testDate))
    }
    
    func testMenstrualEventWithNoSamples() {
        XCTAssertNil(menstrualStore.menstrualEventIfPresent(for: testDate))
    }
    
    // MARK: flowLevel
    func testFlowLevelWithNoFlow() {
        XCTAssertEqual(menstrualStore.flowLevel(for: .noFlow, with: 0), .none)
    }
    
    func testFlowLevelWithNoFlowAndMisleadingVolume() {
        XCTAssertEqual(menstrualStore.flowLevel(for: .noFlow, with: 10), .none)
    }
    
    func testFlowLevelWithLightFlow() {
        XCTAssertEqual(menstrualStore.flowLevel(for: .hadFlow, with: 10), .light)
    }
    
    func testFlowLevelWithMediumFlow() {
        XCTAssertEqual(menstrualStore.flowLevel(for: .hadFlow, with: 15), .medium)
    }
    
    func testFlowLevelWithMediumFlowAtBoundary() {
        XCTAssertEqual(menstrualStore.flowLevel(for: .hadFlow, with: 30), .medium)
    }
    
    func testFlowLevelWithHeavyFlow() {
        XCTAssertEqual(menstrualStore.flowLevel(for: .hadFlow, with: 31), .heavy)
    }
    
    func testFlowLevelWithNegativeFlow() {
        XCTAssertEqual(menstrualStore.flowLevel(for: .hadFlow, with: -1), .unspecified)
    }
    
    // MARK: saveInHealthKit
    // ANNA TODO
}
