//
//  CacheStorageExpiration.swift
//  SoongBook
//
//  Created by 이숭인 on 11/27/24.
//

import Foundation

public enum CacheStorageExpiration: Codable {
    case never
    case seconds(TimeInterval)
    case days(Int)
    case date(Date)
    case expired
    
    var isExpired: Bool {
        switch self {
        case .never:
            return false
        case .seconds(let interval):
            return false
        case .days(let days):
            return TimeInterval(24 * 60 * 60 * days) <= 0
        case .date(let expirationDate):
            return Date() > expirationDate
        case .expired:
            return true
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case type
        case value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "never":
            self = .never
        case "seconds":
            let value = try container.decode(TimeInterval.self, forKey: .value)
            self = .seconds(value)
        case "days":
            let value = try container.decode(Int.self, forKey: .value)
            self = .days(value)
        case "date":
            let value = try container.decode(Date.self, forKey: .value)
            self = .date(value)
        case "expired":
            self = .expired
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown expiration type")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .never:
            try container.encode("never", forKey: .type)
        case .seconds(let value):
            try container.encode("seconds", forKey: .type)
            try container.encode(value, forKey: .value)
        case .days(let value):
            try container.encode("days", forKey: .type)
            try container.encode(value, forKey: .value)
        case .date(let value):
            try container.encode("date", forKey: .type)
            try container.encode(value, forKey: .value)
        case .expired:
            try container.encode("expired", forKey: .type)
        }
    }
}
