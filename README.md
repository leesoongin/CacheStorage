# CacheStorage

`CacheStorage`는 iOS에서 메모리(NSCache)와 디스크(FileManager)를 활용하여 데이터를 효과적으로 캐싱할 수 있는 소스코드입니다.
데이터를 저장, 조회, 삭제할 수 있으며, 캐싱 변경 사항을 Combine 퍼블리셔를 통해 실시간으로 구독할 수 있습니다.

---

## 📁 구성

### 주요 파일 및 클래스
- **CacheStorage.swift**: 메모리와 디스크 캐싱을 통합 관리하는 메인 클래스.
- **MemoryStorage**: `NSCache`를 사용한 메모리 캐싱 관리. 
- **DiskStorage**: `FileManager`를 사용한 디스크 캐싱 관리.
- **NSCacheKey.swift**: `Hashable` 프로토콜을 준수하여 `NSCache`에서 안전하게 키를 사용할 수 있도록 구현.
- **NSCacheObject.swift**: 캐시에서 객체를 안전하게 관리하기 위한 래퍼 클래스.

### ❗ 동시성 이슈 발생 및 해결 방안 ❗

- **문제점**:  
  하나의 `storage`에서 동시에 **Read** 및 **Write** 동작이 반복될 경우, 의도하지 않은 결과가 발생할 가능성이 존재합니다.

- **해결 방안**:  
  동시성 문제를 방지하기 위해, `memoryStorage`와 `diskStorage` 내부에서 각각의 **Save**, **Retrieve**, **Remove** 등의 동작이 **Serial Queue**에서 실행되도록 구현되었습니다. 이를 통해 동시성 문제가 발생하지 않도록 안전한 환경을 보장합니다.


---

## ⚙️ 동작 원리

### NSCacheKey 와 NSCacheObject

`CacheStorage`는 캐시 키를 `Hashable` 프로토콜을 준수하는 모든 객체로 사용할 수 있도록 설계되었습니다. 
`NSCache`는 기본적으로 `NSObject`를 키로 사용하는데, 이를 보완하기 위해 다음과 같은 래퍼 객체를 제공합니다:

- **`NSCacheKey`**:
  - 모든 `Hashable` 타입을 감싸 `NSObject`처럼 동작하도록 래핑.
  - `Hashable` 한 객체를 Key로 사용하기 위하여 정의. 다양한 형태의 Key 객체를 생성하여 사용할 수 있습니다.
```swift
public final class NSCacheKey<T: Hashable>: NSObject {
    public let value: T
    
    public init(value: T) {
        self.value = value
    }
}

```

- **`NSCacheObject`**:
  - `Cacheable` 프로토콜을 따르는 객체를 랩핑하여 저장되는 객체의 모델입니다.
  - 저장되는 객체의 `Expiration`, `addedDate` 정보를 가집니다.
   
```swift
//MARK: Cacheable
public protocol Cacheable: Hashable, Codable {
    var expiration: CacheStorageExpiration { get }
}

//MARK: NSCacheObject
public final class NSCacheObject<T: Cacheable>: NSObject, Codable {
    public var value: T?
    public let expiration: CacheStorageExpiration
    
    private let addedDate: Date
    
    public init(_ value: T, expiration: CacheStorageExpiration) {
        self.value = value
        self.expiration = expiration
        self.addedDate = Date()
    }
    
    // ...
}
```

---

## 🧑‍💻 사용 예제

### 1. Memory, Disk Configuration 정의 및 CacheStorage 객체 생성
- memory, disk configuration 을 정의할 때, Key로 사용될 타입과 저장될 Object의 타입을 지정해주어야 합니다.
```swift
// 1. Configuration 정의
let memoryConfig = MemoryStorage<String, SampleCacheableObject>.Config(totalCostLimit: 1024 * 10)
let diskConfig = DiskStorage<String, SampleCacheableObject>.Config()

// 2. CacheStorage 객체 생성
let cacheStorage = CacheStorage(
    memoryConfig: memoryConfig,
    diskConfig: diskConfig
)
```
### 2. Save, Retrieve , Remove, RemoveAll, StorageObserver
- **`cacheStorage`** 를 통해 `save`, `retrieve`, `remove`, `removeAll` 작업을 수행할 수 있습니다.
- **`cacheStorage`** 의 `storageObserver` 를 통해 이벤트 감지를 할 수 있습니다. `storageObserver` 는 이벤트를 Combine의 `AnyPublisher` 형태로 리턴합니다.
```swift
// Data Save
cacheStorage.save(with: beStoreObject, key: "string_key_1")

// Data Remove All
cacheStorage.removeAll()
        
// Data Retrieve
let retrievedValue = try? cacheStorage.retrieve(forKey: "string_key_1")

// Data Remove
try? cacheStorage.remove(forKey: "string_key_1")

// Observe Storage event
cacheStorage.storageObserver
    .sink { result in
        switch result {
        case .success(let changeSet):
            // changeSet.key
            // changeSet.object
        case .failure(let error):
            // error handle
        }
    }
    .store(in: &cancellable)
```
---

## 다양한 타입의 Key 활용
CacheStorage 의 Key 는 Hashable 하다면 사용 가능합니다.
### 1. String Type
```swift
// 1. Config 객체 생성, Key 타입 String
let memoryConfig = MemoryStorage<String, SampleCacheableObject>.Config(totalCostLimit: 1024 * 10)
let diskConfig = DiskStorage<String, SampleCacheableObject>.Config()

// 2. CacheStorage 객체 생성
let cacheStorage = CacheStorage(
    memoryConfig: memoryConfig,
    diskConfig: diskConfig
)

cacheStorage.save(with: beStoreObject, key: "string_key_1")
// ... do something
```
### 2. Array Type
```swift
// 1. Config 객체 생성, Key 타입 [String]
let memoryConfig = MemoryStorage<[String], SampleCacheableObject>.Config(totalCostLimit: 1024 * 10)
let diskConfig = DiskStorage<[String], SampleCacheableObject>.Config()

// 2. CacheStorage 객체 생성
let cacheStorage = CacheStorage(
    memoryConfig: memoryConfig,
    diskConfig: diskConfig
)

cacheStorage.save(with: beStoreObject, key: ["one", "two", "three", "four"])
// ... do something
```
### 3. Dictionary Type
```swift
// 1. Config 객체 생성, Key 타입 Dictionary [String: String]
let memoryConfig = MemoryStorage<[String: String], SampleCacheableObject>.Config(totalCostLimit: 1024 * 10)
let diskConfig = DiskStorage<[String: String], SampleCacheableObject>.Config()

// 2. CacheStorage 객체 생성
let cacheStorage = CacheStorage(
    memoryConfig: memoryConfig,
    diskConfig: diskConfig
)

cacheStorage.save(with: beStoreObject, key: [
    "first_key": "first_value",
     "second_key": "second_value", 
     "third_key": "third_value"
     ]
    )
// ... do something
```
### 4. Custom Type 
```swift
//MAKR: Custom Key Struct Definition
final class SampleCustomKey: Hashable {
    var id: String
    var something: String
    
    init(id: String, something: String) {
        self.id = id
        self.something = something
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(something)
    }
    
    static func == (lhs: SampleCustomKey, rhs: SampleCustomKey) -> Bool {
        lhs.id == rhs.id && lhs.something == rhs.something
    }
}

//MARK: Sample
// 1. Config 객체 생성, Key 타입 Dictionary [String: String]
let memoryConfig = MemoryStorage<SampleCustomKey, SampleCacheableObject>.Config(totalCostLimit: 1024 * 10)
let diskConfig = DiskStorage<SampleCustomKey, SampleCacheableObject>.Config()

// 2. CacheStorage 객체 생성
let cacheStorage = CacheStorage(
    memoryConfig: memoryConfig,
    diskConfig: diskConfig
)

let firstSampleCustomKey = SampleCustomKey(id: "first_custom_key")
let secondSampleCustomKey = SampleCustomKey(id: "second_custom_key")

// Data save
cacheStorage.save(with: beStoreObject, key: firstSampleCustomKey)
// or
cacheStorage.save(with: beStoreObject, key: secondSampleCustomKey)

// do something ...
```

---

### 3. CustomKey의 유니크 특성 확인

#### 동일한 키를 사용할 경우
```swift
let customKey = CustomKey(name: "SharedKey")

cache.save(value: "First Entry", forKey: customKey)
cache.save(value: "Second Entry", forKey: customKey) // 덮어씌워짐

if let retrieved: String = cache.retrieve(forKey: customKey) {
    print("CustomKey로 가져온 데이터: \(retrieved)") // "Second Entry"
}
```

#### 다른 UUID를 가진 키를 사용할 경우
```swift
let uniqueKey1 = CustomKey(id: UUID(), name: "Key1")
let uniqueKey2 = CustomKey(id: UUID(), name: "Key1") // 같은 이름, 다른 UUID

cache.save(value: "Value for Key1", forKey: uniqueKey1)

if let data: String = cache.retrieve(forKey: uniqueKey2) {
    print("가져온 데이터: \(data)")
} else {
    print("UUID가 다르므로 데이터가 없습니다.") // 출력
}
```

---

## ✅ 주요 기능

- 메모리 및 디스크 캐싱 계층 제공
- 다양한 타입의 키와 값을 저장 가능
- 제네릭으로 유연한 키 타입 지원 (`Hashable` 프로토콜 준수)
- 사용자 정의 키를 활용한 캐싱 (`NSCacheKey`와 호환)
- 캐시 데이터 자동 정리 (용량 초과 시 오래된 데이터 삭제)
- Thread-Safe 동작
- 캐시 변경 사항 실시간 관찰 (`storageObserver` 퍼블리셔 사용)
