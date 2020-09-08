//
//  MenstrualCalendarViewModel.swift
//  Nova
//
//  Created by Anna Quinlan on 9/7/20.
//  Copyright © 2020 Anna Quinlan. All rights reserved.
//

import SwiftUI
import HealthKit

class MenstrualCalendarViewModel: ObservableObject {
    let store: MenstrualStore
    @Published var menstrualEvents: [MenstrualSample] = []
    @Published var selection: SelectionState = .none
    
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
    
    // MARK: Volume Selection
    let flowPickerOptions = (0...45).map { String($0) }
}
