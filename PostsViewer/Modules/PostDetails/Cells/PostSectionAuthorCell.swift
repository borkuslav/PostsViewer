//
//  PostDetailsAuthorCell.swift
//  PostsViewer
//
//  Created by Bogusław Parol on 28/06/2019.
//  Copyright © 2019 Parbo. All rights reserved.
//

import Foundation

import UIKit
import RxSwift

class PostSectionAuthorCell: UITableViewCell {

    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var seeOtherPosts: UIButton!

    func setup(viewModel: PostAuthorViewModel) {
        username.text = viewModel.user.username
        name.text = "(\(viewModel.user.name))"

        self.setupBindings(viewModel: viewModel)
    }

    private func setupBindings(viewModel: PostAuthorViewModel) {
        seeOtherPosts.rx.tap
            .bind(to: viewModel.showOtherPostsButtonPressed)
            .disposed(by: disposeBag)
    }

    override func prepareForReuse() {
        disposeBag = DisposeBag()
    }

    private var disposeBag = DisposeBag()
}
