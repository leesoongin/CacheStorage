//
//  NSCacheObject.swift
//  SoongBook
//
//  Created by 이숭인 on 11/27/24.
//

import Foundation

public final class NSCacheObject<T: Cacheable>: NSObject, Codable {
    public var value: T?
    public let expiration: CacheStorageExpiration
    
    private let addedDate: Date
    
    public init(_ value: T, expiration: CacheStorageExpiration) {
        self.value = value
        self.expiration = expiration
        self.addedDate = Date()
    }
    
    public var isExpired: Bool {
        switch expiration {
        case .never:
            return false
        case .seconds(let interval):
            return Date().timeIntervalSince(addedDate) > interval
        case .days(let days):
            let expirationDate = addedDate.addingTimeInterval(TimeInterval(days * 24 * 60 * 60))
            return Date() > expirationDate
        case .date(let expirationDate):
            return Date() > expirationDate
        case .expired:
            return true
        }
    }
    
    // MARK: - Codable
    private enum CodingKeys: String, CodingKey {
        case value
        case expiration
        case addedDate
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        value = try container.decodeIfPresent(T.self, forKey: .value)
        expiration = try container.decode(CacheStorageExpiration.self, forKey: .expiration)
        addedDate = try container.decode(Date.self, forKey: .addedDate)
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(value, forKey: .value)
        try container.encode(expiration, forKey: .expiration)
        try container.encode(addedDate, forKey: .addedDate)
    }
}
