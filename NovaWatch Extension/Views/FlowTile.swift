//
//  FlowTile.swift
//  NovaWatch Extension
//
//  Created by Anna Quinlan on 5/30/21.
//  Copyright © 2021 Anna Quinlan. All rights reserved.
//

import SwiftUI

struct FlowTile: View {
    let date: Date
    let dateFormatter = DateFormatter()
    @ObservedObject var dataManager: WatchDataManager
    
    init(date: Date, dataManager: WatchDataManager) {
        self.date = date
        self.dataManager = dataManager
    }
    
    func formattedDate(for date: Date) -> String {
        dateFormatter.dateFormat = "EEE, MMM dd"
        return dateFormatter.string(from: date)
    }
    
    var body: some View {
        LazyHStack {
            Circle()
            .fill(buttonColor(for: date))
            .frame(width: 20, height: 20)
            .overlay(
               Circle()
              .stroke(Color.black, lineWidth: 1)
             )
            Spacer(minLength: 10)
            Text(formattedDate(for: date))
            .foregroundColor(Color.black)
        }
    }
    
    private func buttonColor(for date: Date) -> Color {
        if date > Date() {
            return Color(UIColor.gray.withAlphaComponent(0.14))
        }
        if dataManager.hasMenstrualFlow(at: date) {
            return Color("DarkPink")
        }
        return Color("LightBrown")
    }
}
