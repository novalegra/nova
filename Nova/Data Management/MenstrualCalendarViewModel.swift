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
    
    init(store: MenstrualStore) {
        self.store = store
        store.healthStoreUpdateCompletionHandler = { [weak self] updatedEvents in
            DispatchQueue.main.async {
                self?.menstrualEvents = updatedEvents
            }
        }
        store.setUpBackgroundDelivery()
    }
    
    // MARK: Data Refresh
    var timer: DispatchSourceTimer?
    let refreshInterval = 12 /* hours */ * 60 /* minutes */ * 60 /* seconds */
    
    // MARK: Helper Functions
    func hasMenstrualFlow(at date: Date) -> Bool {
        for event in menstrualEvents {
            if (event.startDate <= date && event.endDate >= date) || Calendar.current.isDate(event.startDate, inSameDayAs: date) || Calendar.current.isDate(event.endDate, inSameDayAs: date) {
                return true
            }
        }
        return false
    }
    
    func menstrualEventIfPresent(for date: Date) -> MenstrualSample? {
        for event in menstrualEvents {
            if (event.startDate <= date && event.endDate >= date) || Calendar.current.isDate(event.startDate, inSameDayAs: date) || Calendar.current.isDate(event.endDate, inSameDayAs: date) {
                return event
            }
        }
        return nil
    }
}
