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
    @State var isSheetPresented: Bool = false
    @State var datePresented: Date = Date()

    private var calendarDuraton: DateInterval { calendar.dateInterval(of: .quarter, for: Date())! }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                CalendarView(interval: calendarDuraton) { date in
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
                            .onTapGesture {
                                self.datePresented = date
                                self.isSheetPresented.toggle()
                            }
                            .disabled(date > Date())
                    }
                    .onAppear {
                        if self.viewModel.store.authorizationRequired {
                            self.viewModel.store.authorize()
                        }
                    }
                VStack {
                    Group {
                        if isSheetPresented {
                            MenstrualEventEditor(viewModel: self.viewModel, sample: self.viewModel.menstrualEventIfPresent(for: self.datePresented))
                        }
                    }
                }
                .background(Color(UIColor.systemBackground).shadow(radius: 5))
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
