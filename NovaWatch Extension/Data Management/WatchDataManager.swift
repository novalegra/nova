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
    @Published var menstrualEvents: [MenstrualSample] = []
    @Published var selection: SelectionState = .none
    
    override init() {
        super.init()

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
            print("Couldn't get events")
            return
        }
        let events = try decoder.decode([MenstrualSample].self, from: codedEvents)
        DispatchQueue.main.async {
            self.menstrualEvents = events
        }
        scheduleSnapshot()
    }
    
    private func scheduleSnapshot() {
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
    
    // MARK: Settings
    var volumeUnit: VolumeType = UserDefaults.app?.volumeType ?? .mL
    
    var cupType: MenstrualCupType = UserDefaults.app?.menstrualCupType ?? .lenaSmall
    
    var flowPickerNumbers: [Int] {
        switch volumeUnit {
        case .mL:
            return Array(0...120)
        case .percentOfCup:
            return Array(0...30).map { $0 * 10 }
        }
    }
    
    var flowPickerMin: Int {
        return flowPickerNumbers.first!
    }
    
    var flowPickerMax: Int {
        return flowPickerNumbers.last!
    }
    
    var flowPickerInterval: Int {
        switch volumeUnit {
        case .mL:
            return 1
        case .percentOfCup:
            return 10
        }
    }

    func save(sample: MenstrualSample?, date: Date, newVolume: Int, _ completion: @escaping (Bool) -> Void) {
        let info = RecordedMenstrualEventInfo(sample: sample, date: date, volume: newVolume, selectionState: selection)
        
        WCSession.default.sendMenstrualEvent(info, completion: completion)
    }
}

extension WatchDataManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated {
            print("Watch received data")
            do {
                try updateMenstrualData(session.receivedApplicationContext)
            } catch let error {
                print(error)
            }
            
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("Watch received data")
        do {
            try updateMenstrualData(applicationContext)
        } catch let error {
            print(error)
        }
    }
}

extension WCSession {
    func sendMenstrualEvent(_ userInfo: RecordedMenstrualEventInfo, completion: @escaping (Bool) -> Void) {
        guard activationState == .activated, isReachable else {
            print("Not activated or not reachable")
            completion(false)
            return
        }
        
        print(userInfo.rawValue)

        sendMessage(userInfo.rawValue,
            replyHandler: { reply in
                completion(true)
            },
            errorHandler: { error in
                print(error)
                completion(false)
            }
        )
    }
}
