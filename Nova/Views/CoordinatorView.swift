//
//  CoordinatorView.swift
//  Nova
//
//  Created by Anna Quinlan on 9/11/20.
//  Copyright © 2020 Anna Quinlan. All rights reserved.
//

import SwiftUI

struct CoordinatorView: View {
    @ObservedObject var viewModel: MenstrualDataManager
    
    var body: some View {
        TabView {
            MenstrualCalendarView(viewModel: viewModel)
            .tabItem {
                Image(systemName: "calendar")
                Text("Calendar", comment: "Label for calendar menu item")
            }
            StatisticsView(viewModel: viewModel)
            .tabItem {
                
                Image(systemName: "heart.fill")
                Text("Reports", comment: "Label for reports menu item")
            }
        }
    }
}
