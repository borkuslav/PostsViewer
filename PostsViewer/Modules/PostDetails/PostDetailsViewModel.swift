//
//  PostsDetailsViewModel.swift
//  PostsViewer
//
//  Created by Bogusław Parol on 26/06/2019.
//  Copyright © 2019 Parbo. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

protocol PostDetailsViewModelInput {

    var currentPost: BehaviorRelay<Post> { get }

    var viewDidLoad: AnyObserver<Void> { get }

    var reload: AnyObserver<Void> { get }
}

protocol PostDetailsViewModelOutput {

    var postDetails: Driver<[PostSectionViewModelType]> { get }

    var errorText: Driver<String> { get }

    var loadingViewVisible: Driver<Bool> { get }

    var hideRefreshIndicator: Driver<Void> { get }
}

protocol PostDetailsViewModelType: PostDetailsViewModelInput, PostDetailsViewModelOutput {

}

class PostDetailsViewModel: PostDetailsViewModelType {

    // MARK: - Inputs

    var currentPost: BehaviorRelay<Post>

    var viewDidLoad: AnyObserver<Void>

    var reload: AnyObserver<Void>

    // MARK: - Outputs

    var postDetails: Driver<[PostSectionViewModelType]>

    var errorText: Driver<String>

    var loadingViewVisible: Driver<Bool>

    var hideRefreshIndicator: Driver<Void>

    // MARK: -

    init(postsDetailsProvider: PostsDetailsProvider, post: BehaviorRelay<Post>) {

        self.postsDetailsProvider = postsDetailsProvider
        self.currentPost = post

        let _viewDidLoad = PublishSubject<Void>()
        self.viewDidLoad = _viewDidLoad.asObserver()

        let _reload = PublishSubject<Void>()
        self.reload = _reload.asObserver()

        let _postDetails = Observable.merge(
            _reload.asObservable(),
            _viewDidLoad.asObservable()
        ).flatMap { _ in
            return postsDetailsProvider
                .getPostDetails(forPost: post.value)
                .materialize()
        }.share()

        let postSections = _postDetails.elements()
            .flatMap({ postDetails -> Observable<[PostSectionViewModelType]> in
                if let validatedPostDetails = PostDetailsValidator().validate(postDetails) {
                    return .just([
                        .author(PostAuthorViewModel(user: validatedPostDetails.user)),
                        .content(PostContentViewModel(post: validatedPostDetails.post)),
                        .comments(PostCommentsViewModel(comments: validatedPostDetails.comments))
                    ])
                } else {
                    return .error(PostDetailsError.receivedInvalidPostDetails)
                }
            }).materialize()

        self.postDetails = Observable.merge(
            _postDetails.errors().flatMap { _ -> Observable<[PostSectionViewModelType]> in .just([]) },
            postSections.elements(),
            postSections.errors().flatMap { _ -> Observable<[PostSectionViewModelType]> in .just([]) }
        ).asDriver(onErrorDriveWith: .never())

        self.errorText = Observable.merge(
            _reload.asObservable().map { _ in ""},            
            _postDetails.errors().map { _ in PostDetailsViewModel.errorMessage },
            postSections.errors().map { _ in PostDetailsViewModel.errorMessage },
            postSections.elements().map { _ in ""}
        ).asDriver(onErrorDriveWith: .never())

        self.loadingViewVisible = Observable.merge(
            _viewDidLoad.asObservable().map { _ in true },
            _postDetails.errors().map { _ in false },
            postSections.errors().map { _ in false },
            postSections.elements().map { _ in false }
        ).asDriver(onErrorDriveWith: .never())

        self.hideRefreshIndicator = Observable.merge(
            _postDetails.errors().map { _ in () },
            postSections.errors().map { _ in () },
            postSections.elements().map { _ in () }
        ).asDriver(onErrorDriveWith: .never())
    }

    private let postsDetailsProvider: PostsDetailsProvider
    private let disposeBag = DisposeBag()
    private static let errorMessage = "Couldn't load data. \nPlease pull to refresh"

}

private struct PostDetailsValidator {

    func validate(_ postDetails: PostDetails) -> PostDetails? {
        let postId = postDetails.post.id
        let userId = postDetails.post.userId

        let user = postDetails.user
        if user.id != userId {
            return nil
        }

        let comments = postDetails.comments
        // let invalidComments = comments.filter { comment in comment.postId != postId }
        // TODO: log receiving comments from another post

        let filteredComments = comments.filter { comment in comment.postId == postId }
        var postDetails = postDetails
        postDetails.comments = filteredComments

        return postDetails
    }
}
