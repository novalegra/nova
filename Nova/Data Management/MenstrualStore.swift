//
//  MenstrualStore.swift
//  Nova
//
//  Created by Anna Quinlan on 9/7/20.
//  Copyright © 2020 Anna Quinlan. All rights reserved.
//

import HealthKit

enum MenstrualStoreResult<T> {
    case success(T)
    case failure(MenstrualStoreError)
}

enum MenstrualStoreError: Error {
    case unknownReturnConfiguration
    case noDataAvailable
    case queryError(String) // String is description of error
}

class MenstrualStore {
    public init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
    }
    
    var menstrualEvents: [HKCategorySample] = []
    
    // MARK: HealthKit
    let healthStore: HKHealthStore
    
    var sampleType: HKSampleType {
        return HKObjectType.categoryType(forIdentifier: .menstrualFlow)!
    }
    
    var authorizationRequired: Bool {
        return healthStore.authorizationStatus(for: sampleType) == .notDetermined
    }
    
    func authorize() {
        healthStore.requestAuthorization(toShare: [sampleType], read: [sampleType]) { _, _ in }
    }
    
    // MARK: Data Retrieval
    let hadFlowPredicate = HKQuery.predicateForCategorySamples(
        with: .equalTo,
        value: HKCategoryValueMenstrualFlow.unspecified.rawValue
    )
    
    let lightFlowPredicate = HKQuery.predicateForCategorySamples(
        with: .equalTo,
        value: HKCategoryValueMenstrualFlow.light.rawValue
    )
    
    let heavyFlowPredicate = HKQuery.predicateForCategorySamples(
        with: .equalTo,
        value: HKCategoryValueMenstrualFlow.heavy.rawValue
    )
    
    func getRecentMenstrualSamples(days: Int = 90, _ completion: @escaping (_ result: MenstrualStoreResult<[HKCategorySample]>) -> Void) {
        // Go 'days' back
        let start = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        
        getRecentMenstrualSamples(start: start, matching: hadFlowPredicate, sampleLimit: days) {
            (result) in
            switch result {
            case .success(let samples):
                self.menstrualEvents = self.menstrualEvents + samples
            default:
                break
            }
            completion(result)
        }
    }

    fileprivate func getRecentMenstrualSamples(start: Date, end: Date = Date(), matching predicate: NSPredicate, sampleLimit: Int, _ completion: @escaping (_ result: MenstrualStoreResult<[HKCategorySample]>) -> Void) {
        // get more-recent values first
        let sortByDate = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: sampleLimit, sortDescriptors: [sortByDate]) { (query, samples, error) in

            if let error = error {
                print("Error fetching menstrual data: %{public}@", String(describing: error))
                completion(.failure(MenstrualStoreError.queryError(error.localizedDescription)))
            } else if let samples = samples as? [HKCategorySample] {
                guard !samples.isEmpty else {
                    completion(.failure(MenstrualStoreError.noDataAvailable))
                    return
                }
                completion(.success(samples))
            } else {
                completion(.failure(MenstrualStoreError.unknownReturnConfiguration))
            }
        }
        healthStore.execute(query)
    }
    
    
}
