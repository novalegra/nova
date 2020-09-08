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
    var menstrualEvents: [MenstrualSample] = []
    
    init(store: MenstrualStore) {
        self.store = store
        startTimer()
    }
    
    deinit {
        stopTimer()
    }
    
    // MARK: Data Refresh
    var timer: DispatchSourceTimer?
    let refreshInterval = 12 /* hours */ * 60 /* minutes */ * 60 /* seconds */

    private func startTimer() {
        timer = DispatchSource.makeTimerSource(queue: store.dataFetch)
        timer!.schedule(deadline: .now(), repeating: .seconds(refreshInterval))
        timer!.setEventHandler { [weak self] in
            print("Getting samples")
            self?.store.getRecentMenstrualSamples({ samples in
                self?.menstrualEvents = samples.map { MenstrualSample(sample: $0) }
                print("Success retrieving samples \(samples)")
            })
        }
        timer!.resume()
    }

    func stopTimer() {
        timer?.cancel()
        timer = nil
    }
    
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
