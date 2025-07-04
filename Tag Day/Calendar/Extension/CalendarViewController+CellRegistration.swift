//
//  CalendarViewController+CellRegistration.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/4/29.
//

import UIKit
import ZCCalendar

extension CalendarViewController {
    func getBlockCellRegistration() -> UICollectionView.CellRegistration<BlockCell, Item> {
        let cellRegistration = UICollectionView.CellRegistration<BlockCell, Item> { (cell, indexPath, identifier) in
            switch identifier {
            case .invisible, .info:
                break
            case .block(let blockItem):
                cell.update(with: blockItem)
            }
        }
        return cellRegistration
    }
    
    func getInfoCellRegistration() -> UICollectionView.CellRegistration<TagInfoCell, Item> {
        let cellRegistration = UICollectionView.CellRegistration<TagInfoCell, Item> { (cell, indexPath, identifier) in
            switch identifier {
            case .invisible, .block:
                break
            case .info(let infoItem):
                cell.update(with: infoItem)
            }
        }
        return cellRegistration
    }
}
