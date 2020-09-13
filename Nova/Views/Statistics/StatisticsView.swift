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
                averageVolumeItem
                averagePeriodLength
            }
            .navigationBarTitle("Statistics", displayMode: .large)
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
    
    var averageVolumeItem: some View {
        NavigationLink(
            destination: MenstrualStatisticsDetailView(viewModel: viewModel, title: "Menstrual Volume", mode: .volume)
        ) {
            HStack {
                Text("Typical Daily Menstrual Volume")
                Spacer()
                Text("\(viewModel.averageDailyPeriodVolume) ml")
                .bold()
            }
        }
        .disabled(viewModel.periods.count < 1)
    }
    
    var averagePeriodLength: some View {
        NavigationLink(
            destination: MenstrualStatisticsDetailView(viewModel: viewModel, title: "Menstrual Volume", mode: .length)
        ) {
            HStack {
                Text("Typical Period Length")
                Spacer()
                Text(viewModel.averagePeriodLength > 1 ? "\(viewModel.averagePeriodLength) days" :  "\(viewModel.averagePeriodLength) day")
                .bold()
            }
        }
        .disabled(viewModel.periods.count < 1)
    }
}
