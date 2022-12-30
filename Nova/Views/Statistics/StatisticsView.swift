//
//  StatisticsView.swift
//  Nova
//
//  Created by Anna Quinlan on 9/11/20.
//  Copyright © 2020 Anna Quinlan. All rights reserved.
//

import SwiftUI

struct StatisticsView: View {
    @ObservedObject var viewModel: MenstrualDataManager
    
    var body: some View {
        NavigationView {
            List {
                lastPeriodItem
                Section {
                    totalVolumeChart
                    dailyVolumeChart
                    periodLengthChart
                }
            }
                .listStyle(InsetGroupedListStyle())
                .navigationBarTitle("Reports", displayMode: .large)
        }
    }
    
    var lastPeriodItem: some View {
        HStack {
            Text("Last Period")
            Spacer()
            Text(viewModel.lastPeriodDate)
                .bold()
        }
    }
    
    var totalVolumeChart: some View {
        NavigationLink(
            destination: ScrollableBarChart(viewModel: viewModel.makeTotalVolumeViewModel())
        ) {
            HStack {
                Text("Typical Period Volume")
                Spacer()
                Text("\(Int(viewModel.averageTotalPeriodVolume)) mL")
                    .bold()
            }
        }
        .disabled(viewModel.periods.count < 1)
    }
    
    var periodLengthChart: some View {
        NavigationLink(
            destination: ScrollableBarChart(viewModel: viewModel.makePeriodLengthViewModel())
        ) {
            HStack {
                Text("Typical Period Length")
                Spacer()
                // FIXME: use date formatter
                Text(viewModel.averagePeriodLength != 1 ? "\(viewModel.averagePeriodLength) days" :  "\(viewModel.averagePeriodLength) day")
                    .bold()
            }
        }
        .disabled(viewModel.periods.count < 1)
    }
    
    var dailyVolumeChart: some View {
        NavigationLink(
            destination: ScrollableBarChart(viewModel: viewModel.makeDailyVolumeViewModel())
        ) {
            HStack {
                Text("Typical Daily Volume")
                Spacer()
            }
        }
        .disabled(viewModel.periods.count < 1)
    }
}
