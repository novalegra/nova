//
//  CalendarView.swift
//  Nova
//
//  Created by Anna Quinlan on 9/7/20.
//  Copyright © 2020 Anna Quinlan. All rights reserved.
//

import SwiftUI

enum CalendarScrollPosition {
    case oldest
    case newest
}

struct CalendarView<DateView>: View where DateView: View {
    @Environment(\.calendar) var calendar

    let interval: DateInterval
    let initialScrollPosition: CalendarScrollPosition
    let content: (Date) -> DateView

    init(interval: DateInterval,
         initialPosition: CalendarScrollPosition = .oldest,
         @ViewBuilder content: @escaping (Date) -> DateView) {
        self.interval = interval
        self.initialScrollPosition = initialPosition
        self.content = content
    }

    private var months: [Date] {
        return calendar.generateDates(
            inside: interval,
            matching: DateComponents(day: 1, hour: 0, minute: 0, second: 0)
        )
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    ForEach(months, id: \.self) { month in
                        MonthView(month: month, content: content)
                    }
                }
            }
                .onAppear {
                    if
                        initialScrollPosition == .newest,
                        let scrollPosition = months.last
                    {
                        // Animate so the change is more obvious
                        withAnimation {
                            proxy.scrollTo(scrollPosition)
                        }
                    }
                }
        }
    }
}
