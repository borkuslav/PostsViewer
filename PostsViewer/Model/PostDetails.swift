//
//  PostDetails.swift
//  PostsViewer
//
//  Created by Bogusław Parol on 28/06/2019.
//  Copyright © 2019 Parbo. All rights reserved.
//

import Foundation

struct PostDetails: Decodable {
    var post: Post
    var user: User
    var comments: [Comment]
}
