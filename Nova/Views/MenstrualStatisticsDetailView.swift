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
            ForEach(viewModel.periods, id: \.startDate) { period in
                self.section(for: period)
            }
        }
        .listStyle(GroupedListStyle())
        .environment(\.horizontalSizeClass, .regular)
        .navigationBarTitle(Text(title), displayMode: .large)
    }
    
    func section(for event: MenstrualPeriod) -> some View {
        Section {
            HStack {
                Text(viewModel.getFormattedDate(for: event.startDate) + " to " + viewModel.getFormattedDate(for: event.endDate))
                Spacer()
            }
            SegmentedGaugeBar(scaler: statisticValue(for: event))
            .frame(maxHeight: 20)
        }
        
    }
    
    func statisticValue(for event: MenstrualPeriod) -> Double {
        switch mode {
        case .volume:
            return event.averageFlow / viewModel.getAverageVolume()
        default:
            return 1 // TODO: period length
        }
    }
}
