//
//  FlowPicker.swift
//  Nova
//
//  Created by Anna Quinlan on 9/7/20.
//  Copyright © 2020 Anna Quinlan. All rights reserved.
//

import SwiftUI
import Combine

struct FlowPicker: View {
    @Binding var selectionState: SelectionState
    @State var pickerShouldExpand = true
    @State var pickerIndex: Int = 0 // initializing with zero so it doesn't error
    let initialPickerIndex: Int
    var onUpdate: (Int) -> Void
    let label: String
    let unit: String
    
    let items: [String]
    
    init (
        selectionState: Binding<SelectionState>,
        with items: [String],
        onUpdate: @escaping (Int) -> Void,
        label: String = "",
        unit: String = "",
        initialPickerIndex: Int = 0
    ) {
        self._selectionState = selectionState
        self.items = items
        self.onUpdate = onUpdate
        self.label = label
        self.unit = unit
        self.initialPickerIndex = initialPickerIndex
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Text(label)
                Spacer()
                Text(items[pickerIndex] + " " + unit)                
            }
            .padding(.vertical, 5)
            .frame(minWidth: 0, maxWidth: .infinity).onTapGesture {
                self.pickerShouldExpand.toggle()
            }
            .onAppear {
                self.pickerIndex = self.initialPickerIndex
            }
            .onChange(of: selectionState) { _ in
                if selectionState != .hadFlow {
                    self.pickerIndex = 0
                    self.pickerShouldExpand = false
                }
            }
            if pickerShouldExpand && selectionState == .hadFlow {
                HStack(alignment: .center) {
                    Picker(selection: $pickerIndex.onChange(onUpdate), label: Text("")) {
                        ForEach(0 ..< items.count) {
                            Text(self.items[$0])
                       }
                    }
                    .pickerStyle(WheelPickerStyle())
                }
            }
        }
    }
}

extension Binding {
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        return Binding(
            get: { self.wrappedValue },
            set: { selection in
                self.wrappedValue = selection
                handler(selection)
        })
    }
}
