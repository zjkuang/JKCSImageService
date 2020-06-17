//
//  JKCSImgur.swift
//  Practice001
//
//  Created by Zhengqian Kuang on 2020-06-16.
//  Copyright © 2020 Kuang. All rights reserved.
//

import Foundation
import JKCSSwift
import JKCSImageServiceSwift

/// Warning: This token is exposed for public demo purpose. It will expire in one month
public let imgurAccessToken = "6812d77cb6abc99f0a54e92d1282ffe53b256b5a"

open class JKCSImgur: JKCSImageService {
    public var searchResult = JKCSImageSearchResult()
    
    public init() {}

    open func search(for term: String, pageSize: Int = 20, page: Int = -1, completionHandler: @escaping (Result<JKCSImageSearchResult, JKCSError>) -> ()) {
        var debugInfo = "*** Imgur searching for \(term)."
        let lastTerm = searchResult.term
        if term != lastTerm {
            debugInfo.append(" New search.")
            searchResult = JKCSImageSearchResult(term: term)
        }
        else {
            debugInfo.append(" Same search.")
        }
        print(debugInfo)
        var page = page
        if page == -1 {
            searchResult.page += 1
            page = searchResult.page
            debugInfo.append(" Page \(page)")
        }
        guard let urlString = imgurSearchURL(for: term, page: page) else {
            completionHandler(Result.failure(.customError(message: "Failed to compose Imgur search URL")))
            return
        }
        let headers = ["Authorization" : "Bearer \(imgurAccessToken)"]
        JKCSNetworkService.shared.dataTask(method: .GET, url: urlString, httpHeaders: headers) { (result) in
            switch result {
            case .failure(let error):
                completionHandler(Result.failure(error))
                return
            case .success(let result):
                let result = self.parseSearchResult(result)
                switch result {
                case .failure(let error):
                    completionHandler(Result.failure(error))
                    return
                case .success(let searchResult):
                    completionHandler(Result.success(searchResult))
                    return
                }
            }
        }
    }
    
    private func imgurSearchURL(for searchTerm:String, page: Int = 1) -> String? {
        guard let escapedTerm = searchTerm.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics) else {
          return nil
        }
        
        let urlString = "https://api.imgur.com/3/gallery/search/\(page)/?q=\(escapedTerm)"
        return urlString
    }
    
    private func parseSearchResult(_ result: Any) -> Result<JKCSImageSearchResult, JKCSError> {
        guard
            let result = result as? [String : Any],
            let success = result["success"] as? Bool
        else {
            return Result.failure(.customError(message: "Unrecognized resonse format"))
        }
        // print("*** Imgur search result:\n\(result)")
        guard success else {
            print("Imgur search result success \(success)\n\(result)")
            return Result.failure(.customError(message: "Failure"))
        }
        guard
            let data = result["data"] as? [[String: Any]]
        else {
            return Result.failure(.customError(message: "Unrecognized resonse format"))
        }
        for item in data {
            guard
                let _ = item["id"] as? String,
                let images = item["images"] as? [[String : Any]],
                images.count > 0
            else {
                continue
            }
            for image in images {
                guard
                    let id = image["id"] as? String,
                    let link = image["link"] as? String
                else {
                    continue
                }
                if let type = image["type"] as? String,
                    ((type == "image/jpeg") || (type == "image/png")){
                    let imgurImage = JKCSImgurImage(id: id, link: link)
                    let title = image["title"] as? String ?? "Untitled"
                    imgurImage.title = title
                    imgurImage.info.title = title
                    if let datetime = image["datetime"] as? Int {
                        imgurImage.info.date = Date(timeIntervalSince1970: Double(datetime)).yyyyMMddHHmmss()
                    }
                    imgurImage.info.description = image["description"] as? String ?? ""
                    if !(searchResult.items.contains(imgurImage)) {
                        searchResult.items.append(imgurImage)
                    }
                    break
                }
            }
        }
        return Result.success(searchResult)
    }
}
