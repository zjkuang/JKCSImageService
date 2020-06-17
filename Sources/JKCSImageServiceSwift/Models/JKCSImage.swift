//
//  ImagePack.swift
//  JKCSImageServiceSwift
//
//  Created by Zhengqian Kuang on 2020-06-13.
//  Copyright © 2020 Kuang. All rights reserved.
//

import Foundation
import JKCSSwift

public enum JKCSImageSize {
    case thumbnail, small, medium, large, extraLarge, original
}

open class JKCSImage: Equatable {
    public let id: String
    public var title: String = ""
    public var info: JKCSImageInfo {
        didSet {
            info.save(key: id)
        }
    }
    public var thumbnailImageData: JKCSImageData? = nil
    public var smallImageData: JKCSImageData? = nil
    public var mediumImageData: JKCSImageData? = nil
    public var largeImageData: JKCSImageData? = nil
    public var extraLargeImageData: JKCSImageData? = nil
    public var originalImageData: JKCSImageData? = nil
    
    public init(id: String) {
        self.id = id
        self.info = JKCSImageInfo(id: id)
    }
    
    public static func == (lhs: JKCSImage, rhs: JKCSImage) -> Bool {
        return (lhs.id == rhs.id)
    }
    
    public func retrieveImageDataFromCache(size: JKCSImageSize) -> JKCSCacheLookupResult {
        switch size {
        case .thumbnail:
            guard let targetImageData = thumbnailImageData else { return .abnormal }
            let result: Result<JKCSImageData?, JKCSError> = JKCSImageData.retrieve(key: targetImageData.id)
            switch result {
            case .failure(_):
                return .abnormal
            case .success(let imageData):
                if let imageData = imageData {
                    thumbnailImageData = imageData
                    return .hit
                }
                return .miss
            }
        case .small:
            guard let targetImageData = smallImageData else { return .abnormal }
            let result: Result<JKCSImageData?, JKCSError> = JKCSImageData.retrieve(key: targetImageData.id)
            switch result {
            case .failure(_):
                return .abnormal
            case .success(let imageData):
                if let imageData = imageData {
                    smallImageData = imageData
                    return .hit
                }
                return .miss
            }
        case .medium:
            guard let targetImageData = mediumImageData else { return .abnormal }
            let result: Result<JKCSImageData?, JKCSError> = JKCSImageData.retrieve(key: targetImageData.id)
            switch result {
            case .failure(_):
                return .abnormal
            case .success(let imageData):
                if let imageData = imageData {
                    mediumImageData = imageData
                    return .hit
                }
                return .miss
            }
        case .large:
            guard let targetImageData = largeImageData else { return .abnormal }
            let result: Result<JKCSImageData?, JKCSError> = JKCSImageData.retrieve(key: targetImageData.id)
            switch result {
            case .failure(_):
                return .abnormal
            case .success(let imageData):
                if let imageData = imageData {
                    largeImageData = imageData
                    return .hit
                }
                return .miss
            }
        case .extraLarge:
            guard let targetImageData = extraLargeImageData else { return .abnormal }
            let result: Result<JKCSImageData?, JKCSError> = JKCSImageData.retrieve(key: targetImageData.id)
            switch result {
            case .failure(_):
                return .abnormal
            case .success(let imageData):
                if let imageData = imageData {
                    extraLargeImageData = imageData
                    return .hit
                }
                return .miss
            }
        case .original:
            guard let targetImageData = originalImageData else { return .abnormal }
            let result: Result<JKCSImageData?, JKCSError> = JKCSImageData.retrieve(key: targetImageData.id)
            switch result {
            case .failure(_):
                return .abnormal
            case .success(let imageData):
                if let imageData = imageData {
                    originalImageData = imageData
                    return .hit
                }
                return .miss
            }
        }
    }
    
    public func retrieveImageInfoFromCache() -> JKCSCacheLookupResult {
        let result: Result<JKCSImageInfo?, JKCSError> = JKCSImageInfo.retrieve(key: id)
        switch result {
        case .failure(_):
            return .abnormal
        case .success(let imageInfo):
            if let imageInfo = imageInfo {
                info = imageInfo
                return .hit
            }
            return .miss
        }
    }
    
    open func loadImageData(size: JKCSImageSize, completionHandler: @escaping (Result<ExpressibleByNilLiteral?, JKCSError>) -> ()) {
        // To be overridden by subclass
    }
    
    open func loadImageInfo(completionHandler: @escaping (Result<ExpressibleByNilLiteral?, JKCSError>) -> ()) {
        // To be overriddent by subclass
    }
}

open class JKCSImageData: JKCSCachable {
    public let id: String
    public var data: Data? {
        didSet {
            if let _ = data {
                save(key: id)
            }
        }
    }
    
    public init(id: String, data: Data? = nil) {
        self.id = id
        self.data = data
    }
}

open class JKCSImageInfo: JKCSCachable {
    public let id: String
    public var title: String
    public var author: String
    public var date: String
    public var location: String
    public var description: String
    
    public init(id: String, title: String = "", author: String = "", date: String = "", location: String = "", description: String = "") {
        self.id = id
        self.title = title
        self.author = author
        self.date = date
        self.location = location
        self.description = description
    }
}
