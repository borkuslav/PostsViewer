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
        
        let viewModel = PostsViewModel()
        
        let viewController = PostsViewController()
        viewController.viewModel = viewModel
        
        navigationController.pushViewController(viewController, animated: false)
        
        return Observable.never()
    }
    
}
