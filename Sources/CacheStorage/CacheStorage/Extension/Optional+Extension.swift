//
//  File.swift
//  
//
//  Created by 이숭인 on 11/30/24.
//

import Foundation

extension Optional {
    public var isNil: Bool {
        switch self {
        case .some:
            return false
        case .none:
            return true
        }
    }

    public var isNotNil: Bool {
        !isNil
    }
}
