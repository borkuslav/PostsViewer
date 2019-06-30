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

class PostsViewModelTests: XCTestCase {

    var scheduler: TestScheduler!
    var disposeBag: DisposeBag!

    var viewModel: PostsViewModel!
    private var postsProvider: PostsProviderFake!

    override func setUp() {
        scheduler = TestScheduler(initialClock: 0)
        disposeBag = DisposeBag()

        postsProvider = PostsProviderFake()
        viewModel = PostsViewModel(postsProvider: postsProvider)
    }

    func test_RefreshPosts_OnPostsLoaded_EmitsPosts() {
        onPostsLoaded_EmitPosts(observer: viewModel.refreshPosts)
    }

    func test_ViewDidLoad_OnPostsLoaded_EmitsPosts() {
        onPostsLoaded_EmitPosts(observer: viewModel.refreshPosts)
    }

    private func onPostsLoaded_EmitPosts(observer: AnyObserver<Void>) {

        let postsList = emitNextPosts(atTestTime: 10)

        let posts = createPostsObserver(forPosts: postsList)

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

        _ = emitErrorPosts(atTestTime: 10, error: FakeError.error)

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

    func test_RefreshPosts_OnPostLoaded_ClearErrorText() {
        onPostsLoaded_ClearErrorText(observer: viewModel.refreshPosts)
    }

    private func onPostsLoaded_ClearErrorText(observer: AnyObserver<Void>) {

        _ = emitNextPosts(atTestTime: 10)

        let errorText = createErrorTextObserver()

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

        _ = emitErrorPosts(atTestTime: 10, error: error)

        let errorText = createErrorTextObserver()

        fakeEvent(observer: viewModel.refreshPosts, atTestTime: 0)
        scheduler.start()

        XCTAssertEqual(errorText.events, [
            .next(0, ""),
            .next(10, error.localizedDescription + "\nPull down to refresh")
        ])
    }

    func test_RefreshPosts_OnPostsLoaded_HideLoadingView() {
        _ = emitNextPosts(atTestTime: 10)
        test_OnPostsLoadedOrFail_HideLoadingView(
            observer: viewModel.refreshPosts,
            expectedEvents: [ .next(10, false) ])
    }

    func test_ViewDidLoad_OnPostsLoaded_HideLoadingView() {
        _ = emitNextPosts(atTestTime: 10)
        test_OnPostsLoadedOrFail_HideLoadingView(
            observer: viewModel.viewDidLoad,
            expectedEvents: [
                .next(0, true),
                .next(10, false)
            ])
    }

    func test_RefreshPosts_OnPostsLoadFail_HideLoadingView() {
        emitErrorPosts(atTestTime: 10, error: NetworkError.operationFailedPleaseRetry)
        test_OnPostsLoadedOrFail_HideLoadingView(
            observer: viewModel.refreshPosts,
            expectedEvents: [ .next(10, false) ])
    }

    func test_ViewDidLoad_OnPostsLoadFail_HideLoadingView() {
        emitErrorPosts(atTestTime: 10, error: NetworkError.operationFailedPleaseRetry)
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

        let loadingViewVisible = createLoadingViewVisibleObserver()

        fakeEvent(observer: observer, atTestTime: 0)
        scheduler.start()

        XCTAssertEqual(loadingViewVisible.events, expectedEvents)
    }

    func test_SelectPost_EmitPost() {

        let post = TestDataParser().loadAndParsePosts()![0]

        let selectedPost = scheduler.createObserver(Post.self)
        viewModel.selectedPost
            .drive(selectedPost)
            .disposed(by: disposeBag)

        scheduler.createColdObservable([.next(10, post)])
            .bind(to: viewModel.selectPost)
            .disposed(by: disposeBag)
         scheduler.start()

        XCTAssertEqual(selectedPost.events, [.next(10, post)])
    }

    private func emitNextPosts(atTestTime testTime: TestTime) -> [Post] {
        let postsList: [Post] = TestDataParser().loadAndParsePosts()!
        postsProvider.posts = scheduler
            .createColdObservable([.next(testTime, postsList)])
            .asObservable()
        return postsList
    }

    private func emitErrorPosts(atTestTime testTime: TestTime, error: Error) {
        postsProvider.posts = scheduler
            .createColdObservable([.error(testTime, error)])
            .asObservable()
    }

    private func fakeEvent(observer: AnyObserver<Void>, atTestTime testTime: TestTime) {
        scheduler.createColdObservable([.next(testTime, ())])
            .bind(to: observer)
            .disposed(by: disposeBag)
    }

    private func createErrorTextObserver() -> TestableObserver<String> {
        let errorText = scheduler.createObserver(String.self)
        viewModel.errorText
            .drive(errorText)
            .disposed(by: disposeBag)
        return errorText
    }

    private func createLoadingViewVisibleObserver() -> TestableObserver<Bool> {
        let loadingViewVisible = scheduler.createObserver(Bool.self)
        viewModel.loadingViewVisible
            .drive(loadingViewVisible)
            .disposed(by: disposeBag)
        return loadingViewVisible
    }

    private func createPostsObserver(forPosts posts: [Post]) -> TestableObserver<[Post]> {
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

private class PostsProviderFake: PostsProvider {

    var posts: Observable<[Post]>!

    func getPosts() -> Observable<[Post]> {
        return posts
    }
}
