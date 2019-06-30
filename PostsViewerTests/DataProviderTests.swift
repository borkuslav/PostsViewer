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
        apiEmitNextPosts(postsList, atTestTime: 10)

        runGetPostsAndCheckResults(expected: [.next(10, postsList)])
    }

    func test_FailLoadingPostsFromAPI_WhenNoCachedPosts_EmitError() {

        let error = NetworkError.operationFailedPleaseRetry
        apiEmitErrorPosts(error, atTestTime: 10)

        databaseEmitNextPosts([], atTestTime: 20)

        runGetPostsAndCheckResults(expected: [.error(30, error)])
    }

    func test_FailLoadingPostsFromAPI_WhenCachedPostsAvailable_EmitPosts() {

        let error = NetworkError.operationFailedPleaseRetry
        apiEmitErrorPosts(error, atTestTime: 10)

        let postsList = TestDataParser().loadAndParsePosts()!
        databaseEmitNextPosts(postsList, atTestTime: 20)

        runGetPostsAndCheckResults(expected: [.next(30, postsList)])
    }

    private func runGetPostsAndCheckResults(expected: [Recorded<Event<[Post]>>]) {

        let posts = scheduler.createObserver([Post].self)
        dataProvider.getPosts()
            .bind(to: posts)
            .disposed(by: disposeBag)

        scheduler.start()

        XCTAssertEqual(posts.events, expected)
    }

    func test_LoadPostsFromAPI_OnSuccess_CacheData() {

        let cachePosts = createCachePostsObserver()

        let postsList = TestDataParser().loadAndParsePosts()!

        apiEmitNextPosts(postsList, atTestTime: 20)

        dataProvider.getPosts()
            .subscribe()
            .disposed(by: disposeBag)

        scheduler.start()

        XCTAssertEqual(cachePosts.events, [.next(20, postsList)])
    }

    func test_FailLoadingPostsFromAPI_DontCacheData() {

        databaseEmitNextPosts([], atTestTime: 0)

        let cachePosts = createCachePostsObserver()

        let error = NetworkError.loadingResourceFailed(404)
        apiEmitErrorPosts(error, atTestTime: 20)

        dataProvider.getPosts()
            .subscribe()
            .disposed(by: disposeBag)

        scheduler.start()

        XCTAssertEqual(cachePosts.events, [])
    }

    private func createCachePostsObserver() -> TestableObserver<[Post]> {
        let cachePosts = scheduler.createObserver([Post].self)
        databaseDataProvider.cachePosts
            .asObservable()
            .bind(to: cachePosts)
            .disposed(by: disposeBag)
        return cachePosts
    }

    private func databaseEmitNextPosts(_ posts: [Post], atTestTime testTime: TestTime) {
        databaseDataProvider.posts = scheduler
            .createColdObservable([.next(testTime, posts)])
            .asObservable()
    }

    private func databaseEmitErrorPosts(_ error: Error, atTestTime testTime: TestTime) {
        databaseDataProvider.posts = scheduler
            .createColdObservable([.error(testTime, error)])
            .asObservable()
    }

    private func apiEmitNextPosts(_ posts: [Post], atTestTime testTime: TestTime) {
        apiDataProvider.posts = scheduler
            .createColdObservable([.next(testTime, posts)])
            .asObservable()
    }

    private func apiEmitErrorPosts(_ error: Error, atTestTime testTime: TestTime) {
        apiDataProvider.posts = scheduler
            .createColdObservable([.error(testTime, error)])
            .asObservable()
    }
}

class FakeAPIDataProvider: APIDataProviderType {

    var posts: Observable<[Post]>!
    func getPosts() -> Observable<[Post]> {
        return posts
    }

    var user: Observable<User>!
    func getUser(forUserId userId: Int) -> Observable<User> {
        return user
    }

    var comments: Observable<[Comment]>!
    func getComments(forPostId postId: Int) -> Observable<[Comment]> {
        return comments
    }
}

class FakeDatabaseDataProvider: DatabaseDataProviderType {

    var posts: Observable<[Post]>!
    func getPosts() -> Observable<[Post]> {
        return posts
    }

    var cachePosts = PublishSubject<[Post]>()
    func cachePosts(_ posts: [Post]) {
        cachePosts.onNext(posts)
    }

    var user: Observable<User?>!
    func getUser(forUserId userId: Int) -> Observable<User?> {
        return user
    }

    var cacheUser = PublishSubject<User>()
    func cacheUser(_ user: User) {
        cacheUser.onNext(user)
    }

    var comments: Observable<[Comment]>!
    func getComments(forPostId postId: Int) -> Observable<[Comment]> {
        return comments
    }

    var cacheComments = PublishSubject<[Comment]>()
    func cacheComments(_ comments: [Comment]) {
        cacheComments.onNext(comments)
    }
}
