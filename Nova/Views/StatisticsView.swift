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
        HStack {
            Text("Average Daily Menstrual Volume:")
            Spacer()
            Text("\(String(format: "%.1f", viewModel.getAverageVolume())) mL")
        }
    }
}
