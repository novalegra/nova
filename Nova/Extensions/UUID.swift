//
//  UUID.swift
//  Nova
//
//  Created by Anna Quinlan on 10/25/22.
//  Copyright © 2022 Anna Quinlan. All rights reserved.
//

import Foundation

extension UUID: RawRepresentable {
    public typealias RawValue = String

    public init?(rawValue: String) {
        guard let id = UUID(uuidString: rawValue) else {
            return nil
        }
        self = id
    }

    public var rawValue: String {
        return self.uuidString
    }
}
