//
//  MemoryStorage+Config.swift
//  SoongBook
//
//  Created by 이숭인 on 11/27/24.
//

import Foundation

extension MemoryStorage {
    public struct Config {
        public var totalCostLimit: Int
        public var countLimit: Int = .max
        public var cleanInterval: TimeInterval
        public var expiration: CacheStorageExpiration
        
        public init(
            totalCostLimit: Int,
            cleanInterval: TimeInterval = 60 * 3,
            expiration: CacheStorageExpiration = .seconds(300)
        ) {
            self.totalCostLimit = totalCostLimit
            self.cleanInterval = cleanInterval
            self.expiration = expiration
        }
    }
}
