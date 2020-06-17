//
//  JKCSImgurImage.swift
//  Practice001
//
//  Created by Zhengqian Kuang on 2020-06-16.
//  Copyright © 2020 Kuang. All rights reserved.
//

import Foundation
import JKCSSwift

open class JKCSImgurImageInfo: JKCSImageInfo {
    
}

open class JKCSImgurImage: JKCSImage {
    public var link: String
    
    public init(id: String, link: String = "") {
        self.link = link
        
        super.init(id: id)
        
        self.thumbnailImageData = JKCSImageData(id: link)
        self.mediumImageData = JKCSImageData(id: link)
    }
    
    override public func loadImageData(size: JKCSImageSize = .original, completionHandler: @escaping (Result<ExpressibleByNilLiteral?, JKCSError>) -> ()) {
        let cacheLookup = retrieveImageDataFromCache(size: size)
        if cacheLookup == .hit {
            completionHandler(Result.success(nil))
            return
        }
        let urlString = link
        let headers = ["Authorization" : "Bearer \(imgurAccessToken)"]
        JKCSNetworkService.shared.dataTask(method: .GET, url: urlString, httpHeaders: headers, resultFormat: .data) { [weak self] (result) in
            switch result {
            case .failure(let error):
                completionHandler(Result.failure(error))
                return
            case .success(let result):
                if let data = result as? Data {
                    switch size {
                    case .thumbnail, .small, .medium, .large, .extraLarge, .original:
                        data.compressImageData(qualities: [.lowest, .low]) { (result) in
                            self?.thumbnailImageData!.data = result[0]
                            self?.mediumImageData!.data = result[1]
                        }
                        self?.mediumImageData!.data = data
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
    
    public override func loadImageInfo(completionHandler: @escaping (Result<ExpressibleByNilLiteral?, JKCSError>) -> ()) {
        completionHandler(Result.success(nil))
        return
    }
}
