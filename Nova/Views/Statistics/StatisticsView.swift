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
                    totalVolumeItem
                    dailyVolumeChart
                    dailyVolumeItem
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
    
    var dailyVolumeItem: some View {
        NavigationLink(
            destination: MenstrualStatisticsDetailView(viewModel: viewModel, title: "Daily Volume", mode: .dailyVolume)
        ) {
            HStack {
                Text("Typical Daily Volume")
                Spacer()
                Text("\(Int(viewModel.averageDailyPeriodVolume)) mL")
                    .bold()
            }
        }
        .disabled(viewModel.periods.count < 1)
    }
    
    var totalVolumeItem: some View {
        NavigationLink(
            destination: MenstrualStatisticsDetailView(viewModel: viewModel, title: "Period Volume", mode: .overallVolume)
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
    
    var totalVolumeChart: some View {
        NavigationLink(
            destination: VolumeChart(viewModel: viewModel.makeTotalVolumeViewModel())
        ) {
            HStack {
                Text("Period Volume Chart")
                Spacer()
                Text("\(Int(viewModel.averageTotalPeriodVolume)) mL")
                    .bold()
            }
        }
        .disabled(viewModel.periods.count < 1)
    }
    
    var periodLengthChart: some View {
        NavigationLink(
            destination: VolumeChart(viewModel: viewModel.makePeriodLengthViewModel())
        ) {
            HStack {
                Text("Typical Period Length")
                Spacer()
                Text(viewModel.averagePeriodLength != 1 ? "\(viewModel.averagePeriodLength) days" :  "\(viewModel.averagePeriodLength) day")
                    .bold()
            }
        }
        .disabled(viewModel.periods.count < 1)
    }
    
    var dailyVolumeChart: some View {
        NavigationLink(
            destination: VolumeChart(viewModel: viewModel.makeDailyVolumeViewModel())
        ) {
            HStack {
                Text("Daily Volume Chart")
                Spacer()
            }
        }
        .disabled(viewModel.periods.count < 1)
    }
    
    var periodLengthItem: some View {
        NavigationLink(
            destination: MenstrualStatisticsDetailView(viewModel: viewModel, title: "Period Length", mode: .length)
        ) {
            HStack {
                Text("Typical Period Length")
                Spacer()
                Text(viewModel.averagePeriodLength != 1 ? "\(viewModel.averagePeriodLength) days" :  "\(viewModel.averagePeriodLength) day")
                    .bold()
            }
        }
        .disabled(viewModel.periods.count < 1)
    }
}
