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
    var coordinator: CoordinatorType!

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var errorMessageLabel: UILabel!

    private lazy var loadingView = LoadingView(parentView: view)
    private let disposeBag = DisposeBag()
    private let postCellIdentifier = "PostCell"
    private let refreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupUI()
        self.setupBindings()

        self.viewModel.viewDidLoad.onNext(())
    }

    deinit {
        debugPrint("## deinit PostsViewController")
    }

    private func setupUI() {
        title = "Posts"
        view.backgroundColor = .white
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .clear
        tableView.addSubview(refreshControl)
        tableView.register(UINib(nibName: "PostCell", bundle: .main), forCellReuseIdentifier: postCellIdentifier)
    }

    private func setupBindings() {

        viewModel.title
            .drive(onNext: { [weak self] title in
                self?.title = title
            }).disposed(by: disposeBag)

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
                tableView.rx.items(cellIdentifier: postCellIdentifier, cellType: PostCell.self)
            ) { (_, post, cell) in
                cell.title.text = post.title
                cell.body.text = post.body
            }.disposed(by: disposeBag)

        tableView.rx.modelSelected(Post.self)
            .asDriver()
            .drive(viewModel.selectPost)
            .disposed(by: disposeBag)

        tableView.rx.itemSelected
            .subscribe(onNext: { [tableView] indexPath in
                tableView?.deselectRow(at: indexPath, animated: true)
            }).disposed(by: disposeBag)

        viewModel.addCancelButton
            .drive(onNext: { [weak self] _ in
                guard let self = self else {
                    return
                }
                let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)
                self.navigationItem.leftBarButtonItem = cancelButton
                cancelButton.rx.tap
                    .bind(to: self.viewModel.cancel)
                    .disposed(by: self.disposeBag)
            }).disposed(by: disposeBag)
    }
}
