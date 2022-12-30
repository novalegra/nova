//
//  SettingsView.swift
//  Nova
//
//  Created by Anna Quinlan on 9/16/20.
//  Copyright © 2020 Anna Quinlan. All rights reserved.
//

import SwiftUI

enum VolumeType: String, Equatable, CaseIterable {
    case mL = "Milliliters"
    case percentOfCup = "Percent of Cup Size"
    
    var shortUnit: String {
        switch self {
        case .mL:
            return "mL"
        case .percentOfCup:
            return "% of cup"
        }
    }
}

struct SettingsView: View {
    @ObservedObject var viewModel: MenstrualDataManager
    @State private var selectedVolumeType: VolumeType = .percentOfCup
    @State private var selectedMenstrualCupType: MenstrualCupType = .lenaSmall
    @State private var notificationsEnabled = false
    @State private var customCupVolume = Constants.defaultCustomCupVolume

    var body: some View {
        NavigationView {
            List {
                Section("Menstrual Cup Type") {
                    cupPickerSection
                }
                .headerProminence(.increased)
                
                Section("Notifications") {
                    notificationsPicker
                }
                .headerProminence(.increased)
                
            }
            .listStyle(InsetGroupedListStyle())
            .navigationBarTitle("Settings", displayMode: .large)
            .onAppear {
                // FIXME: removed due to iOS 14 bug
                selectedMenstrualCupType = viewModel.cupType
                selectedVolumeType = .percentOfCup//viewModel.volumeUnit
                notificationsEnabled = viewModel.notificationsEnabled
                customCupVolume = viewModel.customCupVolume
            }
            .onDisappear {
                saveSettingsToDataManager()
            }
            .scrollDismissesKeyboard(.immediately) // TODO: file radar for this having buggy animations
        }
    }
    
    var volumeTypeSection: some View {
        VStack(alignment: .leading) {
            Text("Volume Entry Unit", comment: "Label for volume picker setting")
            Picker(selection: $selectedVolumeType, label: Text("")) {
                ForEach(VolumeType.allCases, id: \.self) { value in
                    Text(value.rawValue)
                    .tag(value)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding(.vertical, Constants.smallPadding)
    }
    
    private var cupPickerSection: some View {
        Section {
            VStack(alignment: .leading) {
                menstrualCupPicker
                if selectedMenstrualCupType == .other {
                    otherCupTypeVolumeField
                }
            }
            .padding(.vertical, Constants.smallPadding)
        }
    }
    
    private var menstrualCupPicker: some View {
        Picker(selection: $selectedMenstrualCupType, label: Text("")) {
            ForEach(MenstrualCupType.allCases, id: \.self) { value in
                Text(value.rawValue)
                .tag(value)
            }
        }
        .pickerStyle(WheelPickerStyle())
        // Hack to center the picker in the screen
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
    }
    
    private var otherCupTypeVolumeField: some View {
        HStack {
            Text("Cup Volume:")
            Spacer()
            HStack(alignment: .firstTextBaseline) {
                TextField("Volume Entry", value: $customCupVolume, format: .number, prompt: Text("25"))
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.done)
                Text("mL")
            }
        }
    }
    
    private var notificationsPicker: some View {
        Toggle(isOn: $notificationsEnabled) {
            Text("Cup Empty Reminders", comment: "Title text for cup empty notifications")
        }
            .onChange(of: notificationsEnabled) { enabled in
                guard enabled else {
                    return
                }
                
                NotificationManager.ensureAuthorization()
            }
    }
    
    private func saveSettingsToDataManager() {
        viewModel.volumeUnit = selectedVolumeType
        viewModel.cupType = selectedMenstrualCupType
        viewModel.notificationsEnabled = notificationsEnabled
        viewModel.customCupVolume = customCupVolume
    }
}
