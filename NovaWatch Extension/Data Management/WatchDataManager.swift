//
//  WatchDataManager.swift
//  NovaWatch Extension
//
//  Created by Anna Quinlan on 10/7/20.
//  Copyright © 2020 Anna Quinlan. All rights reserved.
//

import Foundation
import SwiftUI
import WatchConnectivity
import WatchKit

class WatchDataManager: NSObject, ObservableObject, WKExtensionDelegate {
    var menstrualEvents: [MenstrualSample] = []
    
    override init() {
        super.init()

        let session = WCSession.default
        session.delegate = self
        session.activate()
    }
    
    private func updateMenstrualData(_ context: [String: Any]) {
        print(context)
        guard let events = context["events"] as? [MenstrualSample] else {
            print("Couldn't get events")
            return
        }
        menstrualEvents = events
        menstrualDataDidUpdate()
    }
    
    private func menstrualDataDidUpdate() {
        if WKExtension.shared().applicationState != .active {
            WKExtension.shared().scheduleSnapshotRefresh(withPreferredDate: Date(), userInfo: nil) { (error) in
                if let error = error {
                    print("scheduleSnapshotRefresh error: %{public}@", String(describing: error))
                }
            }
        }
    }
    
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
}

extension WatchDataManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated {
            print("Watch received data")
            updateMenstrualData(session.receivedApplicationContext)
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("Watch received data")
        updateMenstrualData(applicationContext)
    }
}
