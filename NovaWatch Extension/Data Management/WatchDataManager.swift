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
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    var volumeUnit: VolumeType = UserDefaults.app?.volumeType ?? .percentOfCup

    var cupType: MenstrualCupType = UserDefaults.app?.menstrualCupType ?? .lenaSmall
    
    var flowPickerNumbers: [Int] {
        switch volumeUnit {
        case .mL:
            return Array(0...120)
        case .percentOfCup:
            return Array(0...50).map { $0 * 10 }
        }
    }
    
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
    
    func percentToVolume(_ percent: Double) -> Double {
        return percent / 100 * cupType.maxVolume
    }

    func volumeToPercent(_ volume: Double) -> Double {
        return volume / cupType.maxVolume * 100
    }
    
    // MARK: Settings

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
            store.saveInHealthKit(existingSample: sample, date: date, newVolume: newVolume, flowSelection: selection) { result in
                switch result {
                case .success(let savedSample):
                    NSLog("Successfully saved samples to HK on watch")
                    DispatchQueue.main.async {
                        if let savedSample = savedSample {
                            addSampleToMenstrualEvents(savedSample)
                        } else {
                            deleteSampleFromMenstrualEvents(with: sample!.uuid)
                        }
                       
                        completion(true)
                    }
                case .failure(let error):
                    NSLog("Error saving samples in watch: \(error)")
                    completion(false)
                }
            }
        }
    }
    
    func addSampleToMenstrualEvents(_ sample: MenstrualSample) {
        guard let index = menstrualEvents.firstIndex(where: { $0.uuid == sample.uuid }) else {
            // Sample doesn't exist, so add to items
            menstrualEvents.append(sample)
            store.menstrualEvents.append(sample)
            return
        }
        
        // The sample is already in the list, so update it
        menstrualEvents[index] = sample
        store.menstrualEvents[index] = sample
    }
    
    func deleteSampleFromMenstrualEvents(with uuid: UUID) {
        guard let index = menstrualEvents.firstIndex(where: { $0.uuid == uuid }) else {
            fatalError("Passed in unique ID to delete, but no item has that ID")
        }
        menstrualEvents.remove(at: index)
        store.menstrualEvents.remove(at: index)
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
