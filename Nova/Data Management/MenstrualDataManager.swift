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
    let watchManager: WatchDataCoordinator
    // Allowable gap (in days) between samples so it's still considered a period
    let allowablePeriodGap: Int = 1
    @Published var periods: [MenstrualPeriod] = []
    
    var reverseOrderedPeriods: [MenstrualPeriod] {
        return periods.reversed()
    }
    
    let dateFormatter = DateFormatter()
    
    init(store: MenstrualStore) {
        self.store = store
        self.watchManager = WatchDataCoordinator(dataStore: store)
        store.healthStoreUpdateCompletionHandler = { [weak self] updatedEvents in
            DispatchQueue.main.async {
                if let processedPeriods = self?.processHealthKitQuerySamples(updatedEvents) {
                    self?.periods = processedPeriods
                }
            }

            do {
                try self?.watchManager.updateWatch(with: updatedEvents)
            } catch let error {
                NSLog("Error while passing data to watch: \(error)")
            }
        }
    }
    
    // MARK: Data Management
    
    /// This function assumes samples are sorted with most-recent ones first
    /// The output menstrual periods are in sorted order
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
    
    var averageTotalPeriodVolume: Double {
        let totalVolume = periods.reduce(0.0) {sum, curr in sum + curr.totalFlow}
        let totalPeriods = periods.reduce(0.0) {sum, curr in curr.averageDailyFlow > 0 ? sum + 1: sum}
        
        guard totalPeriods > 0 else {
            return 0
        }
        return totalVolume / totalPeriods
    }
    
    var averageDailyPeriodVolume: Double {
        let totalVolume = periods.reduce(0.0) {sum, curr in sum + curr.averageDailyFlow}
        let totalPeriods = periods.reduce(0.0) {sum, curr in curr.averageDailyFlow > 0 ? sum + 1: sum}
        
        guard totalPeriods > 0 else {
            return 0
        }
        return totalVolume / totalPeriods
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
    
    func year(from date: Date?) -> String {
        guard let date = date else {
            return "None"
        }
        dateFormatter.dateFormat = "yyyy"
        return dateFormatter.string(from: date)
    }
    
    func save(sample: MenstrualSample?, date: Date, newVolume: Double, flowSelection: SelectionState, _ completion: @escaping (MenstrualStoreResult<MenstrualSample?>) -> Void) {
        store.saveInHealthKit(sample: sample, date: date, newVolume: newVolume, flowSelection: flowSelection, completion)
    }
    
    // MARK: Settings
    var volumeUnit: VolumeType = UserDefaults.app?.volumeType ?? .percentOfCup {
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
        flowPickerNumbers.map { String(Int($0)) }
    }
    
    var flowPickerNumbers: [Double] {
        switch volumeUnit {
        case .mL:
            return Array(0...240).map { Double($0) }
        case .percentOfCup:
            return Array(0...120).map { Double($0 * 5) }
        }
    }
    
    func closestNumberOnPicker(num: Double) -> Double {
        return flowPickerNumbers.reduce(flowPickerNumbers.first!) { abs($1 - num) < abs($0 - num) ? $1 : $0 }
    }
}
