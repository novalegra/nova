//
//  VolumeChart.swift
//  Nova
//
//  Created by Anna Quinlan on 10/23/22.
//  Copyright © 2022 Anna Quinlan. All rights reserved.
//

import SwiftUI
import Charts

struct VolumeChart: View {
    @ObservedObject var viewModel: TotalVolumeViewModel
    
    var body: some View {
        ScrollView(.horizontal) {
            chart
                .padding()
                .chartOverlay { proxy in
                    GeometryReader { g in
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .onTapGesture { value in
                                let origin = g[proxy.plotAreaFrame].origin
                                let x = value.x - origin.x
                                
                                if let selectedTitle: String = proxy.value(atX: x) {
                                    viewModel.didSelect(title: selectedTitle)
                                }
                            }
                    }
                }
        }
        .navigationBarTitle("Typical Period Volume")
    }
    
    var chart: some View {
        Chart {
            ForEach(viewModel.points) {
                BarMark(
                    x: .value("Date", $0.title),
                    y: .value("Volume", $0.flowVolume)
                )
                .foregroundStyle(Color.novaPink)
            }
            
            if let selected = viewModel.selected, let item = viewModel.point(id: selected) {
                RuleMark(x: .value("Date", item.title))
                    .foregroundStyle(Color(.label))
                
                PointMark(
                    x: .value("Date", item.title),
                    y: .value("Volume", item.flowVolume)
                )
                    .symbolSize(CGSize(width: 15, height: 15))
                    .foregroundStyle(Color(.label))
            }
        }
        .frame(width: ChartConstants.scrollWidth)
    }
}
