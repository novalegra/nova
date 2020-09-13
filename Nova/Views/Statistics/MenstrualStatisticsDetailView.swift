//
//  MenstrualStatisticsDetailView.swift
//  Nova
//
//  Created by Anna Quinlan on 9/12/20.
//  Copyright © 2020 Anna Quinlan. All rights reserved.
//

import SwiftUI

enum MenstrualStatistic {
    case length
    case volume
}

struct MenstrualStatisticsDetailView: View {
    @ObservedObject var viewModel: MenstrualDataManager
    let title: String
    let mode: MenstrualStatistic
    
    var body: some View {
        List {
            averageSecton
            ForEach(viewModel.reverseOrderedPeriods, id: \.startDate) { period in
                self.section(for: period)
            }
        }
        .listStyle(GroupedListStyle())
        .environment(\.horizontalSizeClass, .regular)
        .navigationBarTitle(Text(title), displayMode: .large)
    }
    
    var averageSecton: some View {
        // FIXME: empty header is hack to fix SwiftUI jumping with GroupedListStyle
        Section(header: Text("")) {
            HStack {
                Text("Average")
                .bold()
                Spacer()
            }
            HStack {
                SegmentedGaugeBar(scaler: 1)
                .frame(minHeight: 20, maxHeight: 20)
                Text(mode == .length ? "\(viewModel.averagePeriodLength) days" : "\( viewModel.averageDailyPeriodVolume) ml/day")
                .bold()
                .font(.callout)
            }
        }
    }
    
    func section(for event: MenstrualPeriod) -> some View {
        Section {
            HStack {
                Text(viewModel.monthFormattedDate(for: event.startDate) + " - " + viewModel.monthFormattedDate(for: event.endDate))
                .foregroundColor(Color("DarkBlue"))
                Spacer()
            }
            HStack {
                SegmentedGaugeBar(scaler: scaler(for: event))
                .frame(minHeight: 20, maxHeight: 20)
                Text(description(of: event))
                .font(.callout)
            }
        }
    }
    
    func description(of event: MenstrualPeriod) -> String {
        switch mode {
        case .volume:
            return "\(Int(event.averageFlow)) ml/day"
        case .length:
            return event.duration == 1 ? "\(event.duration) day" : "\(event.duration) days"
        }
    }
    
    func scaler(for event: MenstrualPeriod) -> Double {
        switch mode {
        case .volume:
            return event.averageFlow / Double(viewModel.averageDailyPeriodVolume)
        default:
            return Double(event.duration) / Double(viewModel.averagePeriodLength)
        }
    }
}
