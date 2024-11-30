//
//  Cacheable.swift
//  SoongBook
//
//  Created by 이숭인 on 11/27/24.
//

import Foundation

public protocol Cacheable: Hashable, Codable {
    var expiration: CacheStorageExpiration { get }
}
