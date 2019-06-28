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
}

protocol PostDetailsViewModelType: PostDetailsViewModelInput, PostDetailsViewModelOutput {

    var showPostsDetails: AnyObserver<Post> { get }
}

class PostDetailsViewModel: PostDetailsViewModelType {

    // MARK: - Inputs

    var showPostsDetails: AnyObserver<Post>

    // MARK: - Outputs

    var postDetails: Driver<[PostSectionViewModelType]>

    // MARK: -

    init(postsDetailsProvider: PostsDetailsProvider) {
        self.postsDetailsProvider = postsDetailsProvider

        let _showPostsDetails = PublishSubject<Post>()
        self.showPostsDetails = _showPostsDetails.asObserver()

        let _postDetails = _showPostsDetails.asObservable()
            .flatMap { post in
                return postsDetailsProvider.getPostDetails(forPost: post)
                    .materialize()
            }.share()

        self.postDetails = _postDetails.elements()
            .flatMap({ postDetails -> Observable<[PostSectionViewModelType]>in
                return .just([
                    .author(PostAuthorViewModel(user: postDetails.user)),
                    .title(PostContentViewModel(post: postDetails.post)),
                    .comments(PostCommentsViewModel(comments: postDetails.comments))
                ])
            }).asDriver(onErrorDriveWith: .never())
    }

    private let postsDetailsProvider: PostsDetailsProvider

}
