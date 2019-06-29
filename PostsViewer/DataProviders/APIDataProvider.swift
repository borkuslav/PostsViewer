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
    func getPosts() -> Observable<[Post]>
    func getUser(forUserId userId: Int) -> Observable<User>
    func getComments(forPostId postId: Int) -> Observable<[Comment]>
}

final class APIDataProviderImp {

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

    private func getSingle<Model: Decodable>(url: URL) -> Observable<Model> {
        let list: Observable<[Model]> = getList(url: url)
        return list.flatMap { list -> Observable<Model> in
            if let result = list.first {
                return .just(result)
            }
            return .error(NetworkError.parsingResourceFailed) // TODO: 
        }
    }
}

extension APIDataProviderImp: APIDataProviderType {

    func getPosts() -> Observable<[Post]> {
        return getList(url: URL(string: Constants.postsUrlString)!)
    }

    func getUser(forUserId userId: Int) -> Observable<User> {
        return getSingle(url: URL(string: "\(Constants.usersUrlString)?id=\(userId)")!)
    }

    func getComments(forPostId postId: Int) -> Observable<[Comment]> {
        return getList(url: URL(string: "\(Constants.commentsUrlString)?postId=\(postId)")!)
    }
}
