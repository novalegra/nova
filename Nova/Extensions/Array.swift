//
//  Array.swift
//  Nova
//
//  Created by Anna Quinlan on 11/3/22.
//  Copyright © 2022 Anna Quinlan. All rights reserved.
//

import Foundation

extension Collection where Self.Element == Double {
    func average() -> Double {
        /// Can't divide by 0
        guard self.count != 0 else {
            return 0
        }
        
        return self.reduce(0, { $0 + $1 }) / Double(self.count)
    }
}
