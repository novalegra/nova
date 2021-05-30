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

    private var calendarDuration: DateInterval {
        let now = calendar.startOfDay(for: Date())
        let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: now)!
        
        return DateInterval(start: threeMonthsAgo, end: now.addingTimeInterval(60 * 60 * 24))
    }

    var body: some View {
        NavigationView {
            CalendarView(interval: calendarDuration) { date in
                NavigationLink(
                    destination: MenstrualEventEditor(viewModel: viewModel, sample: viewModel.menstrualEventIfPresent(for: date), date: date)
                ) {
                    Text("00") // Placeholder so circles are correct size
                        .hidden()
                        .padding(8)
                        .background(buttonColor(for: date))
                        .clipShape(Circle())
                        .padding(.vertical, 4)
                        .overlay(
                            Text(String(calendar.component(.day, from: date)))
                                .foregroundColor(Color.black)
                        )
                }
                .disabled(date > Date())
            }
            .onAppear {
                if viewModel.store.authorizationRequired {
                    viewModel.store.authorize()
                    viewModel.store.setUpBackgroundDelivery()
                }
            }
            .navigationBarTitle("Cycle Overview", displayMode: .large)
        }
    }
    
    private func buttonColor(for date: Date) -> Color {
        if date > Date() {
            return Color(UIColor.gray.withAlphaComponent(0.14))
        }
        if viewModel.hasMenstrualFlow(at: date) {
            return Color("DarkPink")
        }
        return Color("LightBrown")
    }
}
