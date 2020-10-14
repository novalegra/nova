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
    override init() {
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
            print("Not sending events", events, "because there's no watch session")
            return
        }
        
        guard session.isPaired, session.isWatchAppInstalled else {
            print("Not sending events", events, "because session isn't paired or app isn't installed")
            return
        }

        if session.activationState != .activated {
            session.activate()
            return
        }

        let encodedEvents = try encoder.encode(events)
        let eventsDict = ["events": encodedEvents]
        
        print("Updating watch data with", eventsDict)
        try session.updateApplicationContext(eventsDict)
    }
}

extension WatchDataCoordinator: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        switch activationState {
        case .activated:
            if let error = error {
                print("%{public}@", String(describing: error))
            } else {
                print("Activated session")
                // TODO: send events
            }
        case .inactive, .notActivated:
            break
        @unknown default:
            break
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
