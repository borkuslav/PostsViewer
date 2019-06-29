//
//  PostDetailsCellFactory.swift
//  PostsViewer
//
//  Created by Bogusław Parol on 28/06/2019.
//  Copyright © 2019 Parbo. All rights reserved.
//

import UIKit

class PostDetailsCellFactory {

    func makeCell(
        inTableView tableView: UITableView,
        forViewModelType viewModelType: PostSectionViewModelType) -> UITableViewCell {

        switch  viewModelType {
        case .content(let contentViewModel):
            return UITableViewCell()
        case .author(let authorViewModel):
            return UITableViewCell()
        case .comments(let commentsViewModel):
            return UITableViewCell()
        default:
            return UITableViewCell()
        }
    }

}
