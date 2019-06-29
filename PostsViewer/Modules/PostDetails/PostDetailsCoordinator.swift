//
//  PostsDetailsCoordinator.swift
//  PostsViewer
//
//  Created by Bogusław Parol on 26/06/2019.
//  Copyright © 2019 Parbo. All rights reserved.
//

import UIKit
import RxSwift

class PostDetailsCoordinator: BaseCoordinator<Post, Void> {

    private let navigationController: UINavigationController

    deinit {
        debugPrint("## PostsDetailsCoordinator")
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
        let databaseDataProvider = DatabaseDataProviderImpl()
        let dataProvider = DataProvider(
            apiDataProvider: apiDataProvider,
            databaseDataProvider: databaseDataProvider)

        let postDetailsViewModel = PostDetailsViewModel(postsDetailsProvider: dataProvider)
        viewController.viewModel = postDetailsViewModel
        // TODO: bind show other posts of that autor
        // TODO: bind show user profile
        // TODO: bind show comments

        navigationController.pushViewController(viewController, animated: true)

        postDetailsViewModel.showPostsDetails.onNext(input)

        return .never()
    }
}
