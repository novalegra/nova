//
//  MenstrualDataManager.swift
//  Nova
//
//  Created by Anna Quinlan on 9/7/20.
//  Copyright © 2020 Anna Quinlan. All rights reserved.
//

import SwiftUI
import HealthKit

class MenstrualDataManager: ObservableObject {
    let store: MenstrualStore
    // Allowable gap (in days) between samples so it's still considered a period
    let allowablePeriodGap: Int = 1
    @Published var selection: SelectionState = .none
    @Published var periods: [MenstrualPeriod] = []
    
    var reverseOrderedPeriods: [MenstrualPeriod] {
        return periods.reversed()
    }
    
    let dateFormatter = DateFormatter()
    
    init(store: MenstrualStore) {
        self.store = store
        store.healthStoreUpdateCompletionHandler = { [weak self] updatedEvents in
            DispatchQueue.main.async {
                if let processedPeriods = self?.processHealthKitQuerySamples(updatedEvents) {
                    self?.periods = processedPeriods
                }
            }
        }
    }
    
    // MARK: Data Management
    func saveSample(_ sample: MenstrualSample, _ completion: @escaping (MenstrualStoreResult<Bool>) -> ()) {
        store.dataFetch.async {
            self.store.saveSample(sample) { result in
                completion(result)
            }
        }
    }
    
    func deleteSample(_ sample: MenstrualSample, _ completion: @escaping (MenstrualStoreResult<Bool>) -> ()) {
        store.dataFetch.async {
            self.store.deleteSample(sample) { result in
                completion(result)
            }
        }
    }
    
    func updateSample(_ sample: MenstrualSample,  _ completion: @escaping (MenstrualStoreResult<Bool>) -> ()) {
        store.dataFetch.async {
            self.store.replaceSample(sample) { result in
                completion(result)
            }
        }
    }
    
    // This function assumes samples are sorted with most-recent ones first
    // The output menstrual periods are in sorted order
    func processHealthKitQuerySamples(_ samples: [MenstrualSample]) -> [MenstrualPeriod] {
        guard samples.count > 0 else {
            return []
        }

        let sortedSamples = samples.sorted(by: { $0.startDate < $1.startDate })
        var output: [MenstrualPeriod] = []
        var periodBuilder: [MenstrualSample] = []

        for sample in sortedSamples {
            if sample.flowLevel == .none {
                continue
            }
            
            if let last = periodBuilder.last, let dayGap = Calendar.current.dateComponents([.day], from: last.endDate, to: sample.startDate).day, dayGap - 1 > allowablePeriodGap {
                output.append(MenstrualPeriod(events: periodBuilder))
                periodBuilder = []
            }
            
            periodBuilder.append(sample)
        }
        
        // Make sure all periods are accounted for
        if periodBuilder.count > 0 {
            output.append(MenstrualPeriod(events: periodBuilder))
        }
        
        return output
    }
    
    // MARK: Computed Properties
    var lastPeriodDate: String {
        return yearFormattedDate(for: periods.last?.startDate)
    }
    
    var averageTotalPeriodVolume: Int {
        let totalVolume = periods.reduce(0) {sum, curr in sum + curr.totalFlow}
        let totalPeriods = periods.reduce(0) {sum, curr in curr.averageDailyFlow > 0 ? sum + 1: sum}
        
        guard totalPeriods > 0 else {
            return 0
        }
        return Int(totalVolume) / totalPeriods
    }
    
    var averageDailyPeriodVolume: Int {
        let totalVolume = periods.reduce(0) {sum, curr in sum + curr.averageDailyFlow}
        let totalPeriods = periods.reduce(0) {sum, curr in curr.averageDailyFlow > 0 ? sum + 1: sum}
        
        guard totalPeriods > 0 else {
            return 0
        }
        return Int(totalVolume) / totalPeriods
    }
    
    var averagePeriodLength: Int {
        guard periods.count > 0 else {
            return 0
        }
        return periods.reduce(0) {sum, curr in sum + curr.duration} / periods.count
    }
    
    // MARK: Data Helper Functions
    func hasMenstrualFlow(at date: Date) -> Bool {
        return store.hasMenstrualFlow(at: date)
    }
    
    func menstrualEventIfPresent(for date: Date) -> MenstrualSample? {
        return store.menstrualEventIfPresent(for: date)
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
    
    func yearFormattedDate(for date: Date?) -> String {
        guard let date = date else {
            return "None"
        }
        dateFormatter.dateFormat = "MM-dd-yyyy"
        return dateFormatter.string(from: date)
    }
    
    func monthFormattedDate(for date: Date?) -> String {
        guard let date = date else {
            return "None"
        }
        dateFormatter.dateFormat = "MMM dd"
        return dateFormatter.string(from: date)
    }
    
    func save(sample: MenstrualSample?, date: Date, newVolume: Int, _ completion: @escaping (MenstrualStoreResult<Bool>) -> Void) {
        let saveCompletion: (MenstrualStoreResult<Bool>) -> () = { result in
            completion(result)
        }
        
        if let sample = sample {
            if selection == .none {
                deleteSample(sample, saveCompletion)
            } else {
                sample.volume = newVolume
                sample.flowLevel = flowLevel(for: selection, with: newVolume)
                updateSample(sample, saveCompletion)
            }
        } else if selection != .none {
            let sample = MenstrualSample(startDate: date, endDate: date, flowLevel: flowLevel(for: selection, with: newVolume), volume: newVolume)
            saveSample(sample, saveCompletion)
        }
    }
    
    // MARK: Settings
    var volumeUnit: VolumeType = UserDefaults.app?.volumeType ?? .mL {
        didSet {
            UserDefaults.app?.volumeType = volumeUnit
        }
    }
    
    var cupType: MenstrualCupType = UserDefaults.app?.menstrualCupType ?? .lenaSmall {
        didSet {
            UserDefaults.app?.menstrualCupType = cupType
        }
    }
    
    var flowPickerOptions: [String] {
        flowPickerNumbers.map { String($0) }
    }
    
    var flowPickerNumbers: [Int] {
        switch volumeUnit {
        case .mL:
            return Array(0...80)
        case .percentOfCup:
            return Array(0...10).map { $0 * 10 }
        }
    }
    
    func closestNumberOnPicker(num: Int) -> Int {
        return  flowPickerNumbers.reduce(flowPickerNumbers.first!) { abs($1 - num) < abs($0 - num) ? $1 : $0 }
    }
}
