//
//  DataProvider.swift
//  PostsViewer
//
//  Created by Bogusław Parol on 22/06/2019.
//  Copyright © 2019 Parbo. All rights reserved.
//

import Foundation
import RxSwift

protocol DataProvider {
    func getPosts(withDatabaseFallback: Bool) -> Observable<[Post]>
}

class DataProviderImpl {

    private var apiDataProvider: APIDataProvider
    private var databaseDataProvider: DatabaseDataProvider

    init(apiDataProvider: APIDataProvider, databaseDataProvider: DatabaseDataProvider) {
        self.apiDataProvider = apiDataProvider
        self.databaseDataProvider = databaseDataProvider
    }

    private func get<Type>(
        withDatabaseFallback: Bool,
        databaseFetch: @escaping () -> Observable<[Type]>,
        apiFetch: @escaping () -> Observable<[Type]>) -> Observable<[Type]> {

        return apiFetch()
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

extension DataProviderImpl: DataProvider {
    func getPosts(withDatabaseFallback: Bool) -> Observable<[Post]> {
        return get(withDatabaseFallback: withDatabaseFallback,
                   databaseFetch: databaseDataProvider.getPosts,
                   apiFetch: apiDataProvider.getAndCachePostsFromAPI)
    }
}
