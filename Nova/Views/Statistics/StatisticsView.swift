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
//                SegmentedGaugeBar(scaler: 1.5)
//                SegmentedGaugeBar(scaler: 3)
//                SegmentedGaugeBar(scaler: 0.1)
            }
            .navigationBarTitle("Statistics", displayMode: .large)
        }
        
    }
    
    var lastPeriodItem: some View {
        HStack {
            Text("Last Recorded Period Date:")
            Spacer()
            Text(viewModel.getLastPeriodDate())
        }
    }
    
    var averageVolumeItem: some View {
        NavigationLink(
            destination: MenstrualStatisticsDetailView(viewModel: viewModel, title: "Menstrual Volume", mode: .volume)
        ) {
            HStack {
                Text("Average Daily Menstrual Volume:")
                Spacer()
                Text("\(String(format: "%.1f", viewModel.getAverageVolume())) ml")
            }
        }
        .disabled(viewModel.periods.count < 1)
    }
}
