//
//  CacheStorage.swift
//  SoongBook
//
//  Created by 이숭인 on 11/27/24.
//

import Foundation
import Combine

@available(macOS 10.15, *)
public final class CacheStorage<Key: Hashable, Object: Cacheable> {
    public typealias ChangedCacheSet = (key: StorageChange<Key>, object: Object?)
    
    private let storageObserverSubject = PassthroughSubject<Result<ChangedCacheSet, StorageError>, Never>()
    
    public let memoryStorage: MemoryStorage<Key, Object>
    public let diskStorage: DiskStorage<Key, Object>
    
    public var storageObserver: AnyPublisher<Result<ChangedCacheSet, StorageError>, Never> {
        storageObserverSubject.eraseToAnyPublisher()
    }
    
    public init(
        memoryConfig: MemoryStorage<Key, Object>.Config,
        diskConfig: DiskStorage<Key, Object>.Config
    ) {
        memoryStorage = MemoryStorage<Key, Object>(config: memoryConfig)
        diskStorage = DiskStorage(config: diskConfig)
    }
    
    public func save(
        with value: Object,
        key: Key,
        expiration: CacheStorageExpiration? = nil
    ) {
        memoryStorage.saveValue(
            with: value,
            key: NSCacheKey(value: key),
            expiration: expiration
        )
        
        diskStorage.saveValue(
            with: value,
            key: NSCacheKey(value: key),
            expiration: expiration
        ) { [weak self] result in
            guard let self else{ return }
            
            switch result {
            case .success:
                let changeSet: ChangedCacheSet = (
                    key: .save(key: key),
                    object: value
                )
                
                storageObserverSubject.send(.success(changeSet))
            case .failure(let error):
                storageObserverSubject.send(.failure(error))
            }
        }
    }
    
    public func retrieve(forKey key: Key) throws -> Object? {
        let cacheKey = NSCacheKey(value: key)
        
        if let memoryCachedValue = memoryStorage.retrieveValue(forKey: cacheKey) {
            return memoryCachedValue
        }
        
        guard let diskCachedValue = try diskStorage.retrieveValue(forKey: cacheKey) else {
            return nil
        }
        
        memoryStorage.saveValue(with: diskCachedValue, key: cacheKey)
        return diskCachedValue
    }
    
    public func remove(forKey key: Key) throws {
        let cacheKey = NSCacheKey(value: key)
        
        let retrievedValue = try retrieve(forKey: key)
        
        memoryStorage.remove(forKey: cacheKey)
        diskStorage.remove(forKey: cacheKey) { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success:
                let changeSet: ChangedCacheSet = (
                    key: .remove(key: key),
                    object: retrievedValue
                )
                
                storageObserverSubject.send(.success(changeSet))
            case .failure(let error):
                storageObserverSubject.send(.failure(error))
            }
        }
    }
    
    public func removeAll() {
        memoryStorage.removeAll()
        diskStorage.removeAll() { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success:
                let changeSet: ChangedCacheSet = (
                    key: .removeAll,
                    object: nil
                )
                
                storageObserverSubject.send(.success(changeSet))
            case .failure(let error):
                storageObserverSubject.send(.failure(error))
            }
        }
    }
    
    public func isCached(forKey key: NSCacheKey<Key>) -> Bool {
        return memoryStorage.isCached(forKey: key) || diskStorage.isCached(forKey: key)
    }
}
