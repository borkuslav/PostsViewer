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


protocol DataProviderType: PostsProvider {

}

final class DataProvider {

    private var apiDataProvider: APIDataProvider
    private var databaseDataProvider: DatabaseDataProvider

    init(apiDataProvider: APIDataProvider, databaseDataProvider: DatabaseDataProvider) {
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
        return get(apiFetch: apiDataProvider.getPosts,
                   cachingFunction: databaseDataProvider.cachePosts,
                   withDatabaseFallback: withDatabaseFallback,
                   databaseFetch: databaseDataProvider.getPosts)
    }
}
