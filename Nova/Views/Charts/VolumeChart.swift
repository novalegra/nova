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
    let viewModel: TotalVolumeViewModel

    @State private var selected: MenstrualVolumePoint.ID?
    
    var body: some View {
        ScrollView(.horizontal) {
            chart
                .padding()
                .chartOverlay { proxy in
                    GeometryReader { g in
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 5)
                                    .onChanged { value in
                                        let origin = g[proxy.plotAreaFrame].origin
                                        let x = value.location.x - origin.x
                                        if
                                            let selectedTitle: String = proxy.value(atX: x),
                                            let selected = viewModel.points.first(where: { $0.title == selectedTitle })
                                        {
                                            print("selecting \(selectedTitle) with start \(selected.start)")
                                            self.selected = selected.start
                                        }
                                    }
                                // Remove the annotation once the user isn't tapping anymore
                                    .onEnded { value in
                                        self.selected = nil
                                    }
                            )
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
            
            if let selected, let item = viewModel.points.first(where: { $0.id == selected }) {
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
