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

class PostsCoordinator: BaseCoordinator<Void> {

    private var navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    override func start() -> Observable<Void> {

        guard let viewController = PostsViewController.initFromStoryboard(name: "Posts") else {
            return Observable.never()
        }

        let apiDataProvider = APIDataProviderImp()
        let databaseDataProvider = DatabaseDataProviderImpl()
        let dataProvider = DataProviderImpl(
            apiDataProvider: apiDataProvider,
            databaseDataProvider: databaseDataProvider)

        let viewModel = PostsViewModel(dataProvider: dataProvider)
        viewController.viewModel = viewModel
        navigationController.pushViewController(viewController, animated: false)

        viewModel.selectedPost
            .drive(onNext: { [weak self] post in
                self?.pushPostDetails(post: post)
            }).disposed(by: disposeBag)

        return Observable.never()
    }

    private func pushPostDetails(post: Post) {
        debugPrint("")
    }

}
