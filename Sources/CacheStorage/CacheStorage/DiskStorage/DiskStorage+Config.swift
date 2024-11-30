//
//  DiskStorage+Config.swift
//  SoongBook
//
//  Created by 이숭인 on 11/27/24.
//

import Foundation

extension DiskStorage {
    public struct Config {
        public var cleanInterval: TimeInterval
        public var expiration: CacheStorageExpiration
        
        public init(
            cleanInterval: TimeInterval = 300,
            expiration: CacheStorageExpiration = .days(7)
        ) {
            self.cleanInterval = cleanInterval
            self.expiration = expiration
        }
    }
}

