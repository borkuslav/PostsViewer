//
//  APIDataProvider.swift
//  PostsViewer
//
//  Created by Bogusław Parol on 24/06/2019.
//  Copyright © 2019 Parbo. All rights reserved.
//

import Foundation
import RxSwift

protocol APIDataProvider {
    func getAndCachePostsFromAPI() -> Observable<[Post]>
    func getAndCacheUsersFromAPI() -> Observable<[User]>
    func getAndCacheCommentsFromAPI() -> Observable<[Comment]>
}

class APIDataProviderImp {

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
            }.catchError { _ in .error(NetworkError.operationFailedPleaseRetry) }
    }
}

extension APIDataProviderImp: APIDataProvider {

    func getAndCachePostsFromAPI() -> Observable<[Post]> {
        return get(url: URL(string: Constants.postsUrlString)!)
            .do(afterNext: { posts in
                DatabaseHelper.instance.cachePosts(posts)
            })
    }

    func getAndCacheUsersFromAPI() -> Observable<[User]> {
        return get(url: URL(string: Constants.usersUrlString)!)
            .do(afterNext: { users in
                DatabaseHelper.instance.cacheUsers(users)
            })
    }

    func getAndCacheCommentsFromAPI() -> Observable<[Comment]> {
        return get(url: URL(string: Constants.commentsUrlString)!)
            .do(afterNext: { comments in
                DatabaseHelper.instance.cacheComments(comments)
            })
    }
}
