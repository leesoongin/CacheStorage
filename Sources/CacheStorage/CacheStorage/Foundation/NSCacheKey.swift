//
//  NSCacheKey.swift
//  SoongBook
//
//  Created by 이숭인 on 11/27/24.
//

import Foundation

public final class NSCacheKey<T: Hashable>: NSObject {
    public let value: T
    
    public init(value: T) {
        self.value = value
    }
}
