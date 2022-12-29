//
//  RoundedBorder.swift
//  Nova
//
//  Created by Anna Quinlan on 12/28/22.
//  Copyright © 2022 Anna Quinlan. All rights reserved.
//

import SwiftUI

struct RoundedBorder: ViewModifier {
    var color: Color
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: ViewConstants.cornerRadius)
                    .stroke(color)
            )
    }
}

extension View {
    func roundedBorder(color: Color = .black) -> some View {
        return modifier(RoundedBorder(color: color))
    }
}
