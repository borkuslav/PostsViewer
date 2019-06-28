//
//  PostsDetailsViewModel.swift
//  PostsViewer
//
//  Created by Bogusław Parol on 26/06/2019.
//  Copyright © 2019 Parbo. All rights reserved.
//

import Foundation
import RxSwift

protocol PostDetailsViewModelInput {

}

protocol PostDetailsViewModelOutput {

    var postDetails: Observable<PostDetails> { get }
}

protocol PostDetailsViewModelType: PostDetailsViewModelInput, PostDetailsViewModelOutput {

    var showPostsDetails: AnyObserver<Post> { get }
}

class PostDetailsViewModel: PostDetailsViewModelType {

    // MARK: - Inputs

    var showPostsDetails: AnyObserver<Post>

    // MARK: - Outputs

    var postDetails: Observable<PostDetails>

    // MARK: -

    init(postsDetailsProvider: PostsDetailsProvider) {
        self.postsDetailsProvider = postsDetailsProvider

        let _showPostsDetails = PublishSubject<Post>()
        self.showPostsDetails = _showPostsDetails.asObserver()

        let _postDetails = ReplaySubject<PostDetails>.create(bufferSize: 1)
        self.postDetails = _postDetails.asObservable()
    }

    private let postsDetailsProvider: PostsDetailsProvider

}
