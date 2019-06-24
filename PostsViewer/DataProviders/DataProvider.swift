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
    func getPosts(forceFromAPI: Bool) -> Observable<[Post]>
}

class DataProviderImpl {

    private var apiDataProvider: APIDataProvider
    private var databaseDataProvider: DatabaseDataProvider

    init(apiDataProvider: APIDataProvider, databaseDataProvider: DatabaseDataProvider) {
        self.apiDataProvider = apiDataProvider
        self.databaseDataProvider = databaseDataProvider
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

extension DataProviderImpl: DataProvider {
    func getPosts(forceFromAPI: Bool) -> Observable<[Post]> {
        return get(forceFromAPI: forceFromAPI,
                   databaseFetch: databaseDataProvider.getPosts,
                   apiFetch: apiDataProvider.getAndCachePostsFromAPI)
    }
}
