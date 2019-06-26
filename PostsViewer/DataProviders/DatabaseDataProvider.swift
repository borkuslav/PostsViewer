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

protocol DatabaseDataProvider {
    func getPosts() -> Observable<[Post]>
    func cachePosts(_ posts: [Post])
}

class DatabaseDataProviderImpl {

    private func get<Type: Identifiable, EntityType: NSManagedObject>(
        entityName: String,
        create: @escaping (EntityType) -> Type) -> Observable<[Type]> {

        return Observable.create { observer in
            guard let context = DatabaseHelper.instance.backgroundContext else {
                observer.onError(DatabaseError.noBackgroundContext)
                return Disposables.create()
            }

            context.perform {
                debugPrint("## loading entities")
                do {
                    let entities = try context.fetch(NSFetchRequest<EntityType>(entityName: entityName))
                    debugPrint("## loading entities OK: \(entities.count)")
                    let items: [Type] = entities.map(create)
                        .sorted(by: { (left, right) in
                            return left.id < right.id
                        })
                    observer.onNext(items)
                    observer.onCompleted()
                } catch {
                    debugPrint("## loading entities NOK")
                    observer.onError(DatabaseError.noBackgroundContext)
                }
            }
            return Disposables.create()
        }
    }
}

extension DatabaseDataProviderImpl: DatabaseDataProvider {

    func getPosts() -> Observable<[Post]> {
        return get(
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
}
