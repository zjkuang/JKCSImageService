//
//  JKCSFlickr.swift
//  Practice001
//
//  Created by Zhengqian Kuang on 2020-06-13.
//  Copyright © 2020 Kuang. All rights reserved.
//

import Foundation
import JKCSSwift

// ref. https://www.raywenderlich.com/9334-uicollectionview-tutorial-getting-started

/// Warning: This key was generated for public demo purpose. If the key is private, make sure to put it in a separate file and use git-crypt to encrypt it before pushing.
public let flickrAppKey = "375fcd70b085ca964dc62e626ce9d69d"

open class JKCSFlickr: JKCSImageService {
    public var searchResult = JKCSImageSearchResult()
    
    public init() {}

    public func search(for term: String, pageSize: Int = 20, page: Int = -1, completionHandler: @escaping (Result<JKCSImageSearchResult, JKCSError>) -> ()) {
        var debugInfo = "*** Flickr searching for \(term)."
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
        // per_page (Optional)
        //   Number of photos to return per page. If this argument is omitted, it defaults to 100. The maximum allowed value is 500.
        // page (Optional)
        //   The page of results to return. If this argument is omitted, it defaults to 1.
        let urlString = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(flickrAppKey)&text=\(escapedTerm)&per_page=\(pageSize)&page=\(page)&format=json&nojsoncallback=1"
        return urlString
    }
    
    private func parseSearchResult(_ result: Any) -> Result<JKCSImageSearchResult, JKCSError> {
        guard
            let result = result as? [String : Any],
            let stat = result["stat"] as? String
        else {
            return Result.failure(.customError(message: "Unrecognized resonse format"))
        }
        // print("*** Flickr search result:\n\(result)")
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
        let debugInfo = "*** Flickr searchResult: total \(searchResult.total), page \(searchResult.page), pages \(searchResult.pages), perpage \(searchResult.perpage)"
        print(debugInfo)
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
