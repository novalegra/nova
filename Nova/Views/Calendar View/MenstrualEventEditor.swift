//
//  MenstrualEventEditor.swift
//  Nova
//
//  Created by Anna Quinlan on 9/7/20.
//  Copyright © 2020 Anna Quinlan. All rights reserved.
//

import SwiftUI
import HealthKit


struct MenstrualEventEditor: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @ObservedObject var viewModel: MenstrualDataManager
    @State var selection: SelectionState = .none
    let sample: MenstrualSample?
    let date: Date

    @State var selectedIndex = 0
    @State var showingAuthorizationAlert = false
    
    init(viewModel: MenstrualDataManager, sample: MenstrualSample?, date: Date) {
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
            flowPickerRow
        }
            .listStyle(InsetGroupedListStyle())
            .onAppear {
                if let sample = sample {
                    selection = sample.flowLevel == .none ? .noFlow : .hadFlow
                } else {
                    selection = .none
                }
            }
            .navigationBarTitle(sample != nil ? "Edit Flow" : "Track Flow", displayMode: .inline)
            .navigationBarItems(trailing: saveButton)
            .alert(isPresented: $showingAuthorizationAlert, content: alert)
    }
    
    var saveButton: some View {
        Button(sample != nil ? "Update" : "Save") {
            let selectedValue = viewModel.flowPickerNumbers[selectedIndex]
            let newVolume = viewModel.volumeUnit == .percentOfCup ? percentToVolume(selectedValue) : selectedValue
            
            viewModel.save(sample: sample, date: date, newVolume: newVolume, flowSelection: selection) { result in
                switch result {
                case .success:
                    DispatchQueue.main.async {
                        presentationMode.wrappedValue.dismiss()
                    }
                case .failure(let error):
                    NSLog("Error when saving: \(error)")
                    showingAuthorizationAlert = true
                }
            }
        }
    }
    
    var hadFlowRow: some View {
        HStack {
            Text("Had Flow", comment: "Label for had flow selector")
            Spacer()
            Image(selection == .hadFlow ? "Checked-Circle" : "Unchecked-Circle")
            .resizable()
            .frame(width: 20.0, height: 20.0)
            .onTapGesture {
                selection = selection == .hadFlow ? .none : .hadFlow
                if selection == .none {
                    selectedIndex = 0 // reset value
                }
            }
        }
    }
    
    var noFlowRow: some View {
        HStack {
            Text("No Flow", comment: "Label for no flow selector")
            Spacer()
            Image(selection == .noFlow ? "Checked-Circle" : "Unchecked-Circle")
            .resizable()
            .frame(width: 20.0, height: 20.0)
            .onTapGesture {
                selection = selection == .noFlow ? .none : .noFlow
                selectedIndex = 0 // reset value
            }
        }
    }
    
    var flowPickerRow: some View {
        let sampleVolume = sample?.volume ?? 0
        let pickerValue = viewModel.volumeUnit == .percentOfCup ? volumeToPercent(sampleVolume) : sampleVolume
        let pickerStart = viewModel.closestNumberOnPicker(num: pickerValue)
        
        return FlowPicker(
            selectionState: $selection,
            with: viewModel.flowPickerOptions,
            onUpdate: { index in
                selectedIndex = index
            },
            label: NSLocalizedString("24-Hour Flow", comment: "Menstrual flow picker label"),
            unit: viewModel.volumeUnit.shortUnit,
            initialPickerIndex: viewModel.flowPickerOptions.firstIndex(of: String(Int(pickerStart))) ?? 0
        )
    }
    
    private func percentToVolume(_ percent: Double) -> Double {
        return percent / 100 * viewModel.cupType.maxVolume
    }
    
    private func volumeToPercent(_ volume: Double) -> Double {
        return volume / viewModel.cupType.maxVolume * 100
    }
    
    private func alert() -> SwiftUI.Alert {
        SwiftUI.Alert(
            title: Text("HealthKit Not Authorized", comment: "Alert title for un-authorized HealthKit"),
            // For the message, preMeal and workout are the same
            message: Text("Allow Nova to save samples by enabling access to menstration data in Health -> Profile -> Apps."),
            primaryButton: .default(Text("OK")),
            secondaryButton: .cancel(
                Text("Go to Health"),
                action: gotoSettings
            )
        )
    }
    
    private func gotoSettings() {
        UIApplication.shared.open(URL(string: "x-apple-health://")!)
    }
}
