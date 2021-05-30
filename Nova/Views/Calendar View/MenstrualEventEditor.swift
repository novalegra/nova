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
        #if swift(>=5.2)
            if #available(iOS 14.0, *) {
                mainBody
                .listStyle(InsetGroupedListStyle())
            } else {
                mainBody
                    .listStyle(GroupedListStyle())
                    .environment(\.horizontalSizeClass, .regular)
            }
        #else
            mainBody
            .listStyle(GroupedListStyle())
            .environment(\.horizontalSizeClass, .regular)
        #endif
    }
    
    var mainBody: some View {
        List {
            Section {
                hadFlowRow
                noFlowRow
            }
            flowPickerRow
        }
        .onAppear {
            if let sample = self.sample {
                self.selection = sample.flowLevel == .none ? .noFlow : .hadFlow
            } else {
                self.selection = .none
            }
        }
        .navigationBarTitle(sample != nil ? "Edit Flow" : "Track Flow", displayMode: .inline)
        .navigationBarItems(trailing: saveButton)
        .alert(isPresented: $showingAuthorizationAlert, content: alert)
    }
    
    var saveButton: some View {
        Button(sample != nil ? "Update" : "Save") {
            let selectedValue = self.viewModel.flowPickerNumbers[self.selectedIndex]
            let newVolume = self.viewModel.volumeUnit == .percentOfCup ? self.percentToVolume(selectedValue) : selectedValue
            self.viewModel.save(sample: self.sample, date: self.date, newVolume: newVolume, flowSelection: selection) { result in
                switch result {
                case .success:
                    DispatchQueue.main.async {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                case .failure(let error):
                    NSLog("Error when saving", error)
                    self.showingAuthorizationAlert = true
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
                self.selection = self.selection == .hadFlow ? .none : .hadFlow
                if self.selection == .none {
                    self.selectedIndex = 0 // reset value
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
                self.selection = self.selection == .noFlow ? .none : .noFlow
                self.selectedIndex = 0 // reset value
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
                self.selectedIndex = index
            },
            label: NSLocalizedString("24-Hour Flow", comment: "Menstrual flow picker label"),
            unit: viewModel.volumeUnit.shortUnit,
            initialPickerIndex: self.viewModel.flowPickerOptions.firstIndex(of: String(pickerStart)) ?? 0
        )
    }
    
    private func percentToVolume(_ percent: Int) -> Int {
        return Int(Double(percent) / Double(100) * Double(viewModel.cupType.maxVolume))
    }
    
    private func volumeToPercent(_ volume: Int) -> Int {
        return Int(Double(volume) / Double(viewModel.cupType.maxVolume) * 100)
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
