//
//  PostsDetailsViewController.swift
//  PostsViewer
//
//  Created by Bogusław Parol on 26/06/2019.
//  Copyright © 2019 Parbo. All rights reserved.
//

import UIKit
import RxSwift

class PostDetailsViewController: UIViewController, Storyboarded {

    var coordinator: CoordinatorType!
    var viewModel: PostDetailsViewModel!

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var errorLabel: UILabel!
    
    private let disposeBag = DisposeBag()
    private let cellFactory = PostSectionsCellFactory()
    private lazy var loadingView = LoadingView(parentView: view)
    private let refreshControl = UIRefreshControl()

    deinit{
        debugPrint("## deinit PostDetailsViewController")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupBindings()

        viewModel.viewDidLoad.onNext(())
    }

    private func setupUI() {
        title = ""
        view.backgroundColor = .white
        tableView.backgroundColor = .clear
        tableView.tableFooterView = UIView()
        tableView.addSubview(refreshControl)
        
        tableView.register(
            UINib(nibName: "PostSectionAuthorCell", bundle: .main),
            forCellReuseIdentifier: PostSectionCellReuseIdentifier.postSectionAuthor.rawValue)
        tableView.register(
            UINib(nibName: "PostSectionContentCell", bundle: .main),
            forCellReuseIdentifier: PostSectionCellReuseIdentifier.postSectionContent.rawValue)
        tableView.register(
            UINib(nibName: "PostSectionCommentsCell", bundle: .main),
            forCellReuseIdentifier: PostSectionCellReuseIdentifier.postSectionComments.rawValue)
    }

    private func setupBindings() {
        viewModel.postDetails
            .drive(tableView.rx.items) { [cellFactory] (tableView, _, postSection) in
                return cellFactory.makeCell(
                    inTableView: tableView,
                    forViewModelType: postSection)
            }.disposed(by: disposeBag)

        viewModel.errorText
            .drive(errorLabel.rx.text)
            .disposed(by: disposeBag)

        viewModel.loadingViewVisible
            .drive(loadingView.visible)
            .disposed(by: disposeBag)

        refreshControl.rx.controlEvent(.valueChanged)
            .map { [unowned refreshControl] _ in
                return refreshControl.isRefreshing
            }.filter { $0 == true }
            .map { _ in return () }
            .bind(to: viewModel.refresh)
            .disposed(by: disposeBag)

        viewModel.hideRefreshIndicator
            .drive(onNext: { [refreshControl] _ in
                refreshControl.endRefreshing()
            }).disposed(by: disposeBag)
    }
}
