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
import HealthKit

class WatchDataManager: NSObject, ObservableObject, WKExtensionDelegate {
    @Published var menstrualEvents: [MenstrualSample] = []
    @Published var selection: SelectionState = .none
    var store: MenstrualStore
    
    override init() {
        let healthStore = HKHealthStore()
        store = MenstrualStore(healthStore: healthStore)
        
        super.init()

        store.healthStoreUpdateCompletionHandler = { [weak self] updatedEvents in
            self?.menstrualEvents = updatedEvents
        }
        if store.authorizationRequired {
            store.authorize()
        }
        
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    private func updateMenstrualData(_ context: [String: Any]) throws {
        guard let codedEvents = context["events"] as? Data else {
            NSLog("Couldn't get coded events (got \(context) instead)")
            return
        }
        let events = try decoder.decode([MenstrualSample].self, from: codedEvents)
        DispatchQueue.main.async { [unowned self] in
            menstrualEvents = events
            store.menstrualEvents = events
        }
    }
    
    func hasMenstrualFlow(at date: Date) -> Bool {
        return store.hasMenstrualFlow(at: date)
    }
    
    func menstrualEventIfPresent(for date: Date) -> MenstrualSample? {
        return store.menstrualEventIfPresent(for: date)
    }
    
    // MARK: Settings
    var volumeUnit: VolumeType = UserDefaults.app?.volumeType ?? .percentOfCup
    
    var cupType: MenstrualCupType = UserDefaults.app?.menstrualCupType ?? .lenaSmall
    
    var flowPickerNumbers: [Int] {
        switch volumeUnit {
        case .mL:
            return Array(0...120)
        case .percentOfCup:
            return Array(0...30).map { $0 * 10 }
        }
    }

    func save(sample: MenstrualSample?, date: Date, newVolume: Double, _ completion: @escaping (Bool) -> Void) {
        let info = RecordedMenstrualEventInfo(sample: sample, date: date, volume: newVolume, selectionState: selection)
        WCSession.default.didUpdateMenstrualEvents(info) { [unowned self] didSave in
            if didSave {
                NSLog("Watch was told that sample was saved in HK on phone")
                completion(didSave)
                return
            }
            
            // If it didn't save on the phone, save it on the watch
            // This is the backup option since the watch health store is much slower to sync
            // TODO: handle case where HealthStore is locked (update current cache appropriately)
            store.saveInHealthKit(sample: sample, date: date, newVolume: newVolume, flowSelection: selection) { result in
                switch result {
                case .success:
                    NSLog("Successfully saved samples to HK on watch")
                    completion(true)
                case .failure(let error):
                    NSLog("Error saving samples in watch: \(error)")
                    completion(false)
                }
            }
        }
    }
}

extension WatchDataManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated {
            NSLog("Watch received data")
            do {
                try updateMenstrualData(session.receivedApplicationContext)
            } catch let error {
                NSLog("\(error)")
            }
            
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        NSLog("Watch received data")
        do {
            try updateMenstrualData(applicationContext)
        } catch let error {
            NSLog("Error updating watch events in response to data: \(error)")
        }
    }
}

extension WCSession {
    func didUpdateMenstrualEvents(_ userInfo: RecordedMenstrualEventInfo, completion: @escaping (Bool) -> Void) {
        guard activationState == .activated, isReachable else {
            NSLog("Not activated or not reachable")
            completion(false)
            return
        }
        
        NSLog("Sending", String(describing: userInfo.sample), "to phone")

        sendMessage(userInfo.rawValue,
            replyHandler: { reply in
                NSLog("Reply from iPhone in response to HK save request: \(String(describing: reply["didSave"] as? Bool))")
                completion(reply["didSave"] as? Bool ?? false)
            },
            errorHandler: { error in
                NSLog("Error sending watch events: \(error)")
                completion(false)
            }
        )
    }
}
