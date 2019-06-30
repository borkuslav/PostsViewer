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

class BaseCoordinator<InputType, ResultType> {

    let disposeBag = DisposeBag()

    func coordinate<InputType, ResultType>(
        to coordinator: BaseCoordinator<InputType, ResultType>,
        withInput input: InputType,
        andTransition transitionType: TransitionType) -> Observable<ResultType> {
        
        store(coordinator: coordinator)
        return coordinator.start(withInput: input, andTransition: transitionType)
    }

    func start(
        withInput input: InputType,
        andTransition transitionType: TransitionType) -> Observable<ResultType> {

        fatalError("Start method should be implemented.")
    }

    // MARK: - Private
    private let identifier = UUID()

    private var childCoordinators = NSHashTable<AnyObject>.weakObjects()

    private func store<InputType, ResultType>(coordinator: BaseCoordinator<InputType, ResultType>) {
        childCoordinators.add(
            CoordinatorBox<InputType, ResultType>(
                item: coordinator,
                identifier: coordinator.identifier)
        )
    }

    private func getChildCoordinator<InputType, ResultType>(
        identifier: UUID) -> BaseCoordinator<InputType, ResultType>? {
        
        var childCoordinator: BaseCoordinator<InputType, ResultType>?
        let enumerator = self.childCoordinators.objectEnumerator()
        while let child = enumerator.nextObject() {
            if let box = child as? CoordinatorBox<InputType, ResultType>, box.identifier == identifier {
                childCoordinator = box.item
            }
        }
        return childCoordinator
    }
}

extension BaseCoordinator: CoordinatorType {
    
}

private class CoordinatorBox<InputType, ResultType: Any> {

    private(set) var item: BaseCoordinator<InputType, ResultType>
    private(set) var identifier: UUID

    init(item: BaseCoordinator<InputType, ResultType>, identifier: UUID) {
        self.item = item
        self.identifier = identifier
    }
}
