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
    
    var menstrualEvents: [MenstrualSample] = []
    
    // MARK: HealthKit
    let healthStore: HKHealthStore
    
    let onlyObserveSamplesFromCurrentApp = true
    
    var healthStoreUpdateCompletionHandler: (([MenstrualSample]) -> Void)?
    
    var sampleType: HKSampleType {
        return HKObjectType.categoryType(forIdentifier: .menstrualFlow)!
    }
    
    var authorizationRequired: Bool {
        return healthStore.authorizationStatus(for: sampleType) == .notDetermined
    }
    
    func authorize() {
        healthStore.requestAuthorization(toShare: [sampleType], read: [sampleType]) { success, error in
            if let error = error {
                print(error)
            } else if success {
                self.setUpBackgroundDelivery()
            }
        }
    }

    func setUpBackgroundDelivery() {
        #if os(iOS)
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
        #endif
    }
    
    // MARK: Data Retrieval
    let dataFetch = DispatchQueue(label: "com.nova.MenstrualStoreQueue", qos: .utility)
    
    let noFlowPredicate = HKQuery.predicateForCategorySamples(
        with: .equalTo,
        value: HKCategoryValueMenstrualFlow.none.rawValue
    )
    
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
    
    func getRecentMenstrualSamples(days: Int = 90, _ completion: @escaping (_ result: [MenstrualSample]) -> Void) {
        dispatchPrecondition(condition: .onQueue(dataFetch))
        // Go 'days' back
        let start = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        var newMenstrualEvents: [MenstrualSample] = []
        
        let updateGroup = DispatchGroup()
        updateGroup.enter()
        getRecentMenstrualSamples(start: start, matching: makeCompoundPredicateIfNeeded(for: noFlowPredicate), sampleLimit: days) {
            (result) in
            switch result {
            case .success(let samples):
                newMenstrualEvents = newMenstrualEvents + samples.map { MenstrualSample(sample: $0, flowLevel: HKCategoryValueMenstrualFlow.none) }
            default:
                break
            }
            updateGroup.leave()
        }

        updateGroup.enter()
        getRecentMenstrualSamples(start: start, matching: makeCompoundPredicateIfNeeded(for: hadFlowPredicate), sampleLimit: days) {
            (result) in
            switch result {
            case .success(let samples):
                newMenstrualEvents = newMenstrualEvents + samples.map { MenstrualSample(sample: $0, flowLevel: HKCategoryValueMenstrualFlow.unspecified) }
            default:
                break
            }
            updateGroup.leave()
        }
        
        updateGroup.enter()
        getRecentMenstrualSamples(start: start, matching: makeCompoundPredicateIfNeeded(for: lightFlowPredicate), sampleLimit: days) {
            (result) in
            switch result {
            case .success(let samples):
                newMenstrualEvents = newMenstrualEvents + samples.map { MenstrualSample(sample: $0, flowLevel: HKCategoryValueMenstrualFlow.light) }
            default:
                break
            }
            updateGroup.leave()
        }
        
        updateGroup.enter()
        getRecentMenstrualSamples(start: start, matching: makeCompoundPredicateIfNeeded(for: mediumFlowPredicate), sampleLimit: days) {
            (result) in
            switch result {
            case .success(let samples):
                newMenstrualEvents = newMenstrualEvents + samples.map { MenstrualSample(sample: $0, flowLevel: HKCategoryValueMenstrualFlow.medium) }
            default:
                break
            }
            updateGroup.leave()
        }
        
        updateGroup.enter()
        getRecentMenstrualSamples(start: start, matching: makeCompoundPredicateIfNeeded(for: heavyFlowPredicate), sampleLimit: days) {
            (result) in
            switch result {
            case .success(let samples):
                newMenstrualEvents = newMenstrualEvents + samples.map { MenstrualSample(sample: $0, flowLevel: HKCategoryValueMenstrualFlow.heavy) }
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
    
    // Make compound predicate to only read from current app if that's necessary
    func makeCompoundPredicateIfNeeded(for predicate: NSPredicate) -> NSPredicate {
        guard onlyObserveSamplesFromCurrentApp else {
            return predicate
        }
        return NSCompoundPredicate(
            andPredicateWithSubpredicates: [
                predicate,
                HKQuery.predicateForObjects(from: HKSource.default())
            ]
        )
    }
    
    // MARK: Data Statistics
    func hasMenstrualFlow(at date: Date) -> Bool {
        for event in menstrualEvents {
            if eventWithinDate(date, event) && event.flowLevel != .none {
                return true
            }
        }
        return false
    }
    
    func menstrualEventIfPresent(for date: Date) -> MenstrualSample? {
        for event in menstrualEvents {
            if eventWithinDate(date, event) {
                return event
            }
        }
        return nil
    }
    
    func eventWithinDate(_ date: Date, _ event: MenstrualSample) -> Bool {
        return (event.startDate <= date && event.endDate >= date) || Calendar.current.isDate(event.startDate, inSameDayAs: date) || Calendar.current.isDate(event.endDate, inSameDayAs: date)
    }
    
    func flowLevel(for selection: SelectionState, with volume: Int) -> HKCategoryValueMenstrualFlow {
        switch selection {
        // Values from https://www.everydayhealth.com/womens-health/menstruation/making-sense-menstrual-flow/ based on 5 mL flow = 1 pad
        case .hadFlow:
            switch volume {
            case let val where 0 < val && val < 15:
                return .light
            case let val where 15 <= val && val <= 30:
                return .medium
            case let val where val > 30:
                return .heavy
            default:
                return .unspecified
            }
        case .noFlow:
            return .none
        case .none:
            fatalError("Calling hkFlowLevel when entry is .none")
        }
    }
}


// MARK: Data Management
extension MenstrualStore {
    func saveInHealthKit(sample: MenstrualSample?, date: Date, newVolume: Int, flowSelection: SelectionState, _ completion: @escaping (MenstrualStoreResult<Bool>) -> Void) {
        let saveCompletion: (MenstrualStoreResult<Bool>) -> () = { result in
            completion(result)
        }
        
        if let sample = sample {
            if flowSelection == .none {
                deleteSample(sample, saveCompletion)
            } else {
                sample.volume = newVolume
                sample.flowLevel = flowLevel(for: flowSelection, with: newVolume)
                updateSample(sample, saveCompletion)
            }
        } else if flowSelection != .none {
            let sample = MenstrualSample(startDate: date, endDate: date, flowLevel: flowLevel(for: flowSelection, with: newVolume), volume: newVolume)
            saveSample(sample, saveCompletion)
        }
    }
    
    func saveSample(_ sample: MenstrualSample, _ completion: @escaping (MenstrualStoreResult<Bool>) -> ()) {
        dataFetch.async {
            self.save(sample) { result in
                completion(result)
            }
        }
    }
    
    func deleteSample(_ sample: MenstrualSample, _ completion: @escaping (MenstrualStoreResult<Bool>) -> ()) {
        dataFetch.async {
            self.delete(sample) { result in
                completion(result)
            }
        }
    }
    
    func updateSample(_ sample: MenstrualSample,  _ completion: @escaping (MenstrualStoreResult<Bool>) -> ()) {
        dataFetch.async {
            self.replace(sample) { result in
                completion(result)
            }
        }
    }
    
    func save(_ entry: MenstrualSample, _ completion: @escaping (MenstrualStoreResult<Bool>) -> ()) {
        dispatchPrecondition(condition: .onQueue(dataFetch))
        
        let persistedSample = HKCategorySample(entry: entry)
        healthStore.save(persistedSample) { success, error in
            if let error = error {
                print("Error: \(String(describing: error))")
                completion(.failure(.queryError(error.localizedDescription)))
            }
            if success {
                print("Saved: \(success)")
                completion(.success(true))
            }
        }
    }
    
    func replace(_ entry: MenstrualSample, _ completion: @escaping (MenstrualStoreResult<Bool>) -> ()) {
        dispatchPrecondition(condition: .onQueue(dataFetch))

        self.deleteSample(entry) { result in
            switch result {
            case .success:
                self.dataFetch.async {
                    self.saveSample(entry) { saveResult in
                        completion(saveResult)
                    }
                }
            case .failure:
                completion(result)
            }
        }
    }
    
    func delete(_ entry: MenstrualSample, _ completion: @escaping (MenstrualStoreResult<Bool>) -> ()) {
        dispatchPrecondition(condition: .onQueue(dataFetch))
        
        let predicate = HKQuery.predicateForObject(with: entry.uuid)
        healthStore.deleteObjects(of: sampleType, predicate: predicate) { success, count, error in
            if let error = error {
                print("Error: \(String(describing: error))")
                completion(.failure(.queryError(error.localizedDescription)))
            }
            if success {
                print("Deleted \(count) samples: \(success)")
                completion(.success(true))
            }
        }
    }
}
