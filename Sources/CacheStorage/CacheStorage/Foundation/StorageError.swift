//
//  StorageError.swift
//  SoongBook
//
//  Created by 이숭인 on 11/29/24.
//

import Foundation

public enum StorageError: Error {
    case unknown
    /// 객체를 찾을 수 없음
    case notFound
    /// 객체를 찾았으나 요청된 타입으로 캐스팅 실패
    case typeNotMatch
    /// 파일 속성이 잘못된 형식으로 저장됨
    case malformedFileAttributes
    /// 디코딩을 수행할 수 없음
    case decodingFailed
    /// 인코딩을 수행할 수 없음
    case encodingFailed
    /// 스토리지가 해제됨
    case deallocated
    /// 데이터를 변환(Transformation)하는 데 실패함
    case transformerFail
    /// Disk write 에 실패함
    case diskWriteFailure
    /// Disk remove 에 실패함
    case diskRemoveFailure
}
