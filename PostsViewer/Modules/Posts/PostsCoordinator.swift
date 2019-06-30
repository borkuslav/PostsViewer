//
//  PostsCoordinator.swift
//  PostsViewer
//
//  Created by Bogusław Parol on 22/06/2019.
//  Copyright © 2019 Parbo. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

enum PostsAction {
    case pick(User)
    case presentDetails
}

class PostsCoordinator: BaseCoordinator<PostsAction, Post> {

    private let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    deinit {
        debugPrint("## deinit PostsCoordinator")
    }

    override func start(
        withInput input: PostsAction,
        andTransition transitionType: TransitionType) -> Observable<Post> {

        guard let viewController = PostsViewController.initFromStoryboard(name: "Posts") else {
            return Observable.never()
        }

        viewController.coordinator = self

        defer {
            switch transitionType {
            case .push(let animated):
                navigationController.pushViewController(viewController, animated: animated)
            case .presentModally:
                let modalNavigationControoler = UINavigationController(rootViewController: viewController)
                navigationController.present(modalNavigationControoler, animated: true)
            default:
                break
            }
        }

        let apiDataProvider = APIDataProviderImp()
        let databaseDataProvider = DatabaseDataProvider()
        let dataProvider = DataProvider(
            apiDataProvider: apiDataProvider,
            databaseDataProvider: databaseDataProvider)

        switch input {
        case .presentDetails:
            let viewModel = PostsViewModel(postsProvider: dataProvider)
            viewController.viewModel = viewModel
            viewModel.selectedPost
                .asObservable()
                .flatMap({ [weak self] post -> Observable<Void> in
                    guard let self = self else {
                        return .never()
                    }
                    return self.pushPostDetails(post: post)
                }).subscribe()
                .disposed(by: disposeBag)

            return .never()

        case .pick(let user):
            let viewModel = PostsViewModel(
                postsProvider: dataProvider,
                currentUser: BehaviorRelay<User?>(value: user))
            viewController.viewModel = viewModel
            return viewModel.selectedPost
                .asObservable()
                .do(onNext: { [weak self] _ in
                    self?.navigationController.dismiss(animated: true)
                })
        }
    }

    private func pushPostDetails(post: Post) -> Observable<Void> {
        return coordinate(
            to: PostDetailsCoordinator(navigationController: navigationController),
            withInput: post,
            andTransition: .push(animated: true))
    }
}
