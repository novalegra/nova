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
        #if swift(>=5.2)
            if #available(iOS 14.0, *) {
                mainBody
                .listStyle(InsetGroupedListStyle())
            } else {
                mainBody
                    .listStyle(GroupedListStyle())
                    .environment(\.horizontalSizeClass, .regular)
            }
        #else
            mainBody
            .listStyle(GroupedListStyle())
            .environment(\.horizontalSizeClass, .regular)
        #endif
    }
    
    var mainBody: some View {
        List {
            averageSection
            ForEach(viewModel.reverseOrderedPeriods, id: \.startDate) { period in
                self.section(for: period)
            }
        }
        .navigationBarTitle(Text(title), displayMode: .large)
    }
    
    var averageSection: some View {
        // FIXME: empty header is hack to fix SwiftUI jumping with GroupedListStyle
        Section(header: Text("")) {
            // FIXME: VStack is a hack to fix spacing in iOS 14.1
            VStack(spacing: 10) {
                HStack {
                    Text("Average")
                    .bold()
                    Spacer()
                }
                if !averageDataIsMissing {
                    HStack {
                        SegmentedGaugeBar(scaler: 1)
                        .frame(minHeight: 20, maxHeight: 20)
                        Text(averageMeasurementLabel)
                        .bold()
                        .font(.callout)
                    }
                } else {
                    HStack {
                        Text("No data")
                        Spacer()
                    }
                }
            }
            .padding(5)
        }
    }
    
    var averageMeasurementLabel: String {
        switch mode {
        case .length:
            return viewModel.averagePeriodLength == 1 ? "\(viewModel.averagePeriodLength) day" : "\(viewModel.averagePeriodLength) days"
        case .dailyVolume:
            return "\(viewModel.averageDailyPeriodVolume) mL"
        case .overallVolume:
            return "\(viewModel.averageTotalPeriodVolume) mL"
        }
    }
    
    func section(for period: MenstrualPeriod) -> some View {
        Section {
            // FIXME: VStack is a hack to fix spacing in iOS 14.1
            VStack(spacing: 10) {
                HStack {
                    Text(viewModel.monthFormattedDate(for: period.startDate) + " - " + viewModel.monthFormattedDate(for: period.endDate))
                    .foregroundColor(Color("DarkBlue"))
                    Spacer()
                }
                if !dataIsMissing(for: period) {
                    HStack {
                        SegmentedGaugeBar(scaler: scaler(for: period))
                        .frame(minHeight: 20, maxHeight: 20)
                        Text(description(of: period))
                        .font(.callout)
                    }
                } else {
                    HStack {
                        Text("No data")
                        Spacer()
                    }
                }
            }
            .padding(5)
        }
    }
    
//    func visualRepresentation(for period: MenstrualPeriod) -> some View {
//        return Group {
//            if !dataIsMissing(for: period) {
//                HStack {
//                    SegmentedGaugeBar(scaler: scaler(for: period))
//                    .frame(minHeight: 20, maxHeight: 20)
//                    Text(description(of: period))
//                    .font(.callout)
//                }
//            } else {
//                HStack {
//                    Text("No data")
//                    Spacer()
//                }
//            }
//        }
//    }
    
    func description(of period: MenstrualPeriod) -> String {
        switch mode {
        case .dailyVolume:
            return "\(Int(period.averageDailyFlow)) mL"
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
    
    func dataIsMissing(for period: MenstrualPeriod) -> Bool {
        switch mode {
        case .dailyVolume:
            return period.averageDailyFlow == 0
        case .overallVolume:
            return period.totalFlow == 0
        default:
            return false
        }
    }
    
    var averageDataIsMissing: Bool {
        switch mode {
        case .dailyVolume:
            return viewModel.averageDailyPeriodVolume == 0
        case .overallVolume:
            return viewModel.averageTotalPeriodVolume == 0
        default:
            return false
        }
    }
}
