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

class DataProviderTests: XCTestCase {

    var scheduler: TestScheduler!
    var disposeBag: DisposeBag!

    var dataProvider: DataProvider!
    var apiDataProvider: FakeAPIDataProvider!
    var databaseDataProvider: FakeDatabaseDataProvider!

    override func setUp() {
        scheduler = TestScheduler(initialClock: 0)
        disposeBag = DisposeBag()

        apiDataProvider = FakeAPIDataProvider()
        databaseDataProvider = FakeDatabaseDataProvider()

        dataProvider = DataProvider(
            apiDataProvider: apiDataProvider,
            databaseDataProvider: databaseDataProvider)
    }

    func test_LoadPostsFromAPI_OnSuccess_EmitPosts() {
        let postsList: [Post] = TestDataParser().loadAndParsePosts()!
        apiDataProvider.posts = scheduler
            .createColdObservable([.next(10, postsList)])
            .asObservable()

        runTestAndCheckGetPostResults(withFallback: true, expected: [.next(10, postsList)])
    }

    func test_FailLoadingPostsFromAPI_WithoutDatabaseFallback_EmitError() {
        let error = NetworkError.operationFailedPleaseRetry
        apiDataProvider.posts = scheduler
            .createColdObservable([.error(10, error)])
            .asObservable()

        runTestAndCheckGetPostResults(withFallback: false, expected: [.error(10, error)])
    }

    func test_FailLoadingPostsFromAPI_WithDatabaseFallback_WhenNoCachedPosts_EmitError() {
        let error = NetworkError.operationFailedPleaseRetry
        apiDataProvider.posts = scheduler
            .createColdObservable([.error(10, error)])
            .asObservable()
        databaseDataProvider.posts = scheduler
            .createColdObservable([.next(20, [])])
            .asObservable()

        runTestAndCheckGetPostResults(withFallback: true, expected: [.error(30, error)])
    }

    func test_FailLoadingPostsFromAPI_WithDatabaseFallback_WhenCachedPostsAvailable_EmitPosts() {
        let error = NetworkError.operationFailedPleaseRetry
        let postsList = TestDataParser().loadAndParsePosts()!

        apiDataProvider.posts = scheduler
            .createColdObservable([.error(10, error)])
            .asObservable()
        databaseDataProvider.posts = scheduler
            .createColdObservable([.next(20, postsList)])
            .asObservable()

        runTestAndCheckGetPostResults(withFallback: true, expected: [.next(30, postsList)])
    }

    private func runTestAndCheckGetPostResults(withFallback: Bool, expected: [Recorded<Event<[Post]>>]) {

        let posts = scheduler.createObserver([Post].self)
        dataProvider.getPosts(withDatabaseFallback: withFallback)
            .bind(to: posts)
            .disposed(by: disposeBag)

        scheduler.start()

        XCTAssertEqual(posts.events, expected)
    }

    func test_LoadPostsFromAPI_OnSuccess_CacheData() {

        let cachePosts = scheduler.createObserver([Post].self)
        databaseDataProvider.cachePosts
            .asObservable()
            .bind(to: cachePosts)
            .disposed(by: disposeBag)

        let postsList = TestDataParser().loadAndParsePosts()!
        apiDataProvider.posts = scheduler
            .createColdObservable([.next(20, postsList)])
            .asObservable()

        dataProvider.getPosts(withDatabaseFallback: true)
            .subscribe()
            .disposed(by: disposeBag)

        scheduler.start()

        XCTAssertEqual(cachePosts.events, [.next(20, postsList)])
    }

    func test_FailLoadingPostsFromAPI_DontCacheData() {

        let cachePosts = scheduler.createObserver([Post].self)
        databaseDataProvider.cachePosts
            .asObservable()
            .bind(to: cachePosts)
            .disposed(by: disposeBag)

        let error = NetworkError.loadingResourceFailed(404)
        apiDataProvider.posts = scheduler
            .createColdObservable([.error(20, error)])
            .asObservable()

        dataProvider.getPosts(withDatabaseFallback: false)
            .subscribe()
            .disposed(by: disposeBag)

        scheduler.start()

        XCTAssertEqual(cachePosts.events, [])
    }
}

class FakeAPIDataProvider: APIDataProvider {

    var posts: Observable<[Post]>!
    var users: Observable<[User]>!
    var comments: Observable<[Comment]>!

    func getPosts() -> Observable<[Post]> {
        return posts
    }

    func getUsers() -> Observable<[User]> {
        return users
    }

    func getComments() -> Observable<[Comment]> {
        return comments
    }
}

class FakeDatabaseDataProvider: DatabaseDataProvider {

    var posts: Observable<[Post]>!

    func getPosts() -> Observable<[Post]> {
        return posts
    }

    var cachePosts = PublishSubject<[Post]>()

    func cachePosts(_ posts: [Post]) {
        cachePosts.onNext(posts)
    }
}
