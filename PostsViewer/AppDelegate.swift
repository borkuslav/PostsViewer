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

    private var coordinator: RootCoordinator?
    private let disposeBag = DisposeBag()

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        let window = UIWindow()

        coordinator = RootCoordinator(window: window)
        coordinator?.start()
            .subscribe()
            .disposed(by: disposeBag)

        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        DatabaseHelper.instance.saveContext()
    }
}
