//
//  UIDraggableCollectionView.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/4/29.
//

import UIKit

class UIDraggableCollectionView: UICollectionView {
    override func touchesShouldCancel(in view: UIView) -> Bool {
        if view.isKind(of: UIButton.self) {
            return true
        } else {
            return super.touchesShouldCancel(in: view)
        }
    }
}

class UIDraggableTableView: UITableView {
    override func touchesShouldCancel(in view: UIView) -> Bool {
        if view.isKind(of: UIButton.self) {
            return true
        } else {
            return super.touchesShouldCancel(in: view)
        }
    }
}
