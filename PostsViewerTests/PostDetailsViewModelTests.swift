//
//  PostDetailsViewModelTests.swift
//  PostsViewerTests
//
//  Created by Bogusław Parol on 28/06/2019.
//  Copyright © 2019 Parbo. All rights reserved.
//

import Foundation
import XCTest
import RxCocoa
import RxSwift
import RxTest
import RxBlocking

@testable import PostsViewer

// Emits postDetails on success
// Emits error on failure ?

class PostDetailsViewModelTests: XCTestCase {

    var scheduler: TestScheduler!
    var disposeBag: DisposeBag!

    var viewModel: PostDetailsViewModel!
    private var dataProvider: PostDetailsProviderFake!

    override func setUp() {
        scheduler = TestScheduler(initialClock: 0)
        disposeBag = DisposeBag()

        dataProvider = PostDetailsProviderFake()
        let post = BehaviorRelay<Post>(value: TestDataParser().loadAndParsePosts()![0])
        viewModel = PostDetailsViewModel(postsDetailsProvider: dataProvider, post: post)
    }

    func test_ViewDidLoad_ShowPostDetails_OnSuccess_WithCorrectData() {

        let post: Post = TestDataParser().loadAndParsePosts()![0]
        let postDetailsModel = emitNextPostDetailsCorrect(forPost: post, atTestTime: 10)
        let expectedResult = wrapToSectionsViewModels(post: post, postDetailsModel: postDetailsModel)

        viewModel.currentPost.accept(post)

        let postDetails = createPostDetailsObserver()
        let loadingViewVisible = createLoadingViewVisibleObserver()
        let errorText = createErrorTextObserver()

        emitViewDidLoad(atTestTime: 0)

        scheduler.start()

        XCTAssertEqual(postDetails.events, [.next(10, expectedResult)])
        XCTAssertEqual(errorText.events, [.next(10, "")])
        XCTAssertEqual(loadingViewVisible.events, [
            .next(0, true),
            .next(10, false)
        ])
    }

    func test_Reload_ShowPostDetails_OnSuccess_WithCorrectData() {

        let post: Post = TestDataParser().loadAndParsePosts()![0]
        let postDetailsModel = emitNextPostDetailsCorrect(forPost: post, atTestTime: 10)
        let expectedResult = wrapToSectionsViewModels(post: post, postDetailsModel: postDetailsModel)

        viewModel.currentPost.accept(post)

        let postDetails = createPostDetailsObserver()
        let loadingViewVisible = createLoadingViewVisibleObserver()
        let errorText = createErrorTextObserver()

        emitRefresh(atTestTime: 10)

        scheduler.start()

        XCTAssertEqual(postDetails.events, [.next(20, expectedResult)])
        XCTAssertEqual(errorText.events, [
            .next(10, ""),
            .next(20, "")
        ])
        XCTAssertEqual(loadingViewVisible.events, [.next(20, false)])
    }

    func test_ShowPostDetails_OnSuccess_WithIncorrectUser() {

        let post: Post = TestDataParser().loadAndParsePosts()![0]
        _ = self.emitNextPostDetailsWithIncorrectUser(forPost: post, atTestTime: 10)

        let postDetails = createPostDetailsObserver()
        let errorText = createErrorTextObserver()

        emitViewDidLoad(atTestTime: 0)

        viewModel.currentPost.accept(post)

        scheduler.start()

        XCTAssertEqual(postDetails.events, [.next(10, [])])
        XCTAssertEqual(errorText.events, [
            .next(10, "Couldn't load data. \nPlease pull to refresh")
        ])
    }

    func test_ShowPostDetails_OnDetailsLoadingFail() {

        let post: Post = TestDataParser().loadAndParsePosts()![0]
        dataProvider.postDetails = scheduler
            .createColdObservable([.error(20, NetworkError.operationFailedPleaseRetry)])
            .asObservable()

        let postDetails = createPostDetailsObserver()
        let errorText = createErrorTextObserver()

        emitViewDidLoad(atTestTime: 0)

        viewModel.currentPost.accept(post)

        scheduler.start()

        XCTAssertEqual(postDetails.events, [.next(20, [])])
        XCTAssertEqual(errorText.events, [
            .next(20, "Couldn't load data. \nPlease pull to refresh")
        ])
    }

    private func wrapToSectionsViewModels(post: Post, postDetailsModel: PostDetails) -> [PostSectionViewModelType] {
        return [
            .author(PostAuthorViewModel(user: postDetailsModel.user)),
            .content(PostContentViewModel(post: post)),
            .comments(PostCommentsViewModel(comments: postDetailsModel.comments))
        ]
    }

    private func createPostDetailsObserver() -> TestableObserver<[PostSectionViewModelType]> {
        let postDetails = scheduler.createObserver(Array<PostSectionViewModelType>.self)
        viewModel.postDetails
            .drive(postDetails)
            .disposed(by: disposeBag)
        return postDetails
    }

    private func createLoadingViewVisibleObserver() -> TestableObserver<Bool> {
        let loadingViewVisible = scheduler.createObserver(Bool.self)
        viewModel.loadingViewVisible
            .drive(loadingViewVisible)
            .disposed(by: disposeBag)
        return loadingViewVisible
    }

    private func createErrorTextObserver() -> TestableObserver<String> {
        let errorText = scheduler.createObserver(String.self)
        viewModel.errorText
            .drive(errorText)
            .disposed(by: disposeBag)
        return errorText
    }

    private func emitViewDidLoad(atTestTime time: TestTime) {
        scheduler.createColdObservable([.next(time, ())])
            .asObservable()
            .bind(to: viewModel.viewDidLoad)
            .disposed(by: disposeBag)
    }

    private func emitRefresh(atTestTime time: TestTime) {
        scheduler.createColdObservable([.next(time, ())])
            .asObservable()
            .bind(to: viewModel.refresh)
            .disposed(by: disposeBag)
    }

    private func emitNextPostDetailsCorrect(
        forPost post: Post,
        atTestTime testTime: TestTime) -> PostDetails {

        let user = getCorrectUser(forPost: post)
        let comments = getCorrectComments(forPost: post)
        return emitNextPostDetails(
            forPost: post,
            user: user,
            comments: comments,
            emitPostDetailsAtTestTime: testTime)
    }

    private func emitNextPostDetailsWithIncorrectUser(
        forPost post: Post,
        atTestTime testTime: TestTime) -> PostDetails {

        let user = getIncorrectUser(forPost: post)
        let comments = getCorrectComments(forPost: post)
        return emitNextPostDetails(
            forPost: post,
            user: user,
            comments: comments,
            emitPostDetailsAtTestTime: testTime)
    }

    private func emitNextPostDetailsWithIncorrectComments(
        forPost post: Post,
        atTestTime testTime: TestTime) -> PostDetails {

        let user = getCorrectUser(forPost: post)
        let comments = getIncorrectComments(forPost: post)
        return emitNextPostDetails(
            forPost: post,
            user: user,
            comments: comments,
            emitPostDetailsAtTestTime: testTime)
    }

    private func emitNextPostDetails(
        forPost post: Post,
        user: User,
        comments: [Comment],
        emitPostDetailsAtTestTime testTime: TestTime) -> PostDetails {

        let postDetails = PostDetails(
            post: post,
            user: user,
            comments: comments)

        dataProvider.postDetails = scheduler
            .createColdObservable([.next(testTime, postDetails)])
            .asObservable()
        return postDetails
    }

    private func getCorrectUser(forPost post: Post) -> User {
        return TestDataParser().loadAndParseUsers()!
            .first { $0.id == post.userId }!
    }

    private func getIncorrectUser(forPost post: Post) -> User {
        var user = TestDataParser().loadAndParseUsers()![0]
        user.id = -999
        return user
    }

    private func getCorrectComments(forPost post: Post) -> [Comment] {
        return TestDataParser().loadAndParseComments()!
            .filter { comment -> Bool in comment.postId == post.id }
    }

    private func getIncorrectComments(forPost post: Post) -> [Comment] {
        return TestDataParser().loadAndParseComments()!.prefix(50)
            .filter { comment -> Bool in comment.postId != post.id }
    }
}

private class PostDetailsProviderFake: PostsDetailsProvider {

    var postDetails: Observable<PostDetails>!

    func getPostDetails(forPost post: Post) -> Observable<PostDetails> {
        return postDetails
    }
}

extension PostSectionViewModelType: Equatable {

    static public func == (lhs: PostSectionViewModelType, rhs: PostSectionViewModelType) -> Bool {
        switch (lhs, rhs) {
        case (let .content(lvm), let .content(rvm)):
            return lvm == rvm
        case (let .author(lvm), let .author(rvm)):
            return lvm == rvm
        case (let .comments(lvm), let .comments(rvm)):
            return lvm == rvm
        default:
            return false
        }
    }
}

extension PostContentViewModel: Equatable {
    static public func == (lhs: PostContentViewModel, rhs: PostContentViewModel) -> Bool {
        return lhs.post.id == rhs.post.id
    }
}

extension PostAuthorViewModel: Equatable {
    static public func == (lhs: PostAuthorViewModel, rhs: PostAuthorViewModel) -> Bool {
        return lhs.user.id == rhs.user.id
    }
}

extension PostCommentsViewModel: Equatable {
    static public func == (lhs: PostCommentsViewModel, rhs: PostCommentsViewModel) -> Bool {
        return lhs.comments.map { $0.id } == rhs.comments.map { $0.id }
    }
}
