//
//  LoadingView.swift
//  PostsViewer
//
//  Created by Bogusław Parol on 22/06/2019.
//  Copyright © 2019 Parbo. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

class LoadingView: UIView {

    var visible: AnyObserver<Bool>

    private var activityIndicator = UIActivityIndicatorView(style: .gray)
    private weak var parentView: UIView?
    private let disposeBag = DisposeBag()

    init(parentView: UIView) {
        self.parentView = parentView

        let visible = PublishSubject<Bool>()
        self.visible = visible.asObserver()

        super.init(frame: parentView.frame)

        // configure
        backgroundColor = .white
        addActivityIndicator()

        /// bind
        visible.asDriver(onErrorJustReturn: false)
            .drive(onNext: { visible in
                visible ? self.startAnimating() : self.stopAnimating()
            }).disposed(by: disposeBag)
    }

    private func addActivityIndicator() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
        activityIndicator.hidesWhenStopped = true
    }

    private func startAnimating() {
        guard let parentView = parentView else {
            return
        }

        parentView.addSubview(self)
        NSLayoutConstraint.activate([
            activityIndicator.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            activityIndicator.topAnchor.constraint(equalTo: self.topAnchor),
            activityIndicator.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            activityIndicator.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        activityIndicator.startAnimating()
    }

    private func stopAnimating() {
        activityIndicator.stopAnimating()
        self.removeFromSuperview()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
