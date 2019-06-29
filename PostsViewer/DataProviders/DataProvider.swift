//
//  DataProvider.swift
//  PostsViewer
//
//  Created by Bogusław Parol on 22/06/2019.
//  Copyright © 2019 Parbo. All rights reserved.
//

import Foundation
import RxSwift

protocol PostsProvider {
    func getPosts(withDatabaseFallback: Bool) -> Observable<[Post]>
}

protocol PostsDetailsProvider {
    func getPostDetails(forPost post: Post) -> Observable<PostDetails>
}

protocol DataProviderType: PostsProvider, PostsDetailsProvider {

}

final class DataProvider {

    private var apiDataProvider: APIDataProviderType
    private var databaseDataProvider: DatabaseDataProvider

    init(apiDataProvider: APIDataProviderType, databaseDataProvider: DatabaseDataProvider) {
        self.apiDataProvider = apiDataProvider
        self.databaseDataProvider = databaseDataProvider
    }

    private func get<Type>(
        apiFetch: @escaping () -> Observable<[Type]>,
        cachingFunction: @escaping ([Type]) -> Void,
        withDatabaseFallback: Bool,
        databaseFetch: @escaping () -> Observable<[Type]>) -> Observable<[Type]> {

        return apiFetch()
            .do(afterNext: { items in
                cachingFunction(items)
            })
            .catchError({ (error) -> Observable<[Type]> in
                if withDatabaseFallback {
                    return databaseFetch()
                        .flatMap { items -> Observable<[Type]> in
                            if items.isEmpty {
                                return .error(error)
                            } else {
                                return .just(items)
                            }
                        }
                }
                return .error(error)
            })
    }
}

extension DataProvider: DataProviderType {

    func getPosts(withDatabaseFallback: Bool) -> Observable<[Post]> {
        return get(
            apiFetch: apiDataProvider.getPosts,
            cachingFunction: databaseDataProvider.cachePosts,
            withDatabaseFallback: withDatabaseFallback,
            databaseFetch: databaseDataProvider.getPosts)
    }

    // FIXME: talk to API creators, API should return 'User' based on 'userId'
    // and '[Comment]' based on 'postId'
    func getPostDetails(forPost post: Post) -> Observable<PostDetails> {
        let user = get(
            apiFetch: apiDataProvider.getUsers,
            cachingFunction: databaseDataProvider.cacheUsers,
            withDatabaseFallback: true,
            databaseFetch: databaseDataProvider.getUsers
        ).map { users in
            return users.first { $0.id == post.userId }
        }

        let comments = get(
            apiFetch: apiDataProvider.getComments,
            cachingFunction: databaseDataProvider.cacheComments,
            withDatabaseFallback: true,
            databaseFetch: databaseDataProvider.getComments
        ).map { comments in
            return comments.filter { $0.postId == post.id }
        }

        return Observable.zip(user, comments)
            .flatMap { (user, comments) -> Observable<PostDetails> in
                if let user = user {
                    return .just(PostDetails(post: post, user: user, comments: comments))
                }
                return .error(NetworkError.operationFailedPleaseRetry)
            }
    }
}
