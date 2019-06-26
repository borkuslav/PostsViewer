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
class PostsViewModelTests: XCTestCase {

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

    func test_RefreshPosts_OnPostsLoaded_EmitsPosts() {
        onPostsLoaded_EmitPosts(observer: viewModel.refreshPosts)
    }

    func test_ViewDidLoad_OnPostsLoaded_EmitsPosts() {
        onPostsLoaded_EmitPosts(observer: viewModel.refreshPosts)
    }

    private func onPostsLoaded_EmitPosts(observer: AnyObserver<Void>) {

        let postsList = prepareDataProviderToSuccess(emitPostsAtTestTime: 10)

        let posts = scheduler.createObserver(Array<Post>.self)
        viewModel.posts
            .drive(posts)
            .disposed(by: disposeBag)

        fakeEvent(observer: observer, atTestTime: 0)
        scheduler.start()

        XCTAssertEqual(posts.events, [ .next(10, postsList)])
    }

    func test_RefreshPosts_OnPostsLoadFail_EmitsEmptyPosts() {
        onPostsLoadFail_EmitEmptyPosts(observer: viewModel.refreshPosts)
    }

    func test_ViewDidLoad_OnPostsLoadFail_EmitsEmptyPosts() {
        onPostsLoadFail_EmitEmptyPosts(observer: viewModel.viewDidLoad)
    }

    private func onPostsLoadFail_EmitEmptyPosts(observer: AnyObserver<Void>) {

        _ = prepareDataProviderToFailure(emitPostsAtTestTime: 10, error: FakeError.error)

        let posts = scheduler.createObserver(Array<Post>.self)
        viewModel.posts
            .drive(posts)
            .disposed(by: disposeBag)

        fakeEvent(observer: observer, atTestTime: 0)
        scheduler.start()

        XCTAssertEqual(posts.events, [ .next(10, [])])
    }

    func test_ViewDidLoad_OnPostLoaded_ClearErrorText() {
        onPostsLoaded_ClearErrorText(observer: viewModel.viewDidLoad)
    }

    func test_RefreshPostsOnPostLoadedClearErrorText() {
        onPostsLoaded_ClearErrorText(observer: viewModel.refreshPosts)
    }

    private func onPostsLoaded_ClearErrorText(observer: AnyObserver<Void>) {

        _ = prepareDataProviderToSuccess(emitPostsAtTestTime: 10)

        let errorText = scheduler.createObserver(String.self)
        viewModel.errorText
            .drive(errorText)
            .disposed(by: disposeBag)

        fakeEvent(observer: viewModel.refreshPosts, atTestTime: 0)
        scheduler.start()

        XCTAssertEqual(errorText.events, [
            .next(0, ""),
            .next(10, "")
        ])
    }

    func test_ViewDidLoad_OnPostLoadFail_EmitErrorText() {
        onPostLoadFail_EmitErrorText(
            observer: viewModel.viewDidLoad,
            error: NetworkError.operationFailedPleaseRetry)
    }

    func test_RefreshPosts_OnPostLoadFail_EmitErrorText() {
        onPostLoadFail_EmitErrorText(
            observer: viewModel.refreshPosts,
            error: NetworkError.loadingResourceFailed(404))
    }

    private func onPostLoadFail_EmitErrorText(observer: AnyObserver<Void>, error: Error) {

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
            .next(0, ""),
            .next(10, error.localizedDescription + "\nPull down to refresh")
        ])
    }

    func test_RefreshPosts_OnPostsLoaded_HideLoadingView() {
        _ = prepareDataProviderToSuccess(emitPostsAtTestTime: 10)
        test_OnPostsLoadedOrFail_HideLoadingView(
            observer: viewModel.refreshPosts,
            expectedEvents: [ .next(10, false) ])
    }

    func test_ViewDidLoad_OnPostsLoaded_HideLoadingView() {
        _ = prepareDataProviderToSuccess(emitPostsAtTestTime: 10)
        test_OnPostsLoadedOrFail_HideLoadingView(
            observer: viewModel.viewDidLoad,
            expectedEvents: [
                .next(0, true),
                .next(10, false)
            ])
    }

    func test_RefreshPosts_OnPostsLoadFail_HideLoadingView() {
        prepareDataProviderToFailure(emitPostsAtTestTime: 10, error: NetworkError.operationFailedPleaseRetry)
        test_OnPostsLoadedOrFail_HideLoadingView(
            observer: viewModel.refreshPosts,
            expectedEvents: [ .next(10, false) ])
    }

    func test_ViewDidLoad_OnPostsLoadFail_HideLoadingView() {
        prepareDataProviderToFailure(emitPostsAtTestTime: 10, error: NetworkError.operationFailedPleaseRetry)
        test_OnPostsLoadedOrFail_HideLoadingView(
            observer: viewModel.viewDidLoad,
            expectedEvents: [
                .next(0, true),
                .next(10, false)
            ])
    }

    private func test_OnPostsLoadedOrFail_HideLoadingView(
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

    func test_RefreshPosts_NotUseDatabaseFallback() {
        test_UseDatabaseFallback(observer: viewModel.refreshPosts, shouldUseDatabaseFallback: false)
    }

    func test_ViewDidLoad_UseDatabaseFallback() {
        test_UseDatabaseFallback(observer: viewModel.viewDidLoad, shouldUseDatabaseFallback: true)
    }

    private func test_UseDatabaseFallback(observer: AnyObserver<()>, shouldUseDatabaseFallback: Bool) {
        let postsList = prepareDataProviderToSuccess(emitPostsAtTestTime: 10)

        _ = createPostsTestableObserver(forPosts: postsList)

        let withDatabaseFallback = scheduler.createObserver(Bool.self)
        dataProvider.withDatabaseFallback.asObservable()
            .bind(to: withDatabaseFallback)
            .disposed(by: disposeBag)

        fakeEvent(observer: observer, atTestTime: 0)
        scheduler.start()

        XCTAssertEqual(withDatabaseFallback.events, [.next(0, shouldUseDatabaseFallback)])
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

    var withDatabaseFallback = PublishSubject<Bool>()

    func getPosts(withDatabaseFallback: Bool) -> Observable<[Post]> {
        self.withDatabaseFallback.onNext(withDatabaseFallback)
        return posts
    }
}
