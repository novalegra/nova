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
                NavigationLink(
                    destination: MenstrualEventEditor(viewModel: self.viewModel, sample: self.viewModel.menstrualEventIfPresent(for: date))
                ) {
                    Text("00") // Placeholder so it works
                        .hidden()
                        .padding(8)
                        .background(self.buttonColor(for: date))
                        .clipShape(Circle())
                        .padding(.vertical, 4)
                        .overlay(
                            Text(String(self.calendar.component(.day, from: date)))
                                .foregroundColor(Color.black)
                        )
                }
                .disabled(date > Date())
            }
            .onAppear {
                if self.viewModel.store.authorizationRequired {
                    self.viewModel.store.authorize()
                }
            }
            .navigationBarTitle("Cycle Overview", displayMode: .large)
        }
    }
    
    private func buttonColor(for date: Date) -> Color {
        if date > Date() {
            return Color(UIColor.gray.withAlphaComponent(0.14))
        }
        if self.viewModel.hasMenstrualFlow(at: date) {
            return Color("DarkPink")
        }
        return Color("LightBrown")
    }
}
