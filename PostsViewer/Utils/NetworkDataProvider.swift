//
//  DataProvider.swift
//  PostsViewer
//
//  Created by Bogusław Parol on 22/06/2019.
//  Copyright © 2019 Parbo. All rights reserved.
//

import Foundation
import RxSwift

enum NetworkError: Error {
    case loadingResourceFailed
    case parsingResourceFailed
}

class URLFactory {
    static let postsUrlString = "http://jsonplaceholder.typicode.com/posts"
    static let usersUrlString = "http://jsonplaceholder.typicode.com/users"
    static let comments = "http://jsonplaceholder.typicode.com/comments"
}

class NetworkDataProvider {

    func getPosts() -> Observable<[Post]> {
        return get(url: URL(string: URLFactory.postsUrlString)!)
    }

    func getUsers() -> Observable<[User]> {
        return get(url: URL(string: URLFactory.usersUrlString)!)
    }

    func getComments() -> Observable<[Comment]> {
        return get(url: URL(string: URLFactory.comments)!)
    }

    func get<Model: Decodable>(url: URL) -> Observable<[Model]> {
        let urlRequest = URLRequest(url: url)
        return URLSession.shared.rx
            .response(request: urlRequest)
            .flatMap { (response: HTTPURLResponse, data: Data) -> Observable<[Model]> in
                if 200 ..< 300 ~= response.statusCode {
                    if let items = try? JSONDecoder().decode([Model].self, from: data) {
                        return .just(items)
                    }
                    return Observable.error(NetworkError.parsingResourceFailed)
                }
                return Observable.error(NetworkError.loadingResourceFailed)
            }
    }
}
