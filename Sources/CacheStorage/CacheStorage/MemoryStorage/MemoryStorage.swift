//
//  MemoryStorage.swift
//  SoongBook
//
//  Created by 이숭인 on 11/27/24.
//

import Foundation
import Combine

public final class MemoryStorage<Key: Hashable, Object: Cacheable> {
    private let storage = NSCache<NSCacheKey<Key>, NSCacheObject<Object>>()
    private let serialQueue = DispatchQueue(label: "com.memoryStorage.serialQueue")
    
    public var config: Config {
        didSet {
            storage.totalCostLimit = config.totalCostLimit
            storage.countLimit = config.countLimit
        }
    }
    private var cleanTimer: Timer? = nil
    private var cacheKeys = Set<NSCacheKey<Key>>()
    
    public init(config: Config) {
        self.config = config
        
        cleanTimer = .scheduledTimer(
            withTimeInterval: config.cleanInterval,
            repeats: true
        ) { [weak self] _ in
            guard let self = self else { return }
            self.removeExpired()
        }
    }
    
    /// Create / Update
    public func saveValue(
        with value: Object,
        key: NSCacheKey<Key>,
        expiration: CacheStorageExpiration? = nil
    ) {
        serialQueue.async { [weak self] in
            guard let self else { return }
            
            let expiration = expiration ?? config.expiration
            guard !expiration.isExpired else { return }
            
            let object = NSCacheObject(value, expiration: expiration)
            
            cacheKeys.insert(key)
            storage.setObject(object, forKey: key)
        }
    }
    
    /// Read
    public func retrieveValue(
        forKey key: NSCacheKey<Key>
    ) -> Object? {
        serialQueue.sync { [weak self] in
            guard let self else { return nil }
            
            guard let object = storage.object(forKey: key) else {
                return nil
            }
            
            if object.isExpired {
                return nil
            }
            
            return object.value
        }
    }
    
    /// Delete
    public func remove(forKey key: NSCacheKey<Key>) {
        serialQueue.async { [weak self] in
            guard let self else { return }
            
            cacheKeys.remove(key)
            storage.removeObject(forKey: key)
        }
    }
    
    /// Delete All
    public func removeAll() {
        serialQueue.async { [weak self] in
            guard let self else { return }
            
            cacheKeys.removeAll()
            storage.removeAllObjects()
        }
    }
    
    /// Auto Delete
    public func removeExpired() {
        serialQueue.async { [weak self] in
            guard let self else { return }
            
            for key in cacheKeys {
                guard let object = storage.object(forKey: key) else {
                    cacheKeys.remove(key)
                    continue // 다음 key check를 위함
                }
                
                if object.isExpired {
                    storage.removeObject(forKey: key)
                    cacheKeys.remove(key)
                }
            }
        }
    }
    
    public func isCached(forKey key: NSCacheKey<Key>) -> Bool {
        return retrieveValue(forKey: key).isNotNil
    }
}
