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

    var errorText: Driver<String> { get }

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

    var errorText: Driver<String>

    var hideRefreshIndicator: Driver<Void>

    var posts: Driver<[Post]>

    // MARK: -
    private let disposeBag = DisposeBag()
    private let dataProvider: DataProvider

    init(dataProvider: DataProvider) {
        self.dataProvider = dataProvider

        let refreshPosts = PublishSubject<Void>()

        let viewDidLoad = PublishSubject<Void>()

        let posts = Observable.merge(
            viewDidLoad.asObservable().map { _ -> Bool in false },
            refreshPosts.asObservable().map { _ -> Bool in true }
        ).flatMap({ forceFromAPI in
            return dataProvider.getPosts(forceFromAPI: forceFromAPI)
                .materialize()
        }).share()

        self.errorText = Observable<String>.merge(
            posts.errors().map { $0.localizedDescription + "\nPull down to refresh" },
            posts.elements().map { _ in "" },
            refreshPosts.map { _ in "" }
        ).asDriver(onErrorJustReturn: "")

        self.hideRefreshIndicator = posts
            .map { _ in () }
            .asDriver(onErrorJustReturn: ())

        self.loadingViewVisible = Observable<Bool>.merge(
            viewDidLoad.asObservable().map { _ in true },
            posts.map { _ in false }
        ).asDriver(onErrorJustReturn: false)

        self.posts = Observable<[Post]>.merge(
            posts.elements(),
            posts.errors().flatMap { _ -> Observable<[Post]> in .just([])}
        ).asDriver(onErrorJustReturn: [])

        self.viewDidLoad = viewDidLoad.asObserver()
        self.refreshPosts = refreshPosts.asObserver()
    }

    deinit {
        debugPrint("## PostsViewModel")
    }
}
