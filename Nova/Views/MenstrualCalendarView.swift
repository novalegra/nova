//
//  MenstrualCalendarView.swift
//  Nova
//
//  Created by Anna Quinlan on 9/7/20.
//  Copyright © 2020 Anna Quinlan. All rights reserved.
//

import SwiftUI

struct MenstrualCalendarView: View {
    @Environment(\.calendar) var calendar

    private var threeMonths: DateInterval { calendar.dateInterval(of: .quarter, for: Date())! }

    var body: some View {
        NavigationView {
            CalendarView(interval: threeMonths) { date in
                // Add navigation
                Text("00") // Placeholder so it works
                    .hidden()
                    .padding(8)
                    .background(Color("DarkPink"))
                    .clipShape(Circle())
                    .padding(.vertical, 4)
                    .overlay(
                        Text(String(self.calendar.component(.day, from: date)))
                        .foregroundColor(Color.white)
                    )
            }
            .navigationBarTitle("Cycle Overview", displayMode: .large)
        }
    }
}
