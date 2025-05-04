//
//  DisplayHandler.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/4/29.
//

import UIKit

protocol DisplayHandlerDelegate: AnyObject {
    func reloadData()
}

protocol DisplayHandler {
    init(delegate: DisplayHandlerDelegate)
    
    func getLeading() -> Int
    func getTrailing() -> Int
    
    func getSnapshot() -> NSDiffableDataSourceSnapshot<Section, Item>?
    func getCatalogueMenuElements() -> [UIMenuElement]
    func getTitle() -> String
    
    func updateSelectedYear(to year: Int)
    func getSelectedYear() -> Int
}
