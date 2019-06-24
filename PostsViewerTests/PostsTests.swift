//
//  PostsTests.swift
//  PostsViewerTests
//
//  Created by Bogusław Parol on 24/06/2019.
//  Copyright © 2019 Parbo. All rights reserved.
//

import Foundation
import XCTest
import RxCocoa
import RxSwift
import RxTest
import RxBlocking

@testable import PostsViewer

/* What to test?
 - on [refreshPosts] / on [viewDidLoad]
    -> should call [DataProvider.getPosts]
    -> should emit [posts] on success
    -> should emit [errorText] before request and after
    -> should emit [loadingViewVisible:false] before request and after
    -> should emit [hideRefreshIndicator] after request
 - on [viewDidLoad]
    -> should emit [loadingViewVisible:true]

 */
class PostsTests: XCTestCase {

    var scheduler: TestScheduler!
    var disposeBag: DisposeBag!

    var viewModel: PostsViewModel!
    private var dataProvider: DataProviderFake!

    override func setUp() {
        scheduler = TestScheduler(initialClock: 0)
        disposeBag = DisposeBag()

        dataProvider = DataProviderFake()
        viewModel = PostsViewModel(dataProvider: dataProvider)
    }

    func testRefreshPosts() {

        let postsList: [Post] = TestDataParser().loadAndParsePosts()!
        dataProvider.getPostsResult = .just(postsList)

        let posts = scheduler.createObserver(Array<Post>.self)
        viewModel.posts
            .drive(posts)
            .disposed(by: disposeBag)

        let errorText = scheduler.createObserver(String.self)
        viewModel.errorText
            .drive(errorText)
            .disposed(by: disposeBag)

        let loadingViewVisible = scheduler.createObserver(Bool.self)
        viewModel.loadingViewVisible
            .drive(loadingViewVisible)
            .disposed(by: disposeBag)

        scheduler.createColdObservable([.next(0, ())])
            .bind(to: viewModel.refreshPosts)
            .disposed(by: disposeBag)
        scheduler.start()

        XCTAssertEqual(posts.events, [ Recorded.next(0, postsList)])
        XCTAssertEqual(errorText.events, [
            Recorded.next(0, ""),
            Recorded.next(0, "")
        ])
        XCTAssertEqual(loadingViewVisible.events, [
            Recorded.next(0, false)
        ])
    }
}

private class DataProviderFake: DataProvider {

    var getPostsResult: Observable<[Post]>!

    func getPosts(forceFromAPI: Bool) -> Observable<[Post]> {
        return getPostsResult
    }
}
