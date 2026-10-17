//
//  NavigationViewController.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/4/29.
//

import UIKit

class NavigationController: UINavigationController {
    // Keep navigation and toolbar items horizontal on iPhone Duo.
    @available(iOS 27.1, *)
    override var preferredVerticalBarBehavior: UIVerticalBarBehavior {
        return .disabled
    }

    @available(iOS 27.1, *)
    override var childForPreferredVerticalBarBehavior: UIViewController? {
        return nil
    }
}
