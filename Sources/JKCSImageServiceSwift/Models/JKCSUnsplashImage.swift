//
//  JKCSUnsplashImage.swift
//  JKCSImageServiceSwift
//
//  Created by Zhengqian Kuang on 2020-06-17.
//  Copyright © 2020 Kuang. All rights reserved.
//

import Foundation
import JKCSSwift

open class JKCSUnsplashImage: JKCSImage {
    public init(id: String, urls: [String : String]) {
        super.init(id: id, provider: .Unsplash)
        
        if let thumb = urls["thumb"] {
            self.thumbnailImageData = JKCSImageData(id: id, url: thumb, filename: getImageFilename(size: .thumbnail), provider: provider.rawValue)
        }
        if let small = urls["small"] {
            self.smallImageData = JKCSImageData(id: id, url: small, filename: getImageFilename(size: .small), provider: provider.rawValue)
        }
        if let regular = urls["regular"] {
            self.mediumImageData = JKCSImageData(id: id, url: regular, filename: getImageFilename(size: .medium), provider: provider.rawValue)
        }
        if let full = urls["full"] {
            self.largeImageData = JKCSImageData(id: id, url: full, filename: getImageFilename(size: .large), provider: provider.rawValue)
        }
        if let raw = urls["raw"] {
            self.extraLargeImageData = JKCSImageData(id: id, url: raw, filename: getImageFilename(size: .extraLarge), provider: provider.rawValue)
            self.originalImageData = JKCSImageData(id: id, url: raw, filename: getImageFilename(size: .original), provider: provider.rawValue)
        }
    }
    
    override public func loadImageData(size: JKCSImageSize = .original, completionHandler: @escaping (Result<ExpressibleByNilLiteral?, JKCSError>) -> ()) {
        let cacheLookup = retrieveImageDataFromCache(size: size)
        if cacheLookup == .hit {
            completionHandler(Result.success(nil))
            return
        }
        guard let urlString = loadImageURL(size: size) else {
            completionHandler(Result.failure(.customError(message: "URL for the image with specified size is unavailable.")))
            return
        }
        let header = ["Authorization" : "Client-ID \(JKCSUnsplash.key)"]
        JKCSNetworkService.shared.dataTask(method: .GET, url: urlString, httpHeaders: header, resultFormat: .data) { [weak self] (result) in
            switch result {
            case .failure(let error):
                completionHandler(Result.failure(error))
                return
            case .success(let result):
                if let data = result as? Data {
                    switch size {
                    case .thumbnail:
                        self?.thumbnailImageData!.data = data
                    case .small:
                        self?.smallImageData!.data = data
                    case .medium:
                        self?.mediumImageData!.data = data
                    case .large:
                        self?.largeImageData!.data = data
                    case .extraLarge:
                        self?.extraLargeImageData!.data = data
                    case .original:
                        self?.originalImageData!.data = data
                    }
                    completionHandler(Result.success(nil))
                    return
                }
                else {
                    completionHandler(Result.failure(.customError(message: "Unknown return type")))
                    return
                }
            }
        }
    }
    
    override public func loadImageInfo(completionHandler: @escaping (Result<ExpressibleByNilLiteral?, JKCSError>) -> ()) {
        let cacheLookup = retrieveImageInfoFromCache()
        if cacheLookup == .hit {
            completionHandler(Result.success(nil))
            return
        }
        
        let urlString = loadImageInfoURL(id: id)
        let header = ["Authorization" : "Client-ID \(JKCSUnsplash.key)"]
        JKCSNetworkService.shared.dataTask(method: .GET, url: urlString, httpHeaders: header) { [weak self] (result) in
            switch result {
            case .failure(let error):
                completionHandler(Result.failure(error))
            case .success(let result):
                if let result = result as? [String : Any] {
                    self?.populateImageInfo(info: result, completionHandler: { (result) in
                        completionHandler(result)
                    })
                }
                else {
                    completionHandler(Result.failure(.customError(message: "Unknown result format")))
                }
            }
        }
    }
    
    private func loadImageURL(size: JKCSImageSize = .original) -> String? {
        switch size {
        case .thumbnail:
            return thumbnailImageData?.url
        case .small:
            return smallImageData?.url
        case .medium:
            return mediumImageData?.url
        case .large:
            return largeImageData?.url
        case .extraLarge:
            return extraLargeImageData?.url
        case .original:
            return originalImageData?.url
        }
    }
    
    private func loadImageInfoURL(id: String) -> String {
        let urlString = "https://api.unsplash.com/photos/\(id)"
        return urlString
    }
    
    private func populateImageInfo(info: [String : Any], completionHandler: @escaping (Result<ExpressibleByNilLiteral?, JKCSError>) -> ()) {
        let imageInfo = self.info
        imageInfo.title = info["description"] as? String ?? "Untitled"
        if let user = info["user"] as? [String : Any] {
            if let name = user["name"] as? String {
                imageInfo.author = name
            }
            else if let username = user["username"] as? String {
                imageInfo.author = username
            }
        }
        if let date = info["created_at"] as? String {
            imageInfo.date = date
        }
        if let description = info["description"] as? String {
            imageInfo.description = description
        }
        if let location = info["location"] as? [String : Any] {
            if let title = location["title"] as? String,
                title.count > 0 {
                imageInfo.location = title
            }
            else if let name = location["name"] as? String,
                name.count > 0 {
                imageInfo.location = name
            }
            else if let position = location["position"] as? [String : Double],
                let latitude = position["latitude"],
                let longitude = position["longitude"] {
                JKCSOpenCageGeoService.mapFormatted(latitude: "\(latitude)", longitude: "\(longitude)") { [weak self] (result) in
                    switch result {
                    case .failure(let error):
                        print("OpenCageGeoService.map failed. \(error.message)")
                        // even though location parsing failed, let the imageInfo still be returned
                    case .success(let result):
                        imageInfo.location = result
                        return
                    }
                    self?.updateInfo(info: imageInfo, writeThrouthCache: true)
                    completionHandler(Result.success(nil))
                    return
                }
                return
            }
            self.updateInfo(info: imageInfo, writeThrouthCache: true)
            completionHandler(Result.success(nil))
            return
        }
        else {
            self.updateInfo(info: imageInfo, writeThrouthCache: true)
            completionHandler(Result.success(nil))
            return
        }
    }
    
    private func updateInfo(info: JKCSImageInfo, writeThrouthCache: Bool) {
        self.info = info
        if writeThrouthCache {
            self.info.save(key: id, group: provider.rawValue)
        }
    }
}
