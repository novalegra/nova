//
//  EventEditor.swift
//  NovaWatch Extension
//
//  Created by Anna Quinlan on 10/14/20.
//  Copyright © 2020 Anna Quinlan. All rights reserved.
//

import SwiftUI

struct MenstrualEventEditor: View {
    @ObservedObject var viewModel: WatchDataManager
    let sample: MenstrualSample?
    let date: Date

    @State var selectedPercent: Double = 0
    
    init(viewModel: WatchDataManager, sample: MenstrualSample?, date: Date) {
        self.sample = sample
        self.viewModel = viewModel
        self.date = date
    }
    
    var body: some View {
        List {
            Section {
                hadFlowRow
                noFlowRow
            }
            if self.viewModel.selection == .hadFlow {
                flowPickerRow
            }
        }
        .onAppear {
            if let sample = self.sample {
                self.viewModel.selection = sample.flowLevel == .none ? .noFlow : .hadFlow
            } else {
                self.viewModel.selection = .none
            }
            self.selectedPercent = Double(volumeToPercent(sample?.volume ?? 0))
        }
        .onDisappear {
            self.saveEvent()
        }
        .focusable()
        .digitalCrownRotation(
            $selectedPercent,
            from: 0,
            through: 100,
            by: 1,
            sensitivity: .low,
            isContinuous: false,
            isHapticFeedbackEnabled: true
        )
        .navigationBarTitle(sample != nil ? "Edit Flow" : "Track Flow")
    }
    
    private var hadFlowRow: some View {
        HStack {
            Text("Had Flow", comment: "Label for had flow selector")
            Spacer()
            Image(self.viewModel.selection == .hadFlow ? "Checked-Circle" : "Unchecked-Circle")
            .resizable()
            .frame(width: 20.0, height: 20.0)
            .foregroundColor(Color.white)
            .onTapGesture {
                self.viewModel.selection = self.viewModel.selection == .hadFlow ? .none : .hadFlow
                if self.viewModel.selection == .none {
                    self.selectedPercent = 0 // reset value
                }
            }
        }
    }

    private var noFlowRow: some View {
        HStack {
            Text("No Flow", comment: "Label for no flow selector")
            Spacer()
            Image(self.viewModel.selection == .noFlow ? "Checked-Circle" : "Unchecked-Circle")
            .resizable()
            .frame(width: 20.0, height: 20.0)
            .foregroundColor(Color.white)
            .onTapGesture {
                self.viewModel.selection = self.viewModel.selection == .noFlow ? .none : .noFlow
                self.selectedPercent = 0 // reset value
            }
        }
    }

    private var flowPickerRow: some View {
        VStack(alignment: .leading) {
            Text("24-Hour Flow")
            HStack {
                decrementButton
                Spacer()
                Text(String(describing: Int(selectedPercent)))
                Text(viewModel.volumeUnit.shortUnit)
                Spacer()
                incrementButton
            }
        }
    }
    
    private var decrementButton: some View {
        Button(action: {
            if selectedPercent > 5 {
                selectedPercent -= 5
            } else {
                selectedPercent = 0
            }
            WKInterfaceDevice.current().play(.directionDown)
        }, label: {
            Text(verbatim: "−")
                .font(.system(.body, design: .rounded))
                .bold()
        })
        .buttonStyle(CircularAccessoryButtonStyle(color: .white))
        .transition(.opacity)
    }
    
    private var incrementButton: some View {
        Button(action: {
            selectedPercent += 5
            WKInterfaceDevice.current().play(.directionUp)
        }, label: {
            Text(verbatim: "+")
                .font(.system(.body, design: .rounded))
                .bold()
        })
        .buttonStyle(CircularAccessoryButtonStyle(color: .white))
        .transition(.opacity)
    }

    private func percentToVolume(_ percent: Int) -> Int {
        return Int(Double(percent) / Double(100) * Double(viewModel.cupType.maxVolume))
    }

    private func volumeToPercent(_ volume: Int) -> Int {
        return Int(Double(volume) / Double(viewModel.cupType.maxVolume) * 100)
    }
    
    private func saveEvent() {
        let newVolume = percentToVolume(Int(selectedPercent))
        self.viewModel.save(sample: self.sample, date: self.date, newVolume: newVolume) { success in
            if success {
                print("Sent menstrual event")
            } else {
                // TODO: show error
                print("Could not send menstrual event")
            }
        }
    }
}
