//
//  PostDetailsTitleCell.swift
//  PostsViewer
//
//  Created by Bogusław Parol on 28/06/2019.
//  Copyright © 2019 Parbo. All rights reserved.
//

import UIKit

class PostSectionContentCell: UITableViewCell {

    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var body: UILabel!

    func setup(viewModel: PostContentViewModel) {
        title.text = viewModel.post.title
        body.text = viewModel.post.body
    }
}
