//
//  DiskStorage.swift
//  SoongBook
//
//  Created by 이숭인 on 11/27/24.
//

import Foundation

public final class DiskStorage<Key: Hashable, Object: Cacheable> {
    private let serialQueue = DispatchQueue(label: "com.diskStorage.serialQueue")
    
    private let fileManager: FileManager
    private let cacheDirectoryURL: URL
    
    public var config: Config {
        didSet {
            // 디스크 캐시 설정이 변경될 때 필요한 처리
        }
    }
    
    private var cleanTimer: Timer? = nil
    
    public init(config: Config) {
        self.config = config
        self.fileManager = FileManager.default
        
        // 캐시 디렉토리 URL 정의
        self.cacheDirectoryURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        
        // 주기적인 캐시 정리를 위한 타이머
        cleanTimer = .scheduledTimer(
            withTimeInterval: config.cleanInterval,
            repeats: true
        ) { [weak self] _ in
            guard let self = self else { return }
            self.removeExpired()
        }
        
        createCacheDirectoryIfNeeded()
    }
    
    /// 디스크에 값을 저장
    public func saveValue(
        with value: Object,
        key: NSCacheKey<Key>,
        expiration: CacheStorageExpiration? = nil,
        completionHandler: @escaping (Result<Void, StorageError>) -> Void
    ) {
        serialQueue.async { [weak self] in
            guard let self else { return }
            
            let expiration = expiration ?? config.expiration
            
            guard !expiration.isExpired else { return }
            
            let object = NSCacheObject(value, expiration: expiration)
            
            // 캐시 항목에 대한 파일 경로 생성
            let filePath = cacheFilePath(forKey: key)
            
            do {
                let data = try encodeObject(with: object)
                try writeData(with: data, to: filePath)
                completionHandler(.success(Void()))
            } catch {
                if let error = error as? StorageError {
                    completionHandler(.failure(error))
                } else {
                    completionHandler(.failure(StorageError.unknown))
                }
            }
        }
    }
    
    /// 디스크에서 값을 읽어오기
    public func retrieveValue(forKey key: NSCacheKey<Key>) throws -> Object? {
        try serialQueue.sync { [weak self] in
            guard let self else { return nil }
            
            let filePath = cacheFilePath(forKey: key)
            let data = try loadData(from: filePath)
            let object = try decodeObject(with: data)
            
            return object.isExpired ? nil : object.value
        }
    }
    
    /// 디스크에서 값을 삭제
    public func remove(
        forKey key: NSCacheKey<Key>,
        completionHandler: @escaping (Result<Void, StorageError>) -> Void
    ) {
        serialQueue.async { [weak self] in
            guard let self else { return }
            
            let filePath = cacheFilePath(forKey: key)
            
            do {
                try fileManager.removeItem(at: filePath)
            } catch {
                completionHandler(.failure(.diskRemoveFailure))
            }
        }
    }
    
    /// 디스크에서 모든 캐시 항목 삭제
    public func removeAll(
        completionHandler: @escaping (Result<Void, StorageError>) -> Void
    ) {
        serialQueue.async { [weak self] in
            guard let self else { return }
            
            guard let enumerator = fileManager.enumerator(at: cacheDirectoryURL, includingPropertiesForKeys: nil) else {
                return
            }
            
            do {
                for case let fileURL as URL in enumerator {
                    try fileManager.removeItem(at: fileURL)
                }
            } catch {
                completionHandler(.failure(StorageError.diskRemoveFailure))
            }
        }
    }
    
    /// 만료된 캐시 항목 자동 삭제
    public func removeExpired() {
        guard let enumerator = fileManager.enumerator(at: cacheDirectoryURL, includingPropertiesForKeys: nil) else {
            return
        }
        
        for case let fileURL as URL in enumerator {
            guard let data = try? Data(contentsOf: fileURL),
                  let object = try? JSONDecoder().decode(NSCacheObject<Object>.self, from: data),
                  object.isExpired else {
                      continue
                  }
            
            try? fileManager.removeItem(at: fileURL)
        }
    }
    
    public func isCached(forKey key: NSCacheKey<Key>) -> Bool {
        guard (try? retrieveValue(forKey: key)).isNotNil else {
            return false
        }
        
        return true
    }
    
    private func createCacheDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: cacheDirectoryURL.path) {
            try? fileManager.createDirectory(at: cacheDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    private func cacheFilePath(forKey key: NSCacheKey<Key>) -> URL {
        let keyString = String(describing: key.value)
        let fileName = keyString.replacingOccurrences(of: "/", with: "-") // 파일명으로 사용할 수 있도록 변환
        return cacheDirectoryURL.appendingPathComponent(fileName)
    }
    
    
    private func writeData(with data: Data, to filePath: URL) throws {
        do {
            try data.write(to: filePath)
        } catch {
            throw StorageError.diskWriteFailure
        }
    }
    
    private func loadData(from filePath: URL) throws -> Data {
        do {
            let data = try Data(contentsOf: filePath)
            return data
        } catch {
            throw StorageError.notFound
        }
    }
}

//MARK: - Encode, Decode
extension DiskStorage {
    private func encodeObject(with object: Encodable) throws -> Data {
        do {
            return try JSONEncoder().encode(object)
        } catch {
            throw StorageError.encodingFailed
        }
    }
    
    private func decodeObject(with data: Data) throws -> NSCacheObject<Object> {
        do {
            return try JSONDecoder().decode(NSCacheObject<Object>.self, from: data)
        } catch {
            throw StorageError.decodingFailed
        }
    }
}
