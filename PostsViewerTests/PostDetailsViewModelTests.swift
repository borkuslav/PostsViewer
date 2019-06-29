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
        viewModel = PostDetailsViewModel(postsDetailsProvider: dataProvider)
    }

    func test_ShowPostDetails_OnSuccess_WithCorrectData_EmitPostDetails() {

        let post: Post = TestDataParser().loadAndParsePosts()![0]
        let postDetailsModel = prepareDataProviderToSuccess(forPost: post, emitPostDetailsAtTestTime: 10)
        let expectedResult: [PostSectionViewModelType] = [
            .author(PostAuthorViewModel(user: postDetailsModel.user)),
            .title(PostContentViewModel(post: post)),
            .comments(PostCommentsViewModel(comments: postDetailsModel.comments))
        ]

        let postDetails = scheduler.createObserver(Array<PostSectionViewModelType>.self)
        viewModel.postDetails
            .drive(postDetails)
            .disposed(by: disposeBag)

        let errorText = scheduler.createObserver(String.self)
        viewModel.errorText
            .drive(errorText)
            .disposed(by: disposeBag)

        scheduler.createColdObservable([.next(0, post)])
            .bind(to: viewModel.showPostsDetails)
            .disposed(by: disposeBag)
        scheduler.start()

        XCTAssertEqual(postDetails.events, [.next(10, expectedResult)])
        XCTAssertEqual(errorText.events, [
            .next(0, ""),
            .next(10, "")
        ])
    }

    func test_ShowPostDetails_OnSuccess_WithIncorrectUser() {

        let post: Post = TestDataParser().loadAndParsePosts()![0]
        _ = self.prepareDataProviderToSuccessWithIncorrectUser(forPost: post, emitPostDetailsAtTestTime: 10)

        let postDetails = scheduler.createObserver(Array<PostSectionViewModelType>.self)
        viewModel.postDetails
            .drive(postDetails)
            .disposed(by: disposeBag)

        let errorText = scheduler.createObserver(String.self)
        viewModel.errorText
            .drive(errorText)
            .disposed(by: disposeBag)

        scheduler.createColdObservable([.next(0, post)])
            .bind(to: viewModel.showPostsDetails)
            .disposed(by: disposeBag)
        scheduler.start()

        XCTAssertEqual(postDetails.events, [.next(10, [])])
        XCTAssertEqual(errorText.events, [
            .next(0, ""),
            .next(10, "Couldn't load data. \nPlease pull to refresh")
        ])
    }

    private func prepareDataProviderToSuccess(
        forPost post: Post,
        emitPostDetailsAtTestTime testTime: TestTime) -> PostDetails {

        let user = getCorrectUser(forPost: post)
        let comments = getCorrectComments(forPost: post)
        return prepareDataProviderToSuccess(
            forPost: post,
            user: user,
            comments: comments,
            emitPostDetailsAtTestTime: testTime)
    }

    private func prepareDataProviderToSuccessWithIncorrectUser(
        forPost post: Post,
        emitPostDetailsAtTestTime testTime: TestTime) -> PostDetails {

        let user = getIncorrectUser(forPost: post)
        let comments = getCorrectComments(forPost: post)
        return prepareDataProviderToSuccess(
            forPost: post,
            user: user,
            comments: comments,
            emitPostDetailsAtTestTime: testTime)
    }

    private func prepareDataProviderToSuccessWithIncorrectComments(
        forPost post: Post,
        emitPostDetailsAtTestTime testTime: TestTime) -> PostDetails {

        let user = getCorrectUser(forPost: post)
        let comments = getIncorrectComments(forPost: post)
        return prepareDataProviderToSuccess(
            forPost: post,
            user: user,
            comments: comments,
            emitPostDetailsAtTestTime: testTime)
    }

    private func prepareDataProviderToSuccess(
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
        case (let .title(lvm), let .title(rvm)):
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


