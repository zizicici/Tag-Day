//
//  NavigationViewController.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/4/29.
//

import UIKit

class NavigationController: UINavigationController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return children.first?.preferredStatusBarStyle ?? super.preferredStatusBarStyle
    }
    
    override var prefersStatusBarHidden: Bool {
        return children.first?.prefersStatusBarHidden ?? super.prefersStatusBarHidden
    }
}
