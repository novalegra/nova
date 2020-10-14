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
    @ObservedObject var dataManager: WatchDataManager = WatchDataManager()
    
    var body: some View {
        List {
            ForEach(reversedDays, id: \.self) { date in
                FlowTile(date: date)
                .listRowBackground(buttonColor(for: date))
                .cornerRadius(10)
            }
        }
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
    
    private func buttonColor(for date: Date) -> Color {
        if date > Date() {
            return Color(UIColor.gray.withAlphaComponent(0.14))
        }
        if self.dataManager.hasMenstrualFlow(at: date) {
            return Color("DarkPink")
        }
        return Color("LightBrown")
    }
}

struct FlowTile: View {
    let date: Date
    let dateFormatter = DateFormatter()
    
    init(date: Date) {
        self.date = date
    }
    
    func formattedDate(for date: Date) -> String {
        dateFormatter.dateFormat = "EEE, MMM dd"
        return dateFormatter.string(from: date)
    }
    
    var body: some View {
        LazyVStack {
            Text(formattedDate(for: date))
            .foregroundColor(Color.black)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        WatchMainView()
    }
}
