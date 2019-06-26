//
//  BaseCoordinator.swift
//  PostsViewer
//
//  Created by Bogusław Parol on 22/06/2019.
//  Copyright © 2019 Parbo. All rights reserved.
//

// based on great example from
// https://github.com/uptechteam/Coordinator-MVVM-Rx-Example/tree/master/Coordinators-MVVM-Rx

import RxSwift
import Foundation

class BaseCoordinator<ResultType> {

    typealias CoordinationResult = ResultType

    let disposeBag = DisposeBag()

    func coordinate<T>(to coordinator: BaseCoordinator<T>,
                       withTransition transitionType: TransitionType) -> Observable<T> {
        
        store(coordinator: coordinator)
        return coordinator.start(withTransition: transitionType)
    }

    func start(withTransition transitionType: TransitionType) -> Observable<ResultType> {
        fatalError("Start method should be implemented.")
    }

    private let identifier = UUID()

    private var childCoordinators = NSHashTable<AnyObject>.weakObjects()

    private func store<T>(coordinator: BaseCoordinator<T>) {
        childCoordinators.add(CoordinatorBox<T>(item: coordinator, identifier: coordinator.identifier))
    }

    private func getChildCoordinator<T>(identifier: UUID) -> BaseCoordinator<T>? {
        var childCoordinator: BaseCoordinator<T>?
        let enumerator = self.childCoordinators.objectEnumerator()
        while let child = enumerator.nextObject() {
            if let box = child as? CoordinatorBox<T>, box.identifier == identifier {
                childCoordinator = box.item
            }
        }
        return childCoordinator
    }
}

extension BaseCoordinator: CoordinatorType {
    
}

private class CoordinatorBox<CoordinatorResult: Any> {

    private(set) var item: BaseCoordinator<CoordinatorResult>
    private(set) var identifier: UUID

    init(item: BaseCoordinator<CoordinatorResult>, identifier: UUID) {
        self.item = item
        self.identifier = identifier
    }
}

