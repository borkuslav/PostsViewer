//
//  PostsDetailsCoordinator.swift
//  PostsViewer
//
//  Created by Bogusław Parol on 26/06/2019.
//  Copyright © 2019 Parbo. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class PostDetailsCoordinator: BaseCoordinator<Post, Void> {

    private let navigationController: UINavigationController

    deinit {
        debugPrint("## deinit PostsDetailsCoordinator")
    }

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    override func start(withInput input: Post, andTransition transitionType: TransitionType) -> Observable<Void> {
        
        guard let viewController = PostDetailsViewController.initFromStoryboard(name: "PostDetails") else {
            return .never()
        }

        viewController.coordinator = self

        let apiDataProvider = APIDataProviderImp()
        let databaseDataProvider = DatabaseDataProvider()
        let dataProvider = DataProvider(
            apiDataProvider: apiDataProvider,
            databaseDataProvider: databaseDataProvider
        )

        let postDetailsViewModel = PostDetailsViewModel(
            postsDetailsProvider: dataProvider,
            post: BehaviorRelay<Post>(value: input)
        )
        viewController.viewModel = postDetailsViewModel

        postDetailsViewModel.showOtherUserPosts.asObservable()
            .flatMap { [weak self] userId -> Observable<Post> in
                guard let self = self else {
                    return .never()
                }

                let postsCoordinator = PostsCoordinator(navigationController: self.navigationController)
                return self.coordinate(
                    to: postsCoordinator,
                    withInput: PostsAction.pick(userId),
                    andTransition: .presentModally)
            }.asDriver(onErrorDriveWith: .never())
            .do(afterNext: { _ in
                postDetailsViewModel.reload.onNext(())
            }).drive(postDetailsViewModel.currentPost)
            .disposed(by: disposeBag)

        navigationController.pushViewController(viewController, animated: true)

        return .never()
    }
}
