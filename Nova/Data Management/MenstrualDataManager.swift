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
    @Published var menstrualEvents: [MenstrualSample] = []
    @Published var selection: SelectionState = .none
    var periods: [MenstrualPeriod] = []
    
    let dateFormatter = DateFormatter()
    
    init(store: MenstrualStore) {
        self.store = store
        store.healthStoreUpdateCompletionHandler = { [weak self] updatedEvents in
            DispatchQueue.main.async {
                self?.menstrualEvents = updatedEvents
                if let processedPeriods = self?.processHealthKitQuerySamples(updatedEvents) {
                    self?.periods = processedPeriods
                }
            }
        }
    }
    
    // MARK: Data Management
    func saveSample(_ sample: MenstrualSample) {
        store.dataFetch.async {
            self.store.saveSample(sample)
        }
    }
    
    func deleteSample(_ sample: MenstrualSample) {
        store.dataFetch.async {
            self.store.deleteSample(sample)
        }
    }
    
    func updateSample(_ sample: MenstrualSample) {
        store.dataFetch.async {
            self.store.replaceSample(sample)
        }
    }
    
    // This function assumes samples are sorted with most-recent ones first
    // The output menstrual periods are in sorted order
    func processHealthKitQuerySamples(_ samples: [MenstrualSample]) -> [MenstrualPeriod] {
        guard samples.count > 0 else {
            return []
        }

        var output: [MenstrualPeriod] = []
        var periodBuilder: [MenstrualSample] = []
        
        var i = samples.count - 1
        while i >= 0 {
            defer {
                i -= 1
            }
            
            let sample = samples[i]
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
    
    // MARK: Helper Functions
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
    
    func getFormattedDate(for date: Date?) -> String {
        guard let date = date else {
            return "None"
        }
        dateFormatter.dateFormat = "MM-dd-yyyy"
        return dateFormatter.string(from: date)
    }
    
    func getLastPeriodDate() -> String {
        return getFormattedDate(for: periods.last?.startDate)
    }
    
    func getAverageVolume() -> Double {
        var totalVolume = 0
        var totalEvents = 0
        
        for event in menstrualEvents {
            if let volume = event.volume, volume > 0 {
                totalVolume += volume
                totalEvents += 1
            }
        }
        
        guard totalEvents > 0 else {
            return 0
        }
        
        return Double(totalVolume) / Double(totalEvents)
    }
    
    func save(sample: MenstrualSample?, date: Date, selectedIndex: Int) {
        let volume = selection == .hadFlow ? Int(flowPickerOptions[selectedIndex]): 0
        
        if let sample = sample {
            if selection == .none {
                deleteSample(sample)
            } else {
                sample.volume = volume
                sample.flowLevel = flowLevel(for: selection, with: selectedIndex)
                updateSample(sample)
            }
        } else if selection != .none {
            let sample = MenstrualSample(startDate: date, endDate: date, flowLevel: flowLevel(for: selection, with: selectedIndex), volume: volume)
            saveSample(sample)
        }
    }
    
    // MARK: Volume Selection
    let flowPickerOptions = (0...80).map { String($0) }
}