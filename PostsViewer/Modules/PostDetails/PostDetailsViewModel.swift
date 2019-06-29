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

}

protocol PostDetailsViewModelOutput {

    var postDetails: Driver<[PostSectionViewModelType]> { get }

    var errorText: Driver<String> { get }
}

protocol PostDetailsViewModelType: PostDetailsViewModelInput, PostDetailsViewModelOutput {

    var showPostsDetails: AnyObserver<Post> { get }
}

class PostDetailsViewModel: PostDetailsViewModelType {

    // MARK: - Inputs

    var showPostsDetails: AnyObserver<Post>

    // MARK: - Outputs

    var postDetails: Driver<[PostSectionViewModelType]>

    var errorText: Driver<String>

    // MARK: -

    init(postsDetailsProvider: PostsDetailsProvider) {
        self.postsDetailsProvider = postsDetailsProvider

        let _showPostsDetails = PublishSubject<Post>()
        self.showPostsDetails = _showPostsDetails.asObserver()

        let _postDetails = _showPostsDetails.asObservable()
            .flatMap { post in
                return postsDetailsProvider
                    .getPostDetails(forPost: post)
                    .materialize()
            }.share()

        _postDetails.replay(1)
            .connect()
            .disposed(by: disposeBag)

        let postSections = _postDetails.elements()
            .flatMap({ postDetails -> Observable<[PostSectionViewModelType]>in                
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
            _postDetails.errors().map { _ in PostDetailsViewModel.errorMessage },
            postSections.errors().map { _ in PostDetailsViewModel.errorMessage },
            postSections.elements().map { _ in ""},
            _showPostsDetails.asObservable().map { _ in ""}
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
