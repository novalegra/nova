//
//  MenstrualEventEditor.swift
//  Nova
//
//  Created by Anna Quinlan on 9/7/20.
//  Copyright © 2020 Anna Quinlan. All rights reserved.
//

import SwiftUI

enum SelectionState {
    case hadFlow
    case noFlow
    case none
}

struct MenstrualEventEditor: View {
    let sample: MenstrualSample?
    @State var selection: SelectionState = .none
    
    let flowPickerOptions = (0...45).map { String($0) }
    @State var selectedIndex = 0 // TODO: update this if needed
    
    init(sample: MenstrualSample?) {
        self.sample = sample
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
            self.selection = self.sample != nil ? .hadFlow : .none
        }
        .navigationBarTitle(sample != nil ? "Edit Flow" : "Track Flow", displayMode: .inline)
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
            with: flowPickerOptions,
            onUpdate: { index in
                self.selectedIndex = index
            },
            label: NSLocalizedString("Menstrual Flow", comment: "Menstrual flow picker label"),
            unit: NSLocalizedString("mL", comment: "Milliliter unit label"),
            initialPickerIndex: 0 // TODO: make this be based on the sample
        )
    }
}
