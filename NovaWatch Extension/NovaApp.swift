//
//  NovaApp.swift
//  NovaWatch Extension
//
//  Created by Anna Quinlan on 10/7/20.
//  Copyright © 2020 Anna Quinlan. All rights reserved.
//

import SwiftUI

@main
struct NovaApp: App {
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                WatchMainView()
            }
        }

        WKNotificationScene(controller: NotificationController.self, category: "novaWatchApp")
    }
}
