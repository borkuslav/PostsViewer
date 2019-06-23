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
import RxSwiftExt

protocol PostsViewModelInput {

    /// call when to load posts with loading view
    var loadPosts: AnyObserver<Void> { get }

    /// call when to load posts without loading view
    var refreshPosts: AnyObserver<Void> { get }
}

protocol PostsViewModelOutput {

    var loadingViewVisible: Driver<Bool> { get }

    var errorViewVisible: Driver<(Bool, String)> { get }

    var hideRefreshIndicator: Driver<Void> { get }

    var posts: Driver<[Post]> { get }
}

protocol PostsViewModelType: PostsViewModelInput, PostsViewModelOutput {}

class PostsViewModel: PostsViewModelType {

    // MARK: - Inputs

    var loadPosts: AnyObserver<Void>

    var refreshPosts: AnyObserver<Void>

    // MARK: - Outputs

    var loadingViewVisible: Driver<Bool>

    var errorViewVisible: Driver<(Bool, String)>

    var hideRefreshIndicator: Driver<Void>

    var posts: Driver<[Post]>

    // MARK: -
    private let disposeBag = DisposeBag()
    private let postsProvider: NetworkPostsProvider

    init(postsProvider: NetworkPostsProvider) {
        self.postsProvider = postsProvider

        let loadingView = ReplaySubject<Bool>.create(bufferSize: 1)
        let showLoadingView = loadingView.asObserver()
        self.loadingViewVisible = showLoadingView.asDriver(onErrorJustReturn: false)

        let errorView = ReplaySubject<(Bool, String)>.create(bufferSize: 1)
        let showErrorView = errorView.asObserver()
        self.errorViewVisible = showErrorView.asDriver(onErrorJustReturn: (false, ""))

        let hidingRefreshIndicator = ReplaySubject<Void>.create(bufferSize: 1)
        self.hideRefreshIndicator = hidingRefreshIndicator.asDriver(onErrorJustReturn: ())

        let loadingPosts = ReplaySubject<Void>.create(bufferSize: 1)
        self.loadPosts = loadingPosts.asObserver()
        let loadPostsRequested = loadingPosts.asObservable()

        let refreshingPosts = ReplaySubject<Void>.create(bufferSize: 1)
        self.refreshPosts = refreshingPosts.asObserver()
        let refreshPostsRequested = refreshingPosts.asObservable()

        let loadingPostsResult = Observable.merge(
            loadPostsRequested
                .do(onNext: { _ in
                    debugPrint("## loadPostsRequested")
                    showLoadingView.onNext(true)
                    showErrorView.onNext((false, ""))
                }),
            refreshPostsRequested
                .do(onNext: { _ in
                    debugPrint("## refreshPostsRequested")
                    showLoadingView.onNext(false)
                    showErrorView.onNext((false, ""))
                })
            ).flatMap({ _ in
                return postsProvider.getPosts()
                    .materialize()
            }).share()

        self.posts = loadingPostsResult.elements()
            .do(onNext: { _ in
                debugPrint("## posts downloaded")
                showLoadingView.asObserver().onNext(false)
                showErrorView.asObserver().onNext((false, ""))
                hidingRefreshIndicator.asObserver().onNext(())
            })
            .asDriver(onErrorJustReturn: [])

        loadingPostsResult.errors().subscribe(onNext: { error in
            debugPrint("## loading posts failed")
            let message = error.localizedDescription + " Pull down to refresh" // localize
            showErrorView.asObserver().onNext((true, message))
            showLoadingView.asObserver().onNext(false)
        }).disposed(by: disposeBag)

        self.loadPosts.onNext(())
    }

    deinit {
        debugPrint("## PostsViewModel")
    }
}
