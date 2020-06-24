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
    public let provider: JKCSImageDataSourceType
    public let id: String
    public var title: String = ""
    public var info: JKCSImageInfo
    public var thumbnailImageData: JKCSImageData? = nil
    public var smallImageData: JKCSImageData? = nil
    public var mediumImageData: JKCSImageData? = nil
    public var largeImageData: JKCSImageData? = nil
    public var extraLargeImageData: JKCSImageData? = nil
    public var originalImageData: JKCSImageData? = nil
    
    public init(id: String, provider: JKCSImageDataSourceType) {
        self.provider = provider
        self.id = id
        self.info = JKCSImageInfo(id: id, provider: provider.rawValue)
    }
    
    public static func == (lhs: JKCSImage, rhs: JKCSImage) -> Bool {
        return (lhs.id == rhs.id)
    }
    
    public func retrieveImageDataFromCache(size: JKCSImageSize) -> JKCSCacheLookupResult {
        let imageFilename = getImageFilename(size: size)
        let result: Result<JKCSImageData?, JKCSError> = JKCSImageData.retrieve(key: imageFilename, group: provider.rawValue)
        switch result {
        case .failure(_):
            return .abnormal
        case .success(let imageData):
            guard let imageData = imageData else { return .miss }
            switch size {
            case .thumbnail:
                thumbnailImageData = imageData
            case .small:
                smallImageData = imageData
            case .medium:
                mediumImageData = imageData
            case .large:
                largeImageData = imageData
            case .extraLarge:
                extraLargeImageData = imageData
            case .original:
                originalImageData = imageData
            }
            return .hit
        }
    }
    
    public func retrieveImageInfoFromCache() -> JKCSCacheLookupResult {
        let result: Result<JKCSImageInfo?, JKCSError> = JKCSImageInfo.retrieve(key: id) // JKCSImageInfo.retrieve(key: id, group: provider.rawValue)
        switch result {
        case .failure(_):
            return .abnormal
        case .success(let imageInfo):
            guard let imageInfo = imageInfo else {
                return .miss
            }
            info = imageInfo
            return .hit
        }
    }
    
    func getSizeLetter(size: JKCSImageSize) -> String {
        let sizeLetter: String // original image, either a jpg, gif or png, depending on source format
        switch size {
        case .thumbnail:
            sizeLetter = "t"
        case .small:
            sizeLetter = "n"
        case .medium:
            sizeLetter = "c"
        case .large:
            sizeLetter = "b"
        case .extraLarge:
            sizeLetter = "k"
        case .original:
            sizeLetter = "o"
        }
        return sizeLetter
    }
    
    func getImageFilename(size: JKCSImageSize) -> String {
        let sizeLetter = getSizeLetter(size: size)
        let filename = "\(id)_\(sizeLetter)"
        return filename
    }
    
    open func loadImageData(size: JKCSImageSize, completionHandler: @escaping (Result<ExpressibleByNilLiteral?, JKCSError>) -> ()) {
        // To be overridden by subclass
    }
    
    open func loadImageInfo(completionHandler: @escaping (Result<ExpressibleByNilLiteral?, JKCSError>) -> ()) {
        // To be overriddent by subclass
    }
}

open class JKCSImageData: JKCSCacheable {
    public let provider: String
    public let id: String
    public let url: String
    public let filename: String
    public var data: Data? {
        didSet {
            if let _ = data {
                save(key: filename, group: provider)
            }
        }
    }
    
    public init(id: String, url: String, filename: String, provider: String, data: Data? = nil) {
        self.provider = provider
        self.id = id
        self.url = url
        self.filename = filename
        self.data = data
    }
}

open class JKCSImageInfo: JKCSCacheable {
    public let provider: String
    public let id: String
    public let filename: String
    public var title: String
    public var author: String
    public var date: String
    public var location: String
    public var description: String
    
    public init(id: String, filename: String? = nil, provider: String, title: String = "", author: String = "", date: String = "", location: String = "", description: String = "") {
        self.provider = provider
        self.id = id
        self.filename = filename ?? id
        self.title = title
        self.author = author
        self.date = date
        self.location = location
        self.description = description
    }
}
