//
//  FlickrImagePack.swift
//  Practice001
//
//  Created by Zhengqian Kuang on 2020-06-13.
//  Copyright © 2020 Kuang. All rights reserved.
//

import Foundation
import JKCSSwift

public class JKCSFlickrImage: JKCSImage {
    public let farm: Int
    public let server: String
    public let secret: String
    
    public init(id: String, farm: Int, server: String, secret: String) {
        self.farm = farm
        self.server = server
        self.secret = secret
        
        super.init(id: id)
        
        self.thumbnailImageData = JKCSImageData(id: JKCSFlickrImage.loadImageURL(farm: farm, server: server, id: id, secret: secret, size: .thumbnail))
        self.smallImageData = JKCSImageData(id: JKCSFlickrImage.loadImageURL(farm: farm, server: server, id: id, secret: secret, size: .small))
        self.mediumImageData = JKCSImageData(id: JKCSFlickrImage.loadImageURL(farm: farm, server: server, id: id, secret: secret, size: .medium))
        self.largeImageData = JKCSImageData(id: JKCSFlickrImage.loadImageURL(farm: farm, server: server, id: id, secret: secret, size: .large))
        self.extraLargeImageData = JKCSImageData(id: JKCSFlickrImage.loadImageURL(farm: farm, server: server, id: id, secret: secret, size: .extraLarge))
        self.originalImageData = JKCSImageData(id: JKCSFlickrImage.loadImageURL(farm: farm, server: server, id: id, secret: secret, size: .original))
    }
    
    override public func loadImageData(size: JKCSImageSize = .original, completionHandler: @escaping (Result<ExpressibleByNilLiteral?, JKCSError>) -> ()) {
        let cacheLookup = retrieveImageDataFromCache(size: size)
        if cacheLookup == .hit {
            completionHandler(Result.success(nil))
            return
        }
        let urlString = JKCSFlickrImage.loadImageURL(farm: farm, server: server, id: id, secret: secret, size: size)
        JKCSNetworkService.shared.dataTask(method: .GET, url: urlString, resultFormat: .data) { [weak self] (result) in
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
        
        // Flickr's flickr.photos.getInfo API has a very weird response format
        // By default the response is an XML string with abnormal format which
        // is not able to be parsed.
        // So we need to add "format=json" as a parameter to the request, but
        // the response is not parsable by JSONSerializer's jsonObject method,
        // Converting the response data to String (with .utf8) reveals that
        // Flickr wrapped the JSON string in jsonFlickrApi(). So we need to
        // drop the leading substring "jsonFlickrApi(" and the trailing sub-
        // string ")" and then the remaining part will be able to be parsed
        // into a JSON object.
        
        let urlString = JKCSFlickrImage.loadImageInfoURL(id: id)
        JKCSNetworkService.shared.dataTask(method: .GET, url: urlString, resultFormat: .data) { [weak self] (result) in
            switch result {
            case .failure(let error):
                completionHandler(Result.failure(error))
            case .success(let result):
                if let data = result as? Data,
                    let result = self?.decodeJsonFlickrApiResponse(data: data) as? [String : Any] {
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
    
    private static func loadImageURL(farm: Int, server: String, id: String, secret: String, size: JKCSImageSize = .original) -> String {
        // ref. https://www.flickr.com/services/api/misc.urls.html
        var sizeLetter = "o" // original image, either a jpg, gif or png, depending on source format
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
        default:
            break
        }
        let urlString = "https://farm\(farm).staticflickr.com/\(server)/\(id)_\(secret)_\(sizeLetter).jpg"
        return urlString
    }
    
    private static func loadImageInfoURL(id: String) -> String {
        // The response format defaults to be an XML
        let urlString = "https://api.flickr.com/services/rest/?method=flickr.photos.getInfo&api_key=\(flickrAppKey)&photo_id=\(id)&format=json"
        return urlString
    }
    
    private func decodeJsonFlickrApiResponse(data: Data) -> Any? {
        guard let jsonFlickrApiString = String(data: data, encoding: .utf8) else {
            return nil
        }
        var subString = jsonFlickrApiString.dropFirst("jsonFlickrApi(".count)
        subString = subString.dropLast(1)
        let jsonString = String(subString)
        let jsonObject = jsonString.toJSONObject()
        return jsonObject
    }
    
    private func populateImageInfo(info: [String : Any], completionHandler: @escaping (Result<ExpressibleByNilLiteral?, JKCSError>) -> ()) {
        guard
            let stat = info["stat"] as? String,
            stat == "ok"
        else {
            completionHandler(Result.failure(.customError(message: "imageInfo abnormal")))
            return
        }
        guard let photo = info["photo"] as? [String : Any] else {
            completionHandler(Result.failure(.customError(message: "imageInfo abnormal")))
            return
        }
        let imageInfo = self.info
        if let owner = photo["owner"] as? [String : Any] {
            if let realname = owner["realname"] as? String {
                imageInfo.author = realname
            }
            else if let username = owner["username"] as? String {
                imageInfo.author = username
            }
        }
        if let dates = photo["dates"] as? [String : Any],
            let taken = dates["taken"] as? String {
            imageInfo.date = taken
        }
        if let description = photo["description"] as? [String : Any],
            let _content = description["_content"] as? String {
            imageInfo.description = _content
        }
        if let location = photo["location"] as? [String : Any],
            let latitude = location["latitude"] as? String,
            latitude.count != 0,
            let longitude = location["longitude"] as? String,
            longitude.count != 0 {
            JKCSOpenCageGeoService.map(latitude: latitude, longitude: longitude) { [weak self] (result) in
                switch result {
                case .failure(let error):
                    print("OpenCageGeoService.map failed. \(error.message)")
                    completionHandler(Result.failure(error))
                    return
                case .success(let result):
                    self?.parseMapLocation(result: result)
                    completionHandler(Result.success(nil))
                    return
                }
            }
        }
        else {
            self.info = imageInfo
            completionHandler(Result.success(nil))
        }
    }
    
    private func parseMapLocation(result: [String : Any]) {
        guard
            let status = result["status"] as? [String : Any],
            let code = status["code"] as? Int,
            code == 200,
            let results = result["results"] as? [[String : Any]],
            let firstResult = results.first,
            let formatted = firstResult["formatted"] as? String
        else {
            return
        }
        let imageInfo = self.info
        imageInfo.location = formatted
        self.info = imageInfo
    }
}
