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

    /// call when to load posts without loading view
    var refreshPosts: AnyObserver<Void> { get }

    /// call when viewDidLoad
    var viewDidLoad: AnyObserver<Void> { get }
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

    var refreshPosts: AnyObserver<Void>

    var viewDidLoad: AnyObserver<Void>

    // MARK: - Outputs

    var loadingViewVisible: Driver<Bool>

    var errorViewVisible: Driver<(Bool, String)>

    var hideRefreshIndicator: Driver<Void>

    var posts: Driver<[Post]>

    // MARK: -
    private let disposeBag = DisposeBag()
    private let dataProvider: DataProvider

    init(dataProvider: DataProvider) {
        self.dataProvider = dataProvider

        let loadingView = PublishSubject<Bool>()
        let showLoadingView = loadingView.asObserver()
        self.loadingViewVisible = showLoadingView.asDriver(onErrorJustReturn: false)

        let errorView = PublishSubject<(Bool, String)>()
        let showErrorView = errorView.asObserver()
        self.errorViewVisible = showErrorView.asDriver(onErrorJustReturn: (false, ""))

        let hidingRefreshIndicator = PublishSubject<Void>()
        self.hideRefreshIndicator = hidingRefreshIndicator.asDriver(onErrorJustReturn: ())

        let refreshingPosts = PublishSubject<Void>()
        self.refreshPosts = refreshingPosts.asObserver()

        let viewDidLoad = PublishSubject<Void>()
        self.viewDidLoad = viewDidLoad.asObserver()

        let loadingPostsResult = Observable.merge(
            viewDidLoad.asObservable()
                .do(onNext: { _ in
                    debugPrint("## loadPostsRequested")
                    showLoadingView.onNext(true)
                    showErrorView.onNext((false, ""))
                }).map { _ -> Bool in false },
            refreshingPosts.asObservable()
                .do(onNext: { _ in
                    debugPrint("## refreshPostsRequested")
                    showLoadingView.onNext(false)
                    showErrorView.onNext((false, ""))
                }).map { _ -> Bool in true }
            ).flatMap({ forceFromAPI in
                return dataProvider.getPosts(forceFromAPI: forceFromAPI)
                    .materialize()
            }).share()

        self.posts = Observable<[Post]>.merge(
            loadingPostsResult.elements()
                .do(onNext: { _ in
                    debugPrint("## posts loaded")
                    showLoadingView.asObserver().onNext(false)
                    showErrorView.asObserver().onNext((false, ""))
                    hidingRefreshIndicator.asObserver().onNext(())
                }),
            loadingPostsResult.errors()
                .do(onNext: { errors in
                    debugPrint("## loading posts failed")
                    let message = errors.localizedDescription + "\nPull down to refresh" // localize
                    showErrorView.asObserver().onNext((true, message))
                    showLoadingView.asObserver().onNext(false)
                    hidingRefreshIndicator.asObserver().onNext(())
                }).flatMap({ _ -> Observable<[Post]> in
                    return .just([])
                })
            ).asDriver(onErrorJustReturn: [])
    }

    deinit {
        debugPrint("## PostsViewModel")
    }
}
