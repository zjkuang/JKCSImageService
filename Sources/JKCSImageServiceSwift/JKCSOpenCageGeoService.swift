//
//  JKCSOpenCageGeoService.swift
//  Practice001
//
//  Created by Zhengqian Kuang on 2020-06-13.
//  Copyright © 2020 Kuang. All rights reserved.
//

import Foundation
import JKCSSwift

/// Warning: This key was generated for public demo purpose. If the key is private, make sure to put it in a separate file and use git-crypt to encrypt it before pushing.
public let openCageGeoApiKey = "8824813b56b84f6f9fd3024d0d080388"

open class JKCSOpenCageGeoService {
    public init() {}
    
    public static func map(latitude: String, longitude: String, completionHander: @escaping (Result<[String : Any], JKCSError>) -> ()) {
        let url = "https://api.opencagedata.com/geocode/v1/json?q=\(latitude)+\(longitude)&key=\(openCageGeoApiKey)&pretty=1&no_annotations=1"
        JKCSNetworkService.shared.dataTask(method: .GET, url: url) { (result) in
            switch result {
            case .failure(let error):
                completionHander(Result.failure(error))
                return
            case .success(let result):
                if let result = result as? [String : Any] {
                    completionHander(Result.success(result))
                    return
                }
                else {
                    completionHander(Result.failure(.customError(message: "Unknown result format")))
                    return
                }
            }
        }
    }
}
