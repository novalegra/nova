//
//  WatchDataCoordinator.swift
//  Nova
//
//  Created by Anna Quinlan on 10/13/20.
//  Copyright © 2020 Anna Quinlan. All rights reserved.
//

import WatchConnectivity

// iOS app manager of watch data & data sending
class WatchDataCoordinator: NSObject {
    unowned let dataStore: MenstrualStore
    
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
        let eventsDict = ["events": encodedEvents]
        
        NSLog("Updating watch data with \(events.count) events; \(events.filter { $0.flowLevel == .heavy }.count) heavy, \(events.filter { $0.flowLevel == .medium }.count) medium, \(events.filter { $0.flowLevel == .light }.count) light, \(events.filter { $0.flowLevel == .unspecified }.count) unspecified")
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
                // TODO: send events
            }
        case .inactive, .notActivated:
            break
        @unknown default:
            break
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        NSLog("Got message from watch")
        switch message["name"] as? String {
        case RecordedMenstrualEventInfo.name?:
            if let data = RecordedMenstrualEventInfo(rawValue: message) {
                NSLog("Reacting to message for RecordedMenstrualEventInfo")

                dataStore.saveInHealthKit(sample: data.sample, date: data.date, newVolume: data.volume, flowSelection: data.selectionState) { [unowned self] result in
                    NSLog("HK save result: \(result)")
                    dataStore.manuallyUpdateMenstrualData()
                    replyHandler(["didSave": result])
                }
            }
        default:
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
