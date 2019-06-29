//
//  PostDetailsCellFactory.swift
//  PostsViewer
//
//  Created by Bogusław Parol on 28/06/2019.
//  Copyright © 2019 Parbo. All rights reserved.
//

import UIKit

enum PostSectionCellReuseIdentifier: String {
    case postSectionAuthor
    case postSectionContent
    case postSectionComments
}

class PostSectionsCellFactory {

    func makeCell(
        inTableView tableView: UITableView,
        forViewModelType viewModelType: PostSectionViewModelType) -> UITableViewCell {

        var cell: UITableViewCell?
        switch  viewModelType {
        case .author(let authorViewModel):
            let ident = PostSectionCellReuseIdentifier.postSectionAuthor.rawValue
            let authorCell = tableView.dequeueReusableCell(withIdentifier: ident) as? PostSectionAuthorCell
            authorCell?.setup(viewModel: authorViewModel)
            cell = authorCell
        case .content(let contentViewModel):
            let ident = PostSectionCellReuseIdentifier.postSectionContent.rawValue
            let contentCell = tableView.dequeueReusableCell(withIdentifier: ident) as? PostSectionContentCell
            contentCell?.setup(viewModel: contentViewModel)
            cell = contentCell
        case .comments(let commentsViewModel):
            let ident = PostSectionCellReuseIdentifier.postSectionComments.rawValue
            let commentsCell = tableView.dequeueReusableCell(withIdentifier: ident) as? PostSectionCommentsCell
            commentsCell?.setup(viewModel: commentsViewModel)
            cell = commentsCell
        }
        cell?.selectionStyle = .none
        return cell ?? UITableViewCell()
    }

}
