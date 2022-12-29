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
    @ObservedObject var viewModel: VolumeViewModel
    
    var body: some View {
        VStack(alignment: .center) {
            interactiveChart
            if !viewModel.xAxisLabel.isEmpty {
                Text(viewModel.xAxisLabel)
            }
        }
        .navigationBarTitle(viewModel.title)
    }
    
    var interactiveChart: some View {
        /// ScrollView so the chart can scroll
        ScrollView(.horizontal) {
            chart
                .padding()
                /// Logic to detect tap & scroll events so an item description can be overlaid
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
                            .simultaneousGesture(
                                DragGesture(minimumDistance: ChartConstants.dragMinimum)
                                    .onChanged { value in
                                        let origin = g[proxy.plotAreaFrame].origin
                                        let x = value.location.x - origin.x
                                        
                                        if let selectedTitle: String = proxy.value(atX: x) {
                                            viewModel.didSlideOver(title: selectedTitle)
                                        }
                                    }
                                    .onEnded { _ in
                                        viewModel.didFinishSelecting()
                                    }
                            )
                    }
                }
                /// Display the axis on the leading edge instead of trailing edge
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
        }
    }
    
    var chart: some View {
        Chart {
            ForEach(viewModel.points) {
                BarMark(
                    x: .value("Date", $0.description),
                    y: .value($0.valueDescription, $0.value)
                )
                .foregroundStyle(Color.novaPink)
            }
            
            if let selected = viewModel.selected, let item = viewModel.point(id: selected), let annotationPosition = viewModel.selectionDetailPosition {
                RuleMark(x: .value("Date", item.description))
                    .foregroundStyle(Color(.label))
                    .annotation(position: annotationPosition, alignment: .top) {
                        Text(item.detailDescription)
                            .font(
                                .caption
                                .bold()
                            )
                            .roundedBorder()
                    }
            }
        }
        .frame(width: ChartConstants.scrollWidth)
    }
}
