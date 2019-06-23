//
//  DatabaseHelper.swift
//  PostsViewer
//
//  Created by Bogusław Parol on 22/06/2019.
//  Copyright © 2019 Parbo. All rights reserved.
//

import Foundation
import CoreData
import RxSwift

enum DatabaseError: LocalizedError {
    case noBackgroundContext
}

class DatabaseHelper {

    static let instance = DatabaseHelper()

    // MARK: - Caching

    func cachePosts(_ posts: [Post]) {
        cache(
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

    func cacheUsers(_ users: [User]) {

    }

    func cacheComments(_ comments: [Comment]) {
        
    }

    // MARK: - Core Data Saving support

    func saveContext () {
        if let context = backgroundContext {
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    debugPrint(error)
                }
            }
        }
    }

    // MARK: - Private

    private enum Entities: String {
        case post
        case user
        case comment

        var name: String {
            return rawValue.capitalized + "Entity"
        }
    }

    private init() {
        self.createPersistentContainer()
    }

    private func cache<Type, EntityType: NSManagedObject>(
        items: [Type],
        entityName: String,
        cachedEntityForItem: @escaping ([EntityType], Type) -> EntityType?,
        updateEntityWithItem: @escaping (EntityType, Type) -> Void) {

        guard let context = backgroundContext else {
            return
        }

        context.perform {
            let entities = (try? context.fetch(NSFetchRequest<EntityType>(entityName: entityName))) ?? []
            items.forEach { item in
                let entity = cachedEntityForItem(entities, item) ?? EntityType(context: context)
                updateEntityWithItem(entity, item)
            }
            do {
                try context.save()
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
    }

    private func get<Type: Identifiable, EntityType: NSManagedObject>(
        entityName: String,
        create: @escaping (EntityType) -> Type) -> Observable<[Type]> {

        return Observable.create { [backgroundContext] observer in
            guard let context = backgroundContext else {
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

    private var backgroundContext: NSManagedObjectContext?

    private var persistentContainer: NSPersistentContainer?

    private func createPersistentContainer() {

        let container = NSPersistentContainer(name: "PostsViewer")
        container.loadPersistentStores(completionHandler: { [weak self] (_, error) in
            if let error = error as NSError? {
                debugPrint(error)
            } else {
                self?.backgroundContext = container.newBackgroundContext()
            }
        })
        persistentContainer = container
    }
}
