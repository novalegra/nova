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
    @ObservedObject var viewModel: MenstrualCalendarViewModel

    private var calendarDuraton: DateInterval { calendar.dateInterval(of: .quarter, for: Date())! }

    var body: some View {
        NavigationView {
            CalendarView(interval: calendarDuraton) { date in
                NavigationLink(destination:
                    MenstrualEventEditor(sample: self.viewModel.menstrualEventIfPresent(for: date))
                ) {
                    Text("00") // Placeholder so it works
                        .hidden()
                        .padding(8)
                        .background(self.viewModel.hasMenstrualFlow(at: date) ? Color("DarkPink") : Color("LightBrown"))
                        .clipShape(Circle())
                        .padding(.vertical, 4)
                        .overlay(
                            Text(String(self.calendar.component(.day, from: date)))
                            .foregroundColor(Color("CalendarDate"))
                        )
                }
            }
            .onAppear {
                if self.viewModel.store.authorizationRequired {
                    self.viewModel.store.authorize()
                }
            }
            .navigationBarTitle("Cycle Overview", displayMode: .large)
        }
    }
}
