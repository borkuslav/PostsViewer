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


    private(set) var backgroundContext: NSManagedObjectContext?

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
