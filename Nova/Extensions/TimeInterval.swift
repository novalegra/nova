//
//  TimeInterval.swift
//  Nova
//
//  Created by Anna Quinlan on 10/3/22.
//  Copyright © 2022 Anna Quinlan. All rights reserved.
//

import Foundation

extension TimeInterval {
    init(hours: Double) {
        self.init(hours * 60 * 60)
    }
    
    init(days: Double) {
        self.init(hours: days * 24)
    }
}
