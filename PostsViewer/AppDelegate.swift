//
//  AppDelegate.swift
//  PostsViewer
//
//  Created by Bogusław Parol on 22/06/2019.
//  Copyright © 2019 Parbo. All rights reserved.
//

import UIKit
import RxSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    private var coordinator: CoordinatorType?
    private let disposeBag = DisposeBag()

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        let window = UIWindow()

        let rootCoordinator = RootCoordinator(window: window)
        rootCoordinator.start(withTransition: .custom)
            .subscribe()
            .disposed(by: disposeBag)
        coordinator = rootCoordinator

        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        DatabaseHelper.instance.saveContext()
    }
}
