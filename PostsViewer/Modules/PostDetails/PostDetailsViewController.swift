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

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupUI()
        self.setupBindings()
    }

    private func setupUI() {
        title = ""
        view.backgroundColor = .white
        tableView.backgroundColor = .clear
        tableView.tableFooterView = UIView()
        
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
    }
}
