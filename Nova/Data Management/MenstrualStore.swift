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

enum MenstrualSaveAction {
    case saveNewSample
    case deleteSample
    case updateSample
    case unknown
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
    
    func authorize(completion: ((Error?) -> Void)? = nil) {
        healthStore.requestAuthorization(toShare: [sampleType], read: [sampleType]) { success, error in
            if success {
                self.setUpBackgroundDelivery()
            }
            completion?(error)
        }
    }

    func setUpBackgroundDelivery() {
        #if os(iOS)
            let query = HKObserverQuery(sampleType: sampleType, predicate: nil) { [weak self] (query, completionHandler, error) in
                self?.fetchAndUpdateMenstrualData(completion: completionHandler)
            }
            healthStore.execute(query)
            healthStore.enableBackgroundDelivery(for: sampleType, frequency: .immediate) { (enabled, error) in
                NSLog("enableBackgroundDeliveryForType handler called for \(self.sampleType) - success: \(enabled), error: \(String(describing: error))")
            }
        #endif
    }
    
    // MARK: Data Retrieval
    let dataFetch = DispatchQueue(label: "com.nova.MenstrualStoreQueue", qos: .utility)
    
    func fetchAndUpdateMenstrualData(completion: (() -> Void)? = nil) {
        dataFetch.async { [unowned self] in
            getRecentMenstrualSamples() { samples in
                NSLog("Wooho - got \(samples.count) updated samples from HealthKit; \(samples.filter { $0.flowLevel == .heavy }.count) heavy, \(samples.filter { $0.flowLevel == .medium }.count) medium, \(samples.filter { $0.flowLevel == .light }.count) light, \(samples.filter { $0.flowLevel == .unspecified }.count) unspecified")
                healthStoreUpdateCompletionHandler?(samples)
                completion?()
            }
        }
    }
    
    /// Fetch samples for all of the different menstrual data types (no flow, light, medium, and heavy)
    fileprivate func getRecentMenstrualSamples(days: Int = 90, _ completion: @escaping (_ result: [MenstrualSample]) -> Void) {
        dispatchPrecondition(condition: .onQueue(dataFetch))
        // Go 'days' back
        let start = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        var newMenstrualEvents: [MenstrualSample] = []
        
        let updateGroup = DispatchGroup()
        updateGroup.enter()
        getSamples(start: start, matching: addCurrentAppFilterIfNeeded(to: MenstrualPredicates.noFlowPredicate), sampleLimit: days) {
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
        getSamples(start: start, matching: addCurrentAppFilterIfNeeded(to: MenstrualPredicates.hadFlowPredicate), sampleLimit: days) {
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
        getSamples(start: start, matching: addCurrentAppFilterIfNeeded(to: MenstrualPredicates.lightFlowPredicate), sampleLimit: days) {
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
        getSamples(start: start, matching: addCurrentAppFilterIfNeeded(to: MenstrualPredicates.mediumFlowPredicate), sampleLimit: days) {
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
        getSamples(start: start, matching: addCurrentAppFilterIfNeeded(to: MenstrualPredicates.heavyFlowPredicate), sampleLimit: days) {
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

    /// Get the samples from HealthKit that match the provided predicate. Must be called on the `dataFetch` queue.
    /// @param start is the earliest start time that samples can have
    /// @param end is the latest start time that samples can have; defaults to current time
    /// @param predicate is the filter to apply to the samples
    /// @param completion is the block that's called with the retrieved samples
    fileprivate func getSamples(start: Date, end: Date = Date(), matching predicate: NSPredicate, sampleLimit: Int, _ completion: @escaping (_ result: MenstrualStoreResult<[HKCategorySample]>) -> Void) {
        dispatchPrecondition(condition: .onQueue(dataFetch))
        
        // get more-recent values first
        let sortByDate = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: sampleLimit, sortDescriptors: [sortByDate]) { (query, samples, error) in

            if let error = error {
                NSLog("Error fetching menstrual data: %{public}@", String(describing: error))
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
    
    /// Make compound predicate to only read from current app if the settings specify that we should
    fileprivate func addCurrentAppFilterIfNeeded(to predicate: NSPredicate) -> NSPredicate {
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
    
    func flowLevel(for selection: SelectionState, with volume: Double) -> HKCategoryValueMenstrualFlow {
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
    // completion: success value contains nil if sample was deleted or non-nil if item was updated/cancelled
    func saveInHealthKit(existingSample: MenstrualSample?, date: Date, newVolume: Double, flowSelection: SelectionState, _ completion: @escaping (MenstrualStoreResult<MenstrualSample?>) -> Void) {
        switch action(existingSample: existingSample, date: date, newVolume: newVolume, flowSelection: flowSelection) {
        case .saveNewSample:
            let sample = MenstrualSample(startDate: date, endDate: date, flowLevel: flowLevel(for: flowSelection, with: newVolume), volume: newVolume)
            saveSample(sample) { result in
                switch result {
                case .success:
                    completion(.success(sample))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        case .updateSample:
            guard let sample = existingSample else {
                break
            }
            
            sample.volume = newVolume
            sample.flowLevel = flowLevel(for: flowSelection, with: newVolume)
            updateSample(sample) { result in
                switch result {
                case .success:
                    completion(.success(sample))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        case .deleteSample:
            guard let sample = existingSample else {
                break
            }
            
            deleteSample(sample) { result in
                switch result {
                case .success:
                    completion(.success(nil))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        case .unknown:
            NSLog("Not doing anything to sample")
        }
    }
    
    func action(existingSample: MenstrualSample?, date: Date, newVolume: Double, flowSelection: SelectionState) -> MenstrualSaveAction {
        if existingSample != nil {
            // The sample has no flow, so delete it
            if flowSelection == .none {
                return .deleteSample
            // The sample has an updated volume, so update the volume
            } else {
                return .updateSample
            }
        // Add a new menstrual event
        } else if flowSelection != .none {
            return .saveNewSample
        }
        
        return .unknown
    }
    
    func saveSample(_ sample: MenstrualSample, _ completion: @escaping (MenstrualStoreResult<Bool>) -> ()) {
        dataFetch.async { [unowned self] in
            save(sample) { result in
                completion(result)
            }
        }
    }
    
    func deleteSample(_ sample: MenstrualSample, _ completion: @escaping (MenstrualStoreResult<Bool>) -> ()) {
        dataFetch.async { [unowned self] in
            delete(sample) { result in
                completion(result)
            }
        }
    }
    
    func updateSample(_ sample: MenstrualSample,  _ completion: @escaping (MenstrualStoreResult<Bool>) -> ()) {
        dataFetch.async { [unowned self] in
            replace(sample) { result in
                completion(result)
            }
        }
    }
    
    fileprivate func save(_ entry: MenstrualSample, _ completion: @escaping (MenstrualStoreResult<Bool>) -> ()) {
        dispatchPrecondition(condition: .onQueue(dataFetch))
        
        let persistedSample = HKCategorySample(entry: entry)
        healthStore.save(persistedSample) { success, error in
            if let error = error {
                NSLog("Error: \(String(describing: error))")
                completion(.failure(.queryError(error.localizedDescription)))
            }
            if success {
                NSLog("Saved: \(success)")
                completion(.success(true))
            }
        }
    }
    
    fileprivate func replace(_ entry: MenstrualSample, _ completion: @escaping (MenstrualStoreResult<Bool>) -> ()) {
        dispatchPrecondition(condition: .onQueue(dataFetch))
        // Bump the version so we can disambiguate
        entry.syncVersion += 1

        deleteSample(entry) { [unowned self] result in
            switch result {
            case .success:
                dataFetch.async {
                    saveSample(entry) { saveResult in
                        completion(saveResult)
                    }
                }
            case .failure:
                completion(result)
            }
        }
    }
    
    fileprivate func delete(_ entry: MenstrualSample, _ completion: @escaping (MenstrualStoreResult<Bool>) -> ()) {
        dispatchPrecondition(condition: .onQueue(dataFetch))
        
        let predicate = HKQuery.predicateForObject(with: entry.uuid)
        healthStore.deleteObjects(of: sampleType, predicate: predicate) { success, count, error in
            if let error = error {
                NSLog("Error: \(String(describing: error))")
                completion(.failure(.queryError(error.localizedDescription)))
            }
            if success {
                NSLog("Deleted \(count) samples: \(success)")
                completion(.success(true))
            }
        }
    }
}

// MARK: Async/Await Bridges
extension MenstrualStore {
    func authorize() async throws -> Void {
        return try await withCheckedThrowingContinuation({
            (continuation: CheckedContinuation<Void, Error>) in
            authorize() { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        })
    }
    
    func saveInHealthKit(existingSample: MenstrualSample?, date: Date, newVolume: Double, flowSelection: SelectionState) async -> MenstrualStoreResult<MenstrualSample?> {
        return await withCheckedContinuation({
            (continuation: CheckedContinuation<MenstrualStoreResult<MenstrualSample?>, Never>) in
            saveInHealthKit(existingSample: existingSample, date: date, newVolume: newVolume, flowSelection: flowSelection) { result in
                continuation.resume(returning: result)
            }
        })
    }
    
    func saveSample(_ sample: MenstrualSample) async -> MenstrualStoreResult<Bool> {
        return await withCheckedContinuation({
            (continuation: CheckedContinuation<MenstrualStoreResult<Bool>, Never>) in
            saveSample(sample) { result in
                continuation.resume(returning: result)
            }
        })
    }
    
    func deleteSample(_ sample: MenstrualSample) async -> MenstrualStoreResult<Bool> {
        return await withCheckedContinuation({
            (continuation: CheckedContinuation<MenstrualStoreResult<Bool>, Never>) in
            deleteSample(sample) { result in
                continuation.resume(returning: result)
            }
        })
    }
    
    func updateSample(_ sample: MenstrualSample) async -> MenstrualStoreResult<Bool> {
        return await withCheckedContinuation({
            (continuation: CheckedContinuation<MenstrualStoreResult<Bool>, Never>) in
            updateSample(sample) { result in
                continuation.resume(returning: result)
            }
        })
    }
    
    func fetchAndUpdateMenstrualData() async {
        return await withCheckedContinuation({
            (continuation: CheckedContinuation<Void, Never>) in
            fetchAndUpdateMenstrualData {
                continuation.resume()
            }
        })
    }
}
