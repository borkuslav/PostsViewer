//
//  TransitionType.swift
//  PostsViewer
//
//  Created by Bogusław Parol on 26/06/2019.
//  Copyright © 2019 Parbo. All rights reserved.
//

import Foundation

enum TransitionType {
    case push(animated: Bool)
    case presentModally
    case custom
}
