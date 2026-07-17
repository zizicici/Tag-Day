//
//  UIApplication+Extension.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/7/6.
//

import UIKit

extension UIApplication {
    func hasPresentedModal() -> Bool {
        for case let windowScene as UIWindowScene in connectedScenes {
            for window in windowScene.windows where containsPresentedViewController(in: window.rootViewController) {
                return true
            }
        }
        return false
    }

    private func containsPresentedViewController(in viewController: UIViewController?) -> Bool {
        guard let viewController = viewController else { return false }
        if viewController.presentedViewController != nil {
            return true
        }
        return viewController.children.contains(where: { containsPresentedViewController(in: $0) })
    }

    func topViewController() -> UIViewController? {
        var topViewController: UIViewController? = nil
        for scene in connectedScenes {
            if let windowScene = scene as? UIWindowScene {
                for window in windowScene.windows {
                    if window.isKeyWindow {
                        topViewController = window.rootViewController
                    }
                }
            }
        }
        while true {
            if let presented = topViewController?.presentedViewController {
                topViewController = presented
            } else if let navController = topViewController as? UINavigationController {
                topViewController = navController.topViewController
            } else if let tabBarController = topViewController as? UITabBarController {
                topViewController = tabBarController.selectedViewController
            } else {
                // Handle any other third party container in `else if` if required
                break
            }
        }
        return topViewController
    }
}
