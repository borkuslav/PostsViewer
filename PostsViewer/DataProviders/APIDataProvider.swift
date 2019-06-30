//
//  APIDataProvider.swift
//  PostsViewer
//
//  Created by Bogusław Parol on 24/06/2019.
//  Copyright © 2019 Parbo. All rights reserved.
//

import Foundation
import RxSwift

protocol APIDataProviderType {
    func getPosts(forUserId userId: Int?) -> Observable<[Post]>
    func getUser(forUserId userId: Int) -> Observable<User?>
    func getComments(forPostId postId: Int) -> Observable<[Comment]>
}

final class APIDataProvider {

    private func getList<Model: Decodable>(url: URL) -> Observable<[Model]> {
        let urlRequest = URLRequest(url: url)
        return URLSession.shared.rx
            .response(request: urlRequest)
            .flatMap { (response: HTTPURLResponse, data: Data) -> Observable<[Model]> in
                if 200 ..< 300 ~= response.statusCode {
                    if let items = try? JSONDecoder().decode([Model].self, from: data) {
                        return .just(items)
                    }
                    return .error(NetworkError.parsingResourceFailed)
                }
                return .error(NetworkError.loadingResourceFailed(response.statusCode))
            }            
    }
}

extension APIDataProvider: APIDataProviderType {

    func getPosts(forUserId userId: Int?) -> Observable<[Post]> {
        if let userId = userId {
            return getList(url: URL(string: "\(Constants.postsUrlString)?userId=\(userId)")!)
        }
        return getList(url: URL(string: Constants.postsUrlString)!)

    }

    func getUser(forUserId userId: Int) -> Observable<User?> {
        return getList(url: URL(string: "\(Constants.usersUrlString)?id=\(userId)")!)
            .flatMap({ (users: [User]) -> Observable<User?> in
                return .just(users.first)
            })
    }

    func getComments(forPostId postId: Int) -> Observable<[Comment]> {
        return getList(url: URL(string: "\(Constants.commentsUrlString)?postId=\(postId)")!)
    }
}
