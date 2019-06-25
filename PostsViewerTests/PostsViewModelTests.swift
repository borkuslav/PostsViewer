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
class PostsTests: XCTestCase {

    var scheduler: TestScheduler!
    var disposeBag: DisposeBag!

    var viewModel: PostsViewModel!
    private var dataProvider: DataProviderFake!

    override func setUp() {
        scheduler = TestScheduler(initialClock: 0)
        disposeBag = DisposeBag()

        dataProvider = DataProviderFake()
        viewModel = PostsViewModel(dataProvider: dataProvider)
    }

    func test_RefreshPostsOnPostsLoadedEmitsPosts() {
        testOnPostsLoadedEmitPosts(observer: viewModel.refreshPosts)
    }

    func test_ViewDidLoadOnPostsLoadedEmitsPosts() {
        testOnPostsLoadedEmitPosts(observer: viewModel.refreshPosts)
    }

    func testOnPostsLoadedEmitPosts(observer: AnyObserver<Void>) {

        let postsList = prepareDataProviderToSuccess(emitPostsAtTestTime: 10)

        let posts = scheduler.createObserver(Array<Post>.self)
        viewModel.posts
            .drive(posts)
            .disposed(by: disposeBag)

        fakeEvent(observer: observer, atTestTime: 0)
        scheduler.start()

        XCTAssertEqual(posts.events, [ Recorded.next(10, postsList)])
    }

    func test_RefreshPostsOnPostsLoadFailEmitsEmptyPosts() {
        testOnPostsLoadFailEmitEmptyPosts(observer: viewModel.refreshPosts)
    }

    func test_ViewDidLoadOnPostsLoadFailEmitsEmptyPosts() {
        testOnPostsLoadFailEmitEmptyPosts(observer: viewModel.viewDidLoad)
    }

    private func testOnPostsLoadFailEmitEmptyPosts(observer: AnyObserver<Void>) {

        _ = prepareDataProviderToFailure(emitPostsAtTestTime: 10, error: FakeError.error)

        let posts = scheduler.createObserver(Array<Post>.self)
        viewModel.posts
            .drive(posts)
            .disposed(by: disposeBag)

        fakeEvent(observer: observer, atTestTime: 0)
        scheduler.start()

        XCTAssertEqual(posts.events, [ Recorded.next(10, [])])
    }

    func test_ViewDidLoadOnPostLoadedClearErrorText() {
        testOnPostsLoadedClearErrorText(observer: viewModel.viewDidLoad)
    }

    func test_RefreshPostsOnPostLoadedClearErrorText() {
        testOnPostsLoadedClearErrorText(observer: viewModel.refreshPosts)
    }

    private func testOnPostsLoadedClearErrorText(observer: AnyObserver<Void>) {

        _ = prepareDataProviderToSuccess(emitPostsAtTestTime: 10)

        let errorText = scheduler.createObserver(String.self)
        viewModel.errorText
            .drive(errorText)
            .disposed(by: disposeBag)

        fakeEvent(observer: viewModel.refreshPosts, atTestTime: 0)
        scheduler.start()

        XCTAssertEqual(errorText.events, [
            Recorded.next(0, ""),
            Recorded.next(10, "")
        ])
    }

    func test_ViewDidLoadOnPostLoadFailEmitErrorText() {
        testPostLoadFailEmitErrorText(
            observer: viewModel.viewDidLoad,
            error: NetworkError.operationFailedPleaseRetry)
    }

    func test_RefreshPostsOnPostLoadFailEmitErrorText() {
        testPostLoadFailEmitErrorText(
            observer: viewModel.refreshPosts,
            error: NetworkError.loadingResourceFailed(404))
    }

    private func testPostLoadFailEmitErrorText(observer: AnyObserver<Void>, error: Error) {

        _ = prepareDataProviderToFailure(
            emitPostsAtTestTime: 10,
            error: error)

        let errorText = scheduler.createObserver(String.self)
        viewModel.errorText
            .drive(errorText)
            .disposed(by: disposeBag)

        fakeEvent(observer: viewModel.refreshPosts, atTestTime: 0)
        scheduler.start()

        XCTAssertEqual(errorText.events, [
            Recorded.next(0, ""),
            Recorded.next(10, error.localizedDescription + "\nPull down to refresh")
        ])
    }

    func test_RefreshPostsOnPostsLoadedHideLoadingView() {
        _ = prepareDataProviderToSuccess(emitPostsAtTestTime: 10)
        testOnPostsLoadedOrFailHideLoadingView(
            observer: viewModel.refreshPosts,
            expectedEvents: [ .next(10, false) ])
    }

    func test_ViewDidLoadOnPostsLoadedHideLoadingView() {
        _ = prepareDataProviderToSuccess(emitPostsAtTestTime: 10)
        testOnPostsLoadedOrFailHideLoadingView(
            observer: viewModel.viewDidLoad,
            expectedEvents: [
                .next(0, true),
                .next(10, false)
            ])
    }

    func test_RefreshPostsOnPostsLoadFailHideLoadingView() {
        prepareDataProviderToFailure(emitPostsAtTestTime: 10, error: NetworkError.operationFailedPleaseRetry)
        testOnPostsLoadedOrFailHideLoadingView(
            observer: viewModel.refreshPosts,
            expectedEvents: [ .next(10, false) ])
    }

    func test_ViewDidLoadOnPostsLoadFailHideLoadingView() {
        prepareDataProviderToFailure(emitPostsAtTestTime: 10, error: NetworkError.operationFailedPleaseRetry)
        testOnPostsLoadedOrFailHideLoadingView(
            observer: viewModel.viewDidLoad,
            expectedEvents: [
                .next(0, true),
                .next(10, false)
            ])
    }

    private func testOnPostsLoadedOrFailHideLoadingView(
        observer: AnyObserver<()>,
        expectedEvents: [Recorded<Event<Bool>>]) {

        let loadingViewVisible = scheduler.createObserver(Bool.self)
        viewModel.loadingViewVisible
            .drive(loadingViewVisible)
            .disposed(by: disposeBag)

        fakeEvent(observer: observer, atTestTime: 0)
        scheduler.start()

        XCTAssertEqual(loadingViewVisible.events, expectedEvents)
    }

    func test_RefreshPostsForcesAPICall() {
        testForcesAPICall(observer: viewModel.refreshPosts, shouldForce: true)
    }

    func test_ViewDidLoadNotForcesAPICall() {
        testForcesAPICall(observer: viewModel.viewDidLoad, shouldForce: false)
    }

    private func testForcesAPICall(observer: AnyObserver<()>, shouldForce: Bool) {
        let postsList = prepareDataProviderToSuccess(emitPostsAtTestTime: 10)

        _ = createPostsTestableObserver(forPosts: postsList)

        let forceFromAPI = scheduler.createObserver(Bool.self)
        dataProvider.forceFromAPI.asObservable()
            .bind(to: forceFromAPI)
            .disposed(by: disposeBag)

        fakeEvent(observer: observer, atTestTime: 0)
        scheduler.start()

        XCTAssertEqual(forceFromAPI.events, [.next(0, shouldForce)])
    }

    private func prepareDataProviderToSuccess(emitPostsAtTestTime testTime: TestTime) -> [Post] {
        let postsList: [Post] = TestDataParser().loadAndParsePosts()!
        dataProvider.posts = scheduler
            .createColdObservable([.next(testTime, postsList)])
            .asObservable()
        return postsList
    }

    private func prepareDataProviderToFailure(emitPostsAtTestTime testTime: TestTime, error: Error) {
        dataProvider.posts = scheduler
            .createColdObservable([.error(testTime, error)])
            .asObservable()
    }

    private func fakeEvent(observer: AnyObserver<Void>, atTestTime testTime: TestTime) {
        scheduler.createColdObservable([.next(testTime, ())])
            .bind(to: observer)
            .disposed(by: disposeBag)
    }

    private func createPostsTestableObserver(forPosts posts: [Post]) -> TestableObserver<[Post]> {
        let observer = scheduler.createObserver(Array<Post>.self)
        viewModel.posts
            .drive(observer)
            .disposed(by: disposeBag)
        return observer
    }
}

private enum FakeError: Error {
    case error
}

private class DataProviderFake: DataProvider {

    var posts: Observable<[Post]>!

    var forceFromAPI = PublishSubject<Bool>()

    func getPosts(forceFromAPI: Bool) -> Observable<[Post]> {
        self.forceFromAPI.onNext(forceFromAPI)
        return posts
    }
}
