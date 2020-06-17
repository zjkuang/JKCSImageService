//
//  JKCSUnsplash.swift
//  JKCSImageServiceSwift
//
//  Created by Zhengqian Kuang on 2020-06-17.
//  Copyright © 2020 Kuang. All rights reserved.
//

import Foundation
import JKCSSwift

open class JKCSUnsplash: JKCSImageService {
    static let magic = "ANT0irtZCuLpJ20tzFbhK7MAbAYbWB6zqOJ1krFmYHL"
    public var searchResult = JKCSImageSearchResult()
    public static var key = decode(str: magic)
    
    public init() {}

    public func search(for term: String, pageSize: Int = 20, page: Int = -1, completionHandler: @escaping (Result<JKCSImageSearchResult, JKCSError>) -> ()) {
        let lastTerm = searchResult.term
        if term != lastTerm {
            searchResult = JKCSImageSearchResult(term: term)
        }
        var page = page
        if page == -1 {
            searchResult.page += 1
            page = searchResult.page
        }
        guard let urlString = unsplashSearchURL(for: term, pageSize: pageSize, page: page) else {
            completionHandler(Result.failure(.customError(message: "Failed to compose Flickr search URL")))
            return
        }
        let header = ["Authorization" : "Client-ID \(JKCSUnsplash.key)"]
        JKCSNetworkService.shared.dataTask(method: .GET, url: urlString, httpHeaders: header) { (result) in
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
    
    private func unsplashSearchURL(for searchTerm:String, pageSize: Int = 100, page: Int = 1) -> String? {
        guard let escapedTerm = searchTerm.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics) else {
          return nil
        }
        
        // ref. https://unsplash.com/documentation#search-photos
        let urlString = "https://api.unsplash.com/search/photos?query=\(escapedTerm)&per_page=\(pageSize)&page=\(page)"
        return urlString
    }
    
    private func parseSearchResult(_ result: Any) -> Result<JKCSImageSearchResult, JKCSError> {
        guard
            let result = result as? [String : Any],
            let results = result["results"] as? [[String : Any]]
        else {
            return Result.failure(.customError(message: "Unrecognized resonse format"))
        }
        if let total = result["total"] as? Int {
            searchResult.total = total
        }
        if let total_pages = result["total_pages"] as? Int {
            searchResult.pages = total_pages
        }
        for result in results {
            guard
                let id = result["id"] as? String,
                let urls = result["urls"] as? [String : String]
            else {
                continue
            }
            let title = result["description"] as? String ?? "untitled"
            let unsplashImage = JKCSUnsplashImage(id: id, urls: urls)
            unsplashImage.title = title
            if !(searchResult.items.contains(unsplashImage)) {
                searchResult.items.append(unsplashImage)
            }
        }
        return Result.success(searchResult)
    }
    
    public static func decode(str: String) -> String {
        var result = ""
        for c in str {
            result = "\(c)\(result)"
        }
        return result
    }
}
