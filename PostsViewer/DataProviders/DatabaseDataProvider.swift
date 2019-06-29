//
//  DatabaseDataProvider.swift
//  PostsViewer
//
//  Created by Bogusław Parol on 24/06/2019.
//  Copyright © 2019 Parbo. All rights reserved.
//

import Foundation
import CoreData
import RxSwift

enum Entities: String {
    case post
    case user
    case comment

    var name: String {
        return rawValue.capitalized + "Entity"
    }
}

protocol DatabaseDataProviderType: class {
    func getPosts() -> Observable<[Post]>
    func cachePosts(_ posts: [Post])

    func getUser(forUserId userId: Int) -> Observable<User?>
    func cacheUser(_ user: User)

    func getComments(forPostId postId: Int) -> Observable<[Comment]>
    func cacheComments(_ comments: [Comment])
}

final class DatabaseDataProvider {
    
}

extension DatabaseDataProvider: DatabaseDataProviderType {

    func getPosts() -> Observable<[Post]> {
        return DatabaseHelper.instance.get(
            entityName: Entities.post.name,
            create: { (entity: PostEntity) -> Post in
                return Post(
                    userId: Int(entity.userId),
                    id: Int(entity.id),
                    title: entity.title ?? "",
                    body: entity.body ?? "")
        })
    }

    func cachePosts(_ posts: [Post]) {
        DatabaseHelper.instance.cache(
            items: posts,
            entityName: Entities.post.name,
            cachedEntityForItem: { (entities: [PostEntity], item: Post) in
                return entities.first { $0.id == item.id }
            },
            updateEntityWithItem: { (postEntity: PostEntity, post: Post) in
                postEntity.id = Int32(post.id)
                postEntity.userId = Int32(post.userId)
                postEntity.body = post.body
                postEntity.title = post.title
            })
    }

    func getUser(forUserId userId: Int) -> Observable<User?> {
        return DatabaseHelper.instance.get(
            entityName: Entities.user.name,
            predicate: NSPredicate(format: "id == %d", userId),
            create: { (entity: UserEntity) -> User in
                return User(
                    id: Int(entity.id),
                    name: entity.name ?? "",
                    username: entity.username ?? "")
        }).flatMap({ users -> Observable<User?> in
            if users.isEmpty {
                return .just(nil)
            } else if users.count == 1 {
                return .just(users[0])
            } else {
                return .error(DatabaseError.multipleEntitiesFound)
            }
        })
    }

    func cacheUser(_ user: User) {
        DatabaseHelper.instance.cache(
            items: [user],
            entityName: Entities.user.name,
            cachedEntityForItem: { (entities: [UserEntity], item: User) in
                return entities.first { $0.id == item.id }
            },
            updateEntityWithItem: { (userEntity: UserEntity, user: User) in
                userEntity.id = Int32(user.id)
                userEntity.name = user.name
                userEntity.username = user.username
        })
    }

    func getComments(forPostId postId: Int) -> Observable<[Comment]> {
        return DatabaseHelper.instance.get(
            entityName: Entities.comment.name,
            predicate: NSPredicate(format: "postId == %d", postId),
            create: { (entity: CommentEntity) -> Comment in
                return Comment(
                    postId: Int(entity.postId),
                    id: Int(entity.id),
                    name: entity.name ?? "",
                    email: entity.email ?? "",
                    body: entity.body ?? "")
        })
    }

    func cacheComments(_ comments: [Comment]) {
        DatabaseHelper.instance.cache(
            items: comments,
            entityName: Entities.comment.name,
            cachedEntityForItem: { (entities: [CommentEntity], item: Comment) in
                return entities.first { $0.id == item.id }
            },
            updateEntityWithItem: { (commentEntity: CommentEntity, comment: Comment) in
                commentEntity.id = Int32(comment.id)
                commentEntity.postId = Int32(comment.postId)
                commentEntity.name = comment.name
                commentEntity.body = comment.body
                commentEntity.email = comment.email                
         })
    }
}
