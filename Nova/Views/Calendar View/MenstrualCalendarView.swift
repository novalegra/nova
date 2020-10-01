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
    @ObservedObject var viewModel: MenstrualDataManager

    private var calendarDuraton: DateInterval {
        let now = Date()
        let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: now)!
        
        return DateInterval(start: threeMonthsAgo, end: now)
    }

    var body: some View {
        NavigationView {
            CalendarView(interval: calendarDuraton) { date in
                NavigationLink(
                    destination: MenstrualEventEditor(viewModel: self.viewModel, sample: self.viewModel.menstrualEventIfPresent(for: date), date: date)
                ) {
                    Text("00") // Placeholder so circles are correct size
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
                    self.viewModel.store.setUpBackgroundDelivery()
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
