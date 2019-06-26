//
//  APIDataProvider.swift
//  PostsViewer
//
//  Created by Bogusław Parol on 24/06/2019.
//  Copyright © 2019 Parbo. All rights reserved.
//

import Foundation
import RxSwift

protocol APIDataProvider {
    func getPosts() -> Observable<[Post]>
    func getUsers() -> Observable<[User]>
    func getComments() -> Observable<[Comment]>
}

final class APIDataProviderImp {

    private func get<Model: Decodable>(url: URL) -> Observable<[Model]> {
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

extension APIDataProviderImp: APIDataProvider {

    func getPosts() -> Observable<[Post]> {
        return get(url: URL(string: Constants.postsUrlString)!)
    }

    func getUsers() -> Observable<[User]> {
        return get(url: URL(string: Constants.usersUrlString)!)
    }

    func getComments() -> Observable<[Comment]> {
        return get(url: URL(string: Constants.commentsUrlString)!)            
    }
}
