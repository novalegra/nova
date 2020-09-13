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
    case dailyVolume
    case overallVolume
}

struct MenstrualStatisticsDetailView: View {
    @ObservedObject var viewModel: MenstrualDataManager
    let title: String
    let mode: MenstrualStatistic
    
    var body: some View {
        List {
            averageSection
            ForEach(viewModel.reverseOrderedPeriods, id: \.startDate) { period in
                self.section(for: period)
            }
        }
        .listStyle(GroupedListStyle())
        .environment(\.horizontalSizeClass, .regular)
        .navigationBarTitle(Text(title), displayMode: .large)
    }
    
    var averageSection: some View {
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
                Text(averageMeasurementLabel)
                .bold()
                .font(.callout)
            }
        }
    }
    
    var averageMeasurementLabel: String {
        switch mode {
        case .length:
            return viewModel.averagePeriodLength == 1 ? "\(viewModel.averagePeriodLength) day" : "\(viewModel.averagePeriodLength) days"
        case .dailyVolume:
            return "\(viewModel.averageDailyPeriodVolume) mL/day"
        case .overallVolume:
            return "\(viewModel.averageTotalPeriodVolume) mL"
        }
    }
    
    func section(for period: MenstrualPeriod) -> some View {
        Section {
            HStack {
                Text(viewModel.monthFormattedDate(for: period.startDate) + " - " + viewModel.monthFormattedDate(for: period.endDate))
                .foregroundColor(Color("DarkBlue"))
                Spacer()
            }
            HStack {
                SegmentedGaugeBar(scaler: scaler(for: period))
                .frame(minHeight: 20, maxHeight: 20)
                Text(description(of: period))
                .font(.callout)
            }
        }
    }
    
    func description(of period: MenstrualPeriod) -> String {
        switch mode {
        case .dailyVolume:
            return "\(Int(period.averageDailyFlow)) mL/day"
        case .overallVolume:
            return "\(period.totalFlow) mL"
        case .length:
            return period.duration == 1 ? "\(period.duration) day" : "\(period.duration) days"
        }
    }
    
    func scaler(for period: MenstrualPeriod) -> Double {
        switch mode {
        case .dailyVolume:
            return period.averageDailyFlow / Double(viewModel.averageDailyPeriodVolume)
        case .overallVolume:
        return Double(period.totalFlow) / Double(viewModel.averageTotalPeriodVolume)
        case .length:
            return Double(period.duration) / Double(viewModel.averagePeriodLength)
        }
    }
}
