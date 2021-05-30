//
//  SelectionState.swift
//  Nova
//
//  Created by Anna Quinlan on 10/14/20.
//  Copyright © 2020 Anna Quinlan. All rights reserved.
//

enum SelectionState: Int {
    case hadFlow
    case noFlow
    case none
}

extension SelectionState: RawRepresentable {
    init?(rawValue: Int) {
        switch rawValue {
        case 0: self = .hadFlow
        case 1: self = .noFlow
        case 2: self = .none
        default:
            fatalError("Invalid raw value for SelectionState")
        }
    }

    var rawValue: Int {
        switch self {
        case .hadFlow:
            return 0
        case .noFlow:
            return 1
        case .none:
            return 2
        }
    }
}
