//
//  PostDetailsCellViewModelType.swift
//  PostsViewer
//
//  Created by Bogusław Parol on 28/06/2019.
//  Copyright © 2019 Parbo. All rights reserved.
//

import Foundation

enum PostSectionViewModelType {
    case title(PostContentViewModel)
    case author(PostAuthorViewModel)
    case comments(PostCommentsViewModel)
}
