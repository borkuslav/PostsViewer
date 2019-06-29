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
    func getPosts() -> Observable<[Post]>
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
}

extension DataProvider: DataProviderType {

    func getPosts() -> Observable<[Post]> {
        return apiDataProvider
            .getPosts()
            .do(afterNext: { [weak self] posts in
                self?.databaseDataProvider.cachePosts(posts)
            }).catchError({ [weak self] error -> Observable<[Post]> in
                guard let self = self else {
                    return .error(error)
                }
                return self.databaseDataProvider
                    .getPosts()
                    .flatMap({ posts -> Observable<[Post]> in
                        if posts.isEmpty {
                            return .error(error)
                        }
                        return .just(posts)
                    })
            })
    }

    func getPostDetails(forPost post: Post) -> Observable<PostDetails> {
        let user = apiDataProvider
            .getUser(forUserId: post.userId)
            .do(afterNext: { [weak self] user in
                self?.databaseDataProvider.cacheUser(user)
            }).catchError { [weak self] error -> Observable<User> in
                guard let self = self else {
                    return .error(error)
                }
                return self.databaseDataProvider
                    .getUser(forUserId: post.userId)
                    .flatMap({ user -> Observable<User> in
                        if let user = user {
                            return .just(user)
                        }
                        return .error(PostDetailsError.missingUser)
                    })
            }
        let comments = apiDataProvider
            .getComments(forPostId: post.id)
            .do(afterNext: { [weak self] comments in
                self?.databaseDataProvider.cacheComments(comments)
            }).catchError { [weak self] error -> Observable<[Comment]> in
                guard let self = self else {
                    return .error(error)
                }
                return self.databaseDataProvider.getComments(forPostId: post.id)
            }

        return Observable.zip(user, comments)
            .flatMap { (user, comments) -> Observable<PostDetails> in
                return .just(PostDetails(post: post, user: user, comments: comments))
            }.catchError({ (error) -> Observable<PostDetails> in
                return .error(error)
            })
    }
}
