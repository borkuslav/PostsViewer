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
        
        let viewController = PostsDetailsViewController()
        viewController.coordinator = self

        navigationController.pushViewController(viewController, animated: true)

        return .never()
    }
}
