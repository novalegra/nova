//
//  WatchDataCoordinator.swift
//  Nova
//
//  Created by Anna Quinlan on 10/13/20.
//  Copyright © 2020 Anna Quinlan. All rights reserved.
//

import WatchConnectivity

// iOS app manager of watch data & data sending
class WatchDataCoordinator {    
    private var watchSession: WCSession? = {
        if WCSession.isSupported() {
            return WCSession.default
        } else {
            return nil
        }
    }()
    
    func updateWatch(with events: [MenstrualSample]) {
        guard let session = watchSession, session.isPaired, session.isWatchAppInstalled else {
            return
        }

        guard case .activated = session.activationState else {
            session.activate()
            return
        }

        let eventsDict = ["events": events]
        
        do {
            print("Updating watch data")
            try session.updateApplicationContext(eventsDict)
        } catch let error {
            print(String(describing: error))
        }
    }
}
