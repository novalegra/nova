//
//  WatchDataManager.swift
//  NovaWatch Extension
//
//  Created by Anna Quinlan on 10/7/20.
//  Copyright © 2020 Anna Quinlan. All rights reserved.
//

import Foundation
import SwiftUI

class MenstrualDataManager: ObservableObject {
    let store: MenstrualStore
    // Allowable gap (in days) between samples so it's still considered a period
    let allowablePeriodGap: Int = 1
    @Published var selection: SelectionState = .none
    @Published var periods: [MenstrualPeriod] = []
}
