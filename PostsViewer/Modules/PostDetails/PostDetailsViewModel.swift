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

}

class PostDetailsViewModel: PostDetailsViewModelType {

    var postDetails: Observable<PostDetails>

    init() {
        let postDetails = ReplaySubject<PostDetails>.create(bufferSize: 1)
        self.postDetails = postDetails.asObservable()
    }
}
