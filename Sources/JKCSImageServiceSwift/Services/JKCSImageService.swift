//
//  JKCSImageService.swift
//  JKCSImageServiceSwift
//
//  Created by Zhengqian Kuang on 2020-06-13.
//  Copyright © 2020 Kuang. All rights reserved.
//

import Foundation
import JKCSSwift

public enum JKCSImageDataSourceType: String {
    case Flickr, Unsplash
    
    public mutating func `switch`() {
        switch self {
        case .Flickr:
            self = .Unsplash
        case .Unsplash:
            self = .Flickr
        }
    }
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
