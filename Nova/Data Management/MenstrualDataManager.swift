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
    @Published var menstrualEvents: [MenstrualSample] = []
    @Published var selection: SelectionState = .none
    
    let dateFormatter = DateFormatter()
    
    init(store: MenstrualStore) {
        self.store = store
        store.healthStoreUpdateCompletionHandler = { [weak self] updatedEvents in
            DispatchQueue.main.async {
                self?.menstrualEvents = updatedEvents
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
    
    // MARK: Helper Functions
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
    
    func getFormattedDate(for date: Date?) -> String {
        guard let date = date else {
            return "None"
        }
        dateFormatter.dateFormat = "MM-dd-yyyy"
        return dateFormatter.string(from: date)
    }
    
    func getLastPeriodDate() -> String {
        guard let event = menstrualEvents.first, event.flowLevel != .none else {
            return getFormattedDate(for: nil)
        }
        return getFormattedDate(for: menstrualEvents.first?.startDate)
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
        
        guard menstrualEvents.count > 0 else {
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
