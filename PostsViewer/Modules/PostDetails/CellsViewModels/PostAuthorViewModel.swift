//
//  PostDetailsAuthorViewModel.swift
//  PostsViewer
//
//  Created by Bogusław Parol on 28/06/2019.
//  Copyright © 2019 Parbo. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

protocol PostAuthorViewModelIntput {
    var showOtherPostsButtonPressed: AnyObserver<Void> { get }
}

protocol PostAuthorViewModelOutput {
    var showOtherPosts: Driver<Void> { get }
}

protocol PostAuthorViewModelType: PostAuthorViewModelIntput, PostAuthorViewModelOutput {

}

class PostAuthorViewModel {

    // MARK: - Inputs

    var showOtherPostsButtonPressed: AnyObserver<Void>

    // MARK: - Outputs

    var showOtherPosts: Driver<Void>

    // MARK: -

    let user: User

    init(user: User) {
        self.user = user

        let _showOtherPosts = PublishSubject<Void>()
        self.showOtherPostsButtonPressed = _showOtherPosts.asObserver()
        self.showOtherPosts = _showOtherPosts
            .asObservable()
            .asDriver(onErrorDriveWith: .never())
    }

    private let disposeBag = DisposeBag()
}
