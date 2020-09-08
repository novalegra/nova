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
    
    var healthStoreUpdateCompletionHandler: (([HKCategorySample]) -> Void)?
    
    var sampleType: HKSampleType {
        return HKObjectType.categoryType(forIdentifier: .menstrualFlow)!
    }
    
    var authorizationRequired: Bool {
        return healthStore.authorizationStatus(for: sampleType) == .notDetermined
    }
    
    func authorize() {
        healthStore.requestAuthorization(toShare: [sampleType], read: [sampleType]) { _, _ in }
    }

    func setUpBackgroundDelivery() {
        let query = HKObserverQuery(sampleType: sampleType, predicate: nil) { [weak self] (query, completionHandler, error) in
            self?.dataFetch.async {
                self?.getRecentMenstrualSamples() { samples in
                    self?.healthStoreUpdateCompletionHandler?(samples)
                }
            }
            completionHandler()
        }
        healthStore.execute(query)
        healthStore.enableBackgroundDelivery(for: sampleType, frequency: .immediate) { (enabled, error) in
            print("enableBackgroundDeliveryForType handler called for \(self.sampleType) - success: \(enabled), error: \(String(describing: error))")
        }
    }
    
    // MARK: Data Retrieval
    let dataFetch = DispatchQueue(label: "com.nova.MenstrualStoreQueue", qos: .utility)
    
    let hadFlowPredicate = HKQuery.predicateForCategorySamples(
        with: .equalTo,
        value: HKCategoryValueMenstrualFlow.unspecified.rawValue
    )
    
    let lightFlowPredicate = HKQuery.predicateForCategorySamples(
        with: .equalTo,
        value: HKCategoryValueMenstrualFlow.light.rawValue
    )
    
    let mediumFlowPredicate = HKQuery.predicateForCategorySamples(
        with: .equalTo,
        value: HKCategoryValueMenstrualFlow.medium.rawValue
    )
    
    let heavyFlowPredicate = HKQuery.predicateForCategorySamples(
        with: .equalTo,
        value: HKCategoryValueMenstrualFlow.heavy.rawValue
    )
    
    func getRecentMenstrualSamples(days: Int = 90, _ completion: @escaping (_ result: [HKCategorySample]) -> Void) {
        dispatchPrecondition(condition: .onQueue(dataFetch))
        // Go 'days' back
        let start = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        var newMenstrualEvents: [HKCategorySample] = []
        
        let updateGroup = DispatchGroup()
        updateGroup.enter()
        getRecentMenstrualSamples(start: start, matching: hadFlowPredicate, sampleLimit: days) {
            (result) in
            switch result {
            case .success(let samples):
                newMenstrualEvents = newMenstrualEvents + samples
            default:
                break
            }
            updateGroup.leave()
        }
        
        updateGroup.enter()
        getRecentMenstrualSamples(start: start, matching: lightFlowPredicate, sampleLimit: days) {
            (result) in
            switch result {
            case .success(let samples):
                newMenstrualEvents = newMenstrualEvents + samples
            default:
                break
            }
            updateGroup.leave()
        }
        
        updateGroup.enter()
        getRecentMenstrualSamples(start: start, matching: mediumFlowPredicate, sampleLimit: days) {
            (result) in
            switch result {
            case .success(let samples):
                newMenstrualEvents = newMenstrualEvents + samples
            default:
                break
            }
            updateGroup.leave()
        }
        
        updateGroup.enter()
        getRecentMenstrualSamples(start: start, matching: heavyFlowPredicate, sampleLimit: days) {
            (result) in
            switch result {
            case .success(let samples):
                newMenstrualEvents = newMenstrualEvents + samples
            default:
                break
            }
            updateGroup.leave()
        }
        updateGroup.wait()
        self.menstrualEvents = newMenstrualEvents
        completion(newMenstrualEvents)
    }

    fileprivate func getRecentMenstrualSamples(start: Date, end: Date = Date(), matching predicate: NSPredicate, sampleLimit: Int, _ completion: @escaping (_ result: MenstrualStoreResult<[HKCategorySample]>) -> Void) {
        dispatchPrecondition(condition: .onQueue(dataFetch))
        
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
