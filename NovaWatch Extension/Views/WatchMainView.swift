//
//  ContentView.swift
//  NovaWatch Extension
//
//  Created by Anna Quinlan on 10/7/20.
//  Copyright © 2020 Anna Quinlan. All rights reserved.
//

import SwiftUI
import Foundation

struct WatchMainView: View {
    @Environment(\.calendar) var calendar
    @StateObject var dataManager: WatchDataManager = WatchDataManager()
    
    var body: some View {
        List {
            ForEach(reversedDays, id: \.self) { date in
                NavigationLink(
                    destination: MenstrualEventEditor(viewModel: dataManager, sample: dataManager.menstrualEventIfPresent(for: date), date: date)
                ) {
                    FlowTile(date: date, dataManager: dataManager)
                }
                .padding(5)
                .frame(height: 50)
                .listRowBackground(Color.white.cornerRadius(15))
                .disabled(date > Date())
                .buttonStyle(PlainButtonStyle())
            }
        }
        .listStyle(CarouselListStyle())
        .navigationTitle(Text("Overview"))
    }

    private var calendarDuration: DateInterval {
        let now = calendar.startOfDay(for: Date())
        let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: now)!
        
        return DateInterval(start: threeMonthsAgo, end: now.addingTimeInterval(60 * 60 * 24))
    }
    
    private var reversedDays: [Date] {
        return days.reversed()
    }
    
    private var days: [Date] {
        return calendar.generateDates(
            inside: calendarDuration,
            matching: DateComponents(hour: 0, minute: 0, second: 0)
        )
    }
}
