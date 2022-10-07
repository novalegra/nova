//
//  WatchDataCoordinator.swift
//  Nova
//
//  Created by Anna Quinlan on 10/13/20.
//  Copyright © 2020 Anna Quinlan. All rights reserved.
//

import WatchConnectivity
import UIKit

// iOS app manager of watch data & data sending
class WatchDataCoordinator: NSObject {
    unowned let dataStore: MenstrualStore
    /// Used to coordinate access UIApplication.shared properties from non-main threads
    let mainThreadAccessGroup = DispatchGroup()
    
    init(dataStore: MenstrualStore) {
        self.dataStore = dataStore
        super.init()
        watchSession?.delegate = self
        watchSession?.activate()
    }
    
    private var watchSession: WCSession? = {
        if WCSession.isSupported() {
            return WCSession.default
        } else {
            return nil
        }
    }()
    
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    
    func updateWatch(with events: [MenstrualSample]) throws {
        mainThreadAccessGroup.enter()
        var protectedDataAvailable: Bool!
        DispatchQueue.main.async { [unowned self] in
            protectedDataAvailable = UIApplication.shared.isProtectedDataAvailable
            mainThreadAccessGroup.leave()
        }
        mainThreadAccessGroup.wait()
        
        guard protectedDataAvailable else {
            NSLog("Not sending events because phone is locked")
            return
        }
        
        guard let session = watchSession else {
            NSLog("Not sending events", events, "because there's no watch session")
            return
        }
        
        guard session.isPaired, session.isWatchAppInstalled else {
            NSLog("Not sending events", events, "because session isn't paired or app isn't installed")
            return
        }

        if session.activationState != .activated {
            session.activate()
            return
        }

        let encodedEvents = try encoder.encode(events)
        let eventsDict = [
            WatchDataCodingKeys.events.rawValue: encodedEvents,
            WatchDataCodingKeys.cupType.rawValue: UserDefaults.app?.menstrualCupType?.rawValue ?? MenstrualCupType.lenaSmall.rawValue,
            
        ] as [String : Any]

        try session.updateApplicationContext(eventsDict)
    }
}

extension WatchDataCoordinator: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        switch activationState {
        case .activated:
            if let error = error {
                NSLog("%{public}@", String(describing: error))
            } else {
                NSLog("Activated session")
            }
        case .inactive, .notActivated:
            break
        @unknown default:
            break
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        switch message["name"] as? String {
        case RecordedMenstrualEventInfo.name?:
            mainThreadAccessGroup.enter()
            var protectedDataAvailable: Bool!
            DispatchQueue.main.async { [unowned self] in
                protectedDataAvailable = UIApplication.shared.isProtectedDataAvailable
                mainThreadAccessGroup.leave()
            }
            mainThreadAccessGroup.wait()
            
            guard protectedDataAvailable else {
                // Kick it back to the watch to save if the HK stores are locked
                replyHandler(["didSave": false])
                return
            }
            
            if let data = RecordedMenstrualEventInfo(rawValue: message) {
                NSLog("Reacting to message for RecordedMenstrualEventInfo")

                dataStore.saveInHealthKit(existingSample: data.sample, date: data.date, newVolume: data.volume, flowSelection: data.selectionState) { [unowned self] result in
                    switch result {
                    case .success:
                        NSLog("Successfully saved to HK on phone in response to watch request")
                        dataStore.fetchAndUpdateMenstrualData()
                        replyHandler(["didSave": true])
                    case .failure(let error):
                        NSLog("Error saving to HK on phone in response to watch request: \(error.localizedDescription)")
                        replyHandler(["didSave": false])
                    }
                }
            }
        default:
            NSLog("Unable to respond to message from watch: unknown message type")
            replyHandler(["didSave": false])
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        // We don't need to do anything
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        watchSession = WCSession.default
        watchSession?.delegate = self
        watchSession?.activate()
    }
}
