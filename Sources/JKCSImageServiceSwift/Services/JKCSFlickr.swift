//
//  JKCSFlickr.swift
//  JKCSImageServiceSwift
//
//  Created by Zhengqian Kuang on 2020-06-13.
//  Copyright © 2020 Kuang. All rights reserved.
//

import Foundation
import JKCSSwift

open class JKCSFlickr: JKCSImageService {
    static let magic = "d96d9ec626e26cd469ac580b07dcf573"
    public var searchResult = JKCSImageSearchResult()
    
    public init() {}

    public func search(for term: String, pageSize: Int = 20, page: Int = -1, completionHandler: @escaping (Result<JKCSImageSearchResult, JKCSError>) -> ()) {
        let lastTerm = searchResult.term
        if term != lastTerm {
            searchResult = JKCSImageSearchResult(term: term)
        }
        var page = page
        if page == -1 {
            searchResult.page += 1
            if searchResult.page < 1 {
                searchResult.page = 1
            }
            page = searchResult.page
        }
        guard let urlString = flickrSearchURL(for: term, pageSize: pageSize, page: page) else {
            completionHandler(Result.failure(.customError(message: "Failed to compose Flickr search URL")))
            return
        }
        JKCSNetworkService.shared.dataTask(method: .GET, url: urlString) { (result) in
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
    
    private func flickrSearchURL(for searchTerm:String, pageSize: Int = 100, page: Int = 1) -> String? {
        guard let escapedTerm = searchTerm.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics) else {
          return nil
        }
        
        // ref. https://www.flickr.com/services/api/flickr.photos.search.html
        let key = String(JKCSFlickr.magic.reversed())
        let urlString = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(key)&text=\(escapedTerm)&per_page=\(pageSize)&page=\(page)&format=json&nojsoncallback=1"
        return urlString
    }
    
    private func parseSearchResult(_ result: Any) -> Result<JKCSImageSearchResult, JKCSError> {
        guard
            let result = result as? [String : Any],
            let stat = result["stat"] as? String
        else {
            return Result.failure(.customError(message: "Unrecognized resonse format"))
        }
        if stat != "ok" {
            print("Flickr search result stat \(stat)\n\(result)")
            return Result.failure(.customError(message: "Abnormal stat"))
        }
        guard
            let photosContainer = result["photos"] as? [String: Any],
            let photos = photosContainer["photo"] as? [[String: Any]]
        else {
            return Result.failure(.customError(message: "Unrecognized resonse format"))
        }
        if let total = photosContainer["total"] {
            searchResult.total = Int("\(total)") ?? -1
        }
        else {
            searchResult.total = -1
        }
        searchResult.page = photosContainer["page"] as? Int ?? -1
        searchResult.pages = photosContainer["pages"] as? Int ?? -1
        searchResult.perpage = photosContainer["perpage"] as? Int ?? -1
        for photo in photos {
            guard
                let id = photo["id"] as? String,
                let farm = photo["farm"] as? Int ,
                let server = photo["server"] as? String ,
                let secret = photo["secret"] as? String
            else {
                continue
            }
            let title = photo["title"] as? String ?? "untitled"
            let flickrImage = JKCSFlickrImage(id: id, farm: farm, server: server, secret: secret)
            flickrImage.title = title
            if !(searchResult.items.contains(flickrImage)) {
                searchResult.items.append(flickrImage)
            }
        }
        return Result.success(searchResult)
    }
}
