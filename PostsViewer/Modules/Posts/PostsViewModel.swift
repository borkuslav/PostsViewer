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

    /// call on tapping on post
    var selectPost: AnyObserver<Post> { get }
}

protocol PostsViewModelOutput {

    var loadingViewVisible: Driver<Bool> { get }

    var errorText: Driver<String> { get }

    var hideRefreshIndicator: Driver<Void> { get }

    var posts: Driver<[Post]> { get }

    var selectedPost: Driver<Post> { get }
}

protocol PostsViewModelType: PostsViewModelInput, PostsViewModelOutput {}

class PostsViewModel: PostsViewModelType {

    // MARK: - Inputs

    var refreshPosts: AnyObserver<Void>

    var viewDidLoad: AnyObserver<Void>

    var selectPost: AnyObserver<Post>

    // MARK: - Outputs

    var loadingViewVisible: Driver<Bool>

    var errorText: Driver<String>

    var hideRefreshIndicator: Driver<Void>

    var posts: Driver<[Post]>

    var selectedPost: Driver<Post>

    // MARK: -
    private let disposeBag = DisposeBag()
    private let dataProvider: DataProviderType

    init(dataProvider: DataProviderType) {
        self.dataProvider = dataProvider

        let refreshPosts = PublishSubject<Void>()

        let viewDidLoad = PublishSubject<Void>()

        let posts = Observable.merge(
            viewDidLoad.asObservable().map { _ -> Bool in true },
            refreshPosts.asObservable().map { _ -> Bool in false }
        ).flatMap({ withDatabaseFallback in
            return dataProvider
                .getPosts(withDatabaseFallback: withDatabaseFallback)
                .materialize()
        }).share()

        self.errorText = Observable<String>.merge(
            posts.errors().map {
                return $0.localizedDescription + "\nPull down to refresh"                
            },
            posts.elements().map { _ in "" },
            refreshPosts.map { _ in "" }
        ).asDriver(onErrorDriveWith: .never())

        self.hideRefreshIndicator = posts
            .map { _ in () }
            .asDriver(onErrorDriveWith: .never())

        self.loadingViewVisible = Observable<Bool>.merge(
            viewDidLoad.asObservable().map { _ in true },
            posts.elements().map { _ in false },
            posts.errors().map { _ in false }
        ).asDriver(onErrorDriveWith: .never())

        self.posts = Observable<[Post]>.merge(
            posts.elements(),
            posts.errors().flatMap { _ -> Observable<[Post]> in .just([]) }
        ).asDriver(onErrorJustReturn: [])

        self.viewDidLoad = viewDidLoad.asObserver()
        self.refreshPosts = refreshPosts.asObserver()

        let selectingPosts = PublishSubject<Post>()
        self.selectPost = selectingPosts.asObserver()
        self.selectedPost = selectingPosts.asDriver(onErrorDriveWith: .never())
    }

    deinit {
        debugPrint("## PostsViewModel")
    }
}
