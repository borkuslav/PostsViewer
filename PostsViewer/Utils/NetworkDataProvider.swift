//
//  DataProvider.swift
//  PostsViewer
//
//  Created by Bogusław Parol on 22/06/2019.
//  Copyright © 2019 Parbo. All rights reserved.
//

import Foundation
import RxSwift

enum NetworkError: LocalizedError {
    case loadingResourceFailed(Int)
    case parsingResourceFailed

    var errorDescription: String? {
        switch self {
        case .loadingResourceFailed(let code):
            return "Loading data failed with code \(code)!"
        case .parsingResourceFailed:
            return "Parsing data failed!"
        }
    }
}

class URLFactory {
    static let postsUrlString = "http://jsonplaceholder.typicode.com/posts"
    static let usersUrlString = "http://jsonplaceholder.typicode.com/users"
    static let comments = "http://jsonplaceholder.typicode.com/comments"
}

protocol NetworkPostsProvider {
    func getPosts() -> Observable<[Post]>
}

protocol NetworkUsersProvider {
    func getUsers() -> Observable<[User]>
}

protocol NetworkCommentsProvider {
    func getComments() -> Observable<[Comment]>
}

class NetworkDataProvider: NetworkPostsProvider, NetworkUsersProvider, NetworkCommentsProvider {

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
                    return .error(NetworkError.parsingResourceFailed)
                }
                return .error(NetworkError.loadingResourceFailed(response.statusCode))
            }
    }
}
