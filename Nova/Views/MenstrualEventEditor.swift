//
//  MenstrualEventEditor.swift
//  Nova
//
//  Created by Anna Quinlan on 9/7/20.
//  Copyright © 2020 Anna Quinlan. All rights reserved.
//

import SwiftUI
import HealthKit

enum SelectionState {
    case hadFlow
    case noFlow
    case none
}

struct MenstrualEventEditor: View {
    @ObservedObject var viewModel: MenstrualCalendarViewModel
    let sample: MenstrualSample?
    let date: Date
    @State var selection: SelectionState = .none

    @State var selectedIndex = 0
    
    init(viewModel: MenstrualCalendarViewModel, sample: MenstrualSample?, date: Date) {
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
        .listStyle(GroupedListStyle())
        .environment(\.horizontalSizeClass, .regular)
        .onAppear {
            if self.sample != nil {
                self.selection = .hadFlow
            }
        }
        .navigationBarTitle(sample != nil ? "Edit Flow" : "Track Flow", displayMode: .inline)
        .navigationBarItems(trailing: saveButton)
    }
    
    var saveButton: some View {
        Button("Save") {
            let volume = Int(self.viewModel.flowPickerOptions[self.selectedIndex])
            if let sample = self.sample {
                sample.volume = volume
                self.viewModel.updateSample(sample)
            } else {
                let flowLevel = HKCategoryValueMenstrualFlow.unspecified
                let sample = MenstrualSample(startDate: self.date, endDate: self.date, flowLevel: flowLevel, volume: volume)
                self.viewModel.saveSample(sample)
            }
        }
    }
    
    var hadFlowRow: some View {
        HStack {
            Text("Had Flow", comment: "Label for had flow selector")
            Spacer()
            Image(systemName: self.selection == .hadFlow ? "checkmark.square" : "square")
            .resizable()
            .frame(width: 20.0, height: 20.0)
            .onTapGesture {
                self.selection = self.selection == .hadFlow ? .none : .hadFlow
            }
        }
    }
    
    var noFlowRow: some View {
        HStack {
            Text("No Flow", comment: "Label for no flow selector")
            Spacer()
            Image(systemName: self.selection == .noFlow ? "checkmark.square" : "square")
            .resizable()
            .frame(width: 20.0, height: 20.0)
            .onTapGesture {
                self.selection = self.selection == .noFlow ? .none : .noFlow
            }
        }
    }
    
    var flowPickerRow: some View {
        ExpandablePicker(
            with: viewModel.flowPickerOptions,
            onUpdate: { index in
                self.selectedIndex = index
            },
            label: NSLocalizedString("Menstrual Flow", comment: "Menstrual flow picker label"),
            unit: NSLocalizedString("mL", comment: "Milliliter unit label"),
            initialPickerIndex: self.viewModel.flowPickerOptions.firstIndex(of: String(sample?.volume ?? 0)) ?? 0
        )
    }
}
