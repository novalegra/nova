//
//  NotificationManager.swift
//  Nova
//
//  Created by Anna Quinlan on 10/3/22.
//  Copyright © 2022 Anna Quinlan. All rights reserved.
//
import UserNotifications

struct NotificationManager {
    enum Action: String {
        case cupChangeReminder
    }
    
    private static var defaultReminderInterval = TimeInterval(hours: 12)
    
    static func scheduleCupChangeNotification() {
        Self.scheduleCupChangeNotification(after: Self.defaultReminderInterval)
    }
    
    static func scheduleCupChangeNotification(after interval: TimeInterval) {
        let notification = UNMutableNotificationContent()

        notification.title =  String(format: NSLocalizedString("Time to empty your cup!", comment: "The notification title for a reminder to empty the menstrual cup."))
        notification.body = String(format: NSLocalizedString("It's been 12 hours since you last emptied your cup.", comment: "The notification description for a reminder to empty the menstrual cup."))
        notification.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)

        // Keep the ID the same to always replace any outstanding notifications
        let request = UNNotificationRequest(
            identifier: Self.Action.cupChangeReminder.rawValue,
            content: notification,
            trigger: trigger
        )

        NSLog("Scheduled notification for \(interval) from \(Date())")
        UNUserNotificationCenter.current().add(request)
    }
    
    static func ensureAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                Self.authorize()
            }
        }
    }
    
    static func authorize(_ completion: ((Bool, Error?) -> Void)? = nil) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            NSLog("Tried to authorize notifications; success: \(granted)")
            completion?(granted, error)
        }
    }
}
