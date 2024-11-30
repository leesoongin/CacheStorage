//
//  CacheStorage+Observe.swift
//  SoongBook
//
//  Created by 이숭인 on 11/29/24.
//

import Foundation

public enum StorageChange<Key: Hashable>: Equatable {
    case save(key: Key)
    case remove(key: Key)
    case removeAll
}

