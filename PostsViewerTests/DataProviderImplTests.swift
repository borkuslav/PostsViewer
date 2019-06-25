//
//  PostsTests.swift
//  PostsViewerTests
//
//  Created by Bogusław Parol on 24/06/2019.
//  Copyright © 2019 Parbo. All rights reserved.
//

import Foundation
import XCTest
import RxCocoa
import RxSwift
import RxTest
import RxBlocking

@testable import PostsViewer

/* What to test?
 - on [refreshPosts] / on [viewDidLoad]
    -> should call [DataProvider.getPosts]
    -> should emit [posts] on success
    -> should emit [errorText] before request and after
    -> should emit [loadingViewVisible:false] before request and after
    -> should emit [hideRefreshIndicator] after request
 - on [viewDidLoad]
    -> should emit [loadingViewVisible:true]

 */
class DataProviderImplTests: XCTestCase {

    var scheduler: TestScheduler!
    var disposeBag: DisposeBag!

    var dataProvider: DataProviderImpl!
    var apiDataProvider: FakeAPIDataProvider!
    var databaseDataProvider: FakeDatabaseDataProvider!

    override func setUp() {
        scheduler = TestScheduler(initialClock: 0)
        disposeBag = DisposeBag()

        apiDataProvider = FakeAPIDataProvider()
        databaseDataProvider = FakeDatabaseDataProvider()

        dataProvider = DataProviderImpl(
            apiDataProvider: apiDataProvider,
            databaseDataProvider: databaseDataProvider)
    }

    func test_LoadPostsFromAPI_WithSuccess() {
        let postsList: [Post] = TestDataParser().loadAndParsePosts()!

        
    }

    func test_FailLoadingPostsFromAPI_WithoutDatabaseFallback() {

    }

    func test_FailLoadingPostsFromAPI_WithDatabaseFallback_WhenNoCachedPosts() {

    }

    func test_FailLoadingPostsFromAPI_WithDatabaseFallback_WhenCachedPostsAvailable() {

    }
}

class FakeAPIDataProvider: APIDataProvider {

    var posts: Observable<[Post]>!
    var users: Observable<[User]>!
    var comments: Observable<[Comment]>!

    func getAndCachePostsFromAPI() -> Observable<[Post]> {
        return posts
    }

    func getAndCacheUsersFromAPI() -> Observable<[User]> {
        return users
    }

    func getAndCacheCommentsFromAPI() -> Observable<[Comment]> {
        return comments
    }
}

class FakeDatabaseDataProvider: DatabaseDataProvider {

    var posts: Observable<[Post]>!

    func getPosts() -> Observable<[Post]> {
        return posts
    }
}
