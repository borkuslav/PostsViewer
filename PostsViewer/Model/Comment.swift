//
//  Comment.swift
//  PostsViewer
//
//  Created by Bogusław Parol on 22/06/2019.
//  Copyright © 2019 Parbo. All rights reserved.
//

import Foundation

struct Comment: Decodable, Identifiable {
    var postId: Int
    var id: Int
    var name: String
    var email: String
    var body: String
}
