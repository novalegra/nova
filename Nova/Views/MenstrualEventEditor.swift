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
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @ObservedObject var viewModel: MenstrualCalendarViewModel
    let sample: MenstrualSample?
    let date: Date

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
            if let sample = self.sample {
                self.viewModel.selection = sample.flowLevel == .none ? .noFlow : .hadFlow
            } else {
                self.viewModel.selection = .none
            }
        }
        .navigationBarTitle(sample != nil ? "Edit Flow" : "Track Flow", displayMode: .inline)
        .navigationBarItems(trailing: saveButton)
    }
    
    var saveButton: some View {
        Button(sample != nil ? "Update" : "Save") {
            self.viewModel.save(sample: self.sample, date: self.date, selectedIndex: self.selectedIndex)
            self.presentationMode.wrappedValue.dismiss()
        }
    }
    
    var hadFlowRow: some View {
        HStack {
            Text("Had Flow", comment: "Label for had flow selector")
            Spacer()
            Image(self.viewModel.selection == .hadFlow ? "Checked-Circle" : "Unchecked-Circle")
            .resizable()
            .frame(width: 20.0, height: 20.0)
            .onTapGesture {
                self.viewModel.selection = self.viewModel.selection == .hadFlow ? .none : .hadFlow
            }
        }
    }
    
    var noFlowRow: some View {
        HStack {
            Text("No Flow", comment: "Label for no flow selector")
            Spacer()
            Image(self.viewModel.selection == .noFlow ? "Checked-Circle" : "Unchecked-Circle")
            .resizable()
            .frame(width: 20.0, height: 20.0)
            .onTapGesture {
                self.viewModel.selection = self.viewModel.selection == .noFlow ? .none : .noFlow
            }
        }
    }
    
    var flowPickerRow: some View {
        FlowPicker(
            viewModel: viewModel,
            with: viewModel.flowPickerOptions,
            onUpdate: { index in
                self.selectedIndex = index
            },
            label: NSLocalizedString("24-Hour Menstrual Flow", comment: "Menstrual flow picker label"),
            unit: NSLocalizedString("mL", comment: "Milliliter unit label"),
            initialPickerIndex: self.viewModel.flowPickerOptions.firstIndex(of: String(sample?.volume ?? 0)) ?? 0
        )
    }
}
