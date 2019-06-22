//
//  PostsViewModel.swift
//  PostsViewer
//
//  Created by Bogusław Parol on 22/06/2019.
//  Copyright © 2019 Parbo. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

protocol PostsViewModelInput {

}

protocol PostsViewModelOutput {

    var loadingViewVisible: Driver<Bool> { get }
}

protocol PostsViewModelType: PostsViewModelInput, PostsViewModelOutput {}

class PostsViewModel: PostsViewModelType {

    // MARK: - Inputs

    // MARK: - Outputs

    var loadingViewVisible: Driver<Bool>

    // MARK: -
    private let disposeBag = DisposeBag()

    init() {
        let showLoadingView = ReplaySubject<Bool>.create(bufferSize: 1)
        self.loadingViewVisible = showLoadingView.asDriver(onErrorJustReturn: false)
        showLoadingView.asObserver().onNext(true)

//        NetworkDataProvider().getPosts()
//            .subscribe(onNext: { posts in
//                debugPrint("")
//            }, onError: { error in
//                debugPrint("")
//            }).disposed(by: disposeBag)
//
//        NetworkDataProvider().getUsers()
//            .subscribe(onNext: { posts in
//                debugPrint("")
//            }, onError: { error in
//                debugPrint("")
//            }).disposed(by: disposeBag)
    }

    deinit {
        debugPrint("PostsViewModel")
    }
}
