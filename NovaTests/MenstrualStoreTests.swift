//
//  NovaTests.swift
//  NovaTests
//
//  Created by Anna Quinlan on 12/18/21.
//  Copyright © 2021 Anna Quinlan. All rights reserved.
//

import XCTest
import HealthKit
@testable import Nova

class MenstrualStoreTests: XCTestCase {
    let testDate = Date(timeIntervalSince1970: TimeInterval(30))
    
    var menstrualStore: MenstrualStore!
    var healthStore: HKHealthStoreMock!
    var mockSample1: MenstrualSample!
    var mockSample2: MenstrualSample!

    override func setUpWithError() throws {
        super.setUp()
        healthStore = HKHealthStoreMock()

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
    
    // MARK: getAction
    func testActionShouldSave() {
        let result = menstrualStore.action(
            existingSample: nil,
            date: Date(),
            newVolume: 5,
            flowSelection: .hadFlow)
        
        XCTAssertEqual(result, .saveNewSample)
    }
    
    func testActionShouldSaveNoFlow() {
        let result = menstrualStore.action(
            existingSample: nil,
            date: Date(),
            newVolume: 5,
            flowSelection: .noFlow)
        
        XCTAssertEqual(result, .saveNewSample)
    }
    
    func testActionShouldSaveNothingSelected() {
        let result = menstrualStore.action(
            existingSample: nil,
            date: Date(),
            newVolume: 5,
            flowSelection: .none)
        
        XCTAssertEqual(result, .unknown)
    }
    
    func testActionShouldUpdate() {
        let result = menstrualStore.action(
            existingSample: mockSample1,
            date: mockSample1.startDate,
            newVolume: 5,
            flowSelection: .hadFlow)
        
        XCTAssertEqual(result, .updateSample)
    }
    
    func testActionShouldUpdateNoFlow() {
        let result = menstrualStore.action(
            existingSample: mockSample1,
            date: mockSample1.startDate,
            newVolume: 0,
            flowSelection: .noFlow)
        
        XCTAssertEqual(result, .updateSample)
    }
    
    func testActionShouldDelete() {
        let result = menstrualStore.action(
            existingSample: mockSample1,
            date: mockSample1.startDate,
            newVolume: 5,
            flowSelection: .none)
        
        XCTAssertEqual(result, .deleteSample)
    }
    
    // MARK: saveInHealthKit
    func testSaveInHealthKit() async {
        let saveHealthStoreHandler = expectation(description: "Add health store handler")
        
        healthStore.setSaveHandler({[unowned self] (objects, success, error) in
            XCTAssertEqual(1, objects.count)

            let sample = objects.first as! HKCategorySample

            XCTAssertEqual(sample.startDate, mockSample1.startDate)

            saveHealthStoreHandler.fulfill()
        })
        
        _ = await menstrualStore.saveSample(mockSample1)
        
        wait(for: [saveHealthStoreHandler], timeout: 10, enforceOrder: true)
    }
    
    func testDeleteInHealthKit() async {
        let deleteHealthStoreHandler = expectation(description: "Delete health store handler")
        
        healthStore.setDeletedObjectsHandler({[unowned self] (objectType, predicate, success, count, error) in
            XCTAssertEqual(objectType, HKObjectType.categoryType(forIdentifier: .menstrualFlow))
            XCTAssertEqual(predicate.predicateFormat, "UUID == \(mockSample1.uuid)")

            deleteHealthStoreHandler.fulfill()
        })
        
        _ = await menstrualStore.deleteSample(mockSample1)
        
        wait(for: [deleteHealthStoreHandler], timeout: 10, enforceOrder: true)
    }
    
    func testUpdateInHealthKit() async {
        let deleteHealthStoreHandler = expectation(description: "Delete health store handler")
        let saveHealthStoreHandler = expectation(description: "Save health store handler")
        
        healthStore.setDeletedObjectsHandler({[unowned self] (objectType, predicate, success, count, error) in
            XCTAssertEqual(objectType, HKObjectType.categoryType(forIdentifier: .menstrualFlow))
            XCTAssertEqual(predicate.predicateFormat, "UUID == \(mockSample1.uuid)")

            deleteHealthStoreHandler.fulfill()
        })
        
        healthStore.setSaveHandler({[unowned self] (objects, success, error) in
            XCTAssertEqual(1, objects.count)

            let sample = objects.first as! HKCategorySample

            XCTAssertEqual(sample.startDate, mockSample1.startDate)
            XCTAssertEqual(sample.version, 2)

            saveHealthStoreHandler.fulfill()
        })
        
        _ = await menstrualStore.updateSample(mockSample1)
        
        wait(for: [deleteHealthStoreHandler, saveHealthStoreHandler], timeout: 10, enforceOrder: true)
    }
}
