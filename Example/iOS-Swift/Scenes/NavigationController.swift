//
//  NavigationController.swift
//  Example-iOS
//
//  Created by BB9z on 2020/4/12.
//  Copyright © 2020 RFUI. All rights reserved.
//

import UIKit

class NavigationController: UINavigationController,
    UINavigationControllerDelegate {

    override func awakeFromNib() {
        super.awakeFromNib()
        self.delegate = self
    }

    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        lastViewControllers = viewControllers
    }

    private var lastViewControllers: [UIViewController] = [] {
        didSet {
            if oldValue == lastViewControllers { return }

            let vcRemoved = oldValue.filter { !lastViewControllers.contains($0) }
            let vcAdded = lastViewControllers.filter { !oldValue.contains($0) }
            if !vcRemoved.isEmpty {
                didRemove(viewControllers: vcRemoved)
            }
            if !vcAdded.isEmpty {
                didAdd(viewControllers: vcAdded)
            }
        }
    }

    func didAdd(viewControllers: [UIViewController]) {

    }
    func didRemove(viewControllers: [UIViewController]) {
        for vc in viewControllers {
            TestAPI.shared.cancelOperations(withGroupIdentifier: vc.apiGroupIdentifier)
        }
    }
}

extension UIViewController {
    var apiGroupIdentifier: String {
        return "\(ObjectIdentifier(self))"
    }
}
