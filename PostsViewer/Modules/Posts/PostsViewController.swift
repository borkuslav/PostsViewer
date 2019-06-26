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

class PostsViewController: UIViewController, Storyboarded {

    var viewModel: PostsViewModelType!

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var errorMessageLabel: UILabel!

    private lazy var loadingView = LoadingView(parentView: view)
    private let disposeBag = DisposeBag()
    private let postCellIdentifier = "PostsCellIdentifier"
    private let refreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupUI()
        self.setupBindings()

        self.viewModel.viewDidLoad.onNext(())
    }

    private func setupUI() {
        title = "Posts"
        view.backgroundColor = .white
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: postCellIdentifier)
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .clear
        tableView.addSubview(refreshControl)
    }

    private func setupBindings() {

        refreshControl.rx.controlEvent(.valueChanged)
            .map { [unowned refreshControl] _ in
                return refreshControl.isRefreshing
            }.filter { $0 == true }
            .map { _ in return () }
            .bind(to: viewModel.refreshPosts)
            .disposed(by: disposeBag)

        viewModel.hideRefreshIndicator
            .drive(onNext: { [refreshControl] _ in
                refreshControl.endRefreshing()                
            }).disposed(by: disposeBag)

        viewModel.loadingViewVisible
            .drive(loadingView.visible)
            .disposed(by: disposeBag)

        viewModel.errorText
            .drive(errorMessageLabel.rx.text)
            .disposed(by: disposeBag)

        viewModel.posts            
            .drive(
                tableView.rx.items(cellIdentifier: postCellIdentifier, cellType: UITableViewCell.self)
            ) { (_, post, cell) in
                cell.textLabel?.numberOfLines = 0
                cell.textLabel?.text = post.title
            }.disposed(by: disposeBag)

        tableView.rx.modelSelected(Post.self)
            .asDriver()
            .drive(viewModel.selectPost)
            .disposed(by: disposeBag)
    }
}
