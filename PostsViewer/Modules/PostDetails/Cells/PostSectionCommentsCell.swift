//
//  PostDetailsCommentsCell.swift
//  PostsViewer
//
//  Created by Bogusław Parol on 28/06/2019.
//  Copyright © 2019 Parbo. All rights reserved.
//

import Foundation

import UIKit

class PostSectionCommentsCell: UITableViewCell {

    @IBOutlet weak var comments: UILabel!

    func setup(viewModel: PostCommentsViewModel) {
        comments.text = "\(viewModel.comments.count) comments"
    }
}
