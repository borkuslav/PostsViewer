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

class DataProvider {

    func getPosts(forceFromAPI: Bool) -> Observable<[Post]> {

        let apiDataProvider = APIDataProvider()
        return get(forceFromAPI: forceFromAPI,
                   databaseFetch: DatabaseHelper.instance.getPosts,
                   apiFetch: apiDataProvider.getAndCachePostsFromAPI)
    }

    private func get<Type>(
        forceFromAPI: Bool,
        databaseFetch: @escaping () -> Observable<[Type]>,
        apiFetch: @escaping () -> Observable<[Type]>) -> Observable<[Type]> {

        if forceFromAPI {
            return apiFetch()
        }
        return databaseFetch()
            .flatMap({ (items) -> Observable<[Type]> in
                if items.isEmpty {
                    return apiFetch()
                }
                return .just(items)
            })
    }
}

class APIDataProvider {

    func getAndCachePostsFromAPI() -> Observable<[Post]> {
        return get(url: URL(string: URLFactory.postsUrlString)!)
            .do(afterNext: { posts in
                DatabaseHelper.instance.cachePosts(posts)
            })
    }

    func getUsers() -> Observable<[User]> {
        return get(url: URL(string: URLFactory.usersUrlString)!)
            .do(afterNext: { users in
                DatabaseHelper.instance.cacheUsers(users)
            })
    }

    func getComments() -> Observable<[Comment]> {
        return get(url: URL(string: URLFactory.comments)!)
            .do(afterNext: { comments in
                DatabaseHelper.instance.cacheComments(comments)
            })
    }

    private func get<Model: Decodable>(url: URL) -> Observable<[Model]> {
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
