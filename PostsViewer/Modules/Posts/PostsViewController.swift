//
//  PostsViewController.swift
//  PostsViewer
//
//  Created by Bogusław Parol on 22/06/2019.
//  Copyright © 2019 Parbo. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

class PostsViewController: UIViewController {

    var viewModel: PostsViewModelType!

    private lazy var loadingView = LoadingView(parentView: view)
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupUI()
        self.setupBindings()
    }

    private func setupUI() {
        self.title = "Posts"
        view.backgroundColor = .white
    }

    private func setupBindings() {
        viewModel.loadingViewVisible
            .drive(loadingView.visible)
            .disposed(by: disposeBag)
    }
}
