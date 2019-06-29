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

class PostsCoordinator: BaseCoordinator<Void, Void> {

    private let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    override func start(withInput input: Void, andTransition transitionType: TransitionType) -> Observable<Void> {

        guard let viewController = PostsViewController.initFromStoryboard(name: "Posts") else {
            return Observable.never()
        }

        viewController.coordinator = self

        let apiDataProvider = APIDataProviderImp()
        let databaseDataProvider = DatabaseDataProvider()
        let dataProvider = DataProvider(
            apiDataProvider: apiDataProvider,
            databaseDataProvider: databaseDataProvider)

        let viewModel = PostsViewModel(postsProvider: dataProvider)
        viewController.viewModel = viewModel
        switch transitionType {
        case .push(let animated):
            navigationController.pushViewController(viewController, animated: animated)
        default:
            break
        }

        viewModel.selectedPost
            .asObservable()
            .flatMap({ [weak self] post -> Observable<Void> in
                guard let self = self else {
                    return .never()
                }
                return self.pushPostDetails(post: post)
            }).subscribe()
            .disposed(by: disposeBag)

        return Observable.never()
    }

    private func pushPostDetails(post: Post) -> Observable<Void> {
        return coordinate(
            to: PostDetailsCoordinator(navigationController: navigationController),
            withInput: post,
            andTransition: .push(animated: true))
    }
}
