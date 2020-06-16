//
//  JKCSImageService.swift
//  Practice001
//
//  Created by Zhengqian Kuang on 2020-06-13.
//  Copyright © 2020 Kuang. All rights reserved.
//

import Foundation
import JKCSSwift

public enum JKCSImageDataSourceType {
    case Flickr
    // case Imgur, Unsplash, Shutterstock, GettyImages
}

open class JKCSImageSearchResult {
    public let term: String
    public var total: Int = -1
    public var page: Int = -1
    public var pages: Int = -1
    public var perpage: Int = 20
    public var items: [JKCSImage] = []
    
    public init(term: String = "") {
        self.term = term
    }
}

public protocol JKCSImageService {
    var searchResult: JKCSImageSearchResult {get set}
    func search(for term: String, pageSize: Int, page: Int, completionHandler: @escaping (Result<JKCSImageSearchResult, JKCSError>) -> ())
}
