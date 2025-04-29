//
//  CalendarViewController+CellRegistration.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/4/29.
//

import UIKit
import ZCCalendar

extension CalendarViewController {
    func getMonthSectionCellRegistration() -> UICollectionView.CellRegistration<MonthTitleCell, Item> {
        let cellRegistration = UICollectionView.CellRegistration<MonthTitleCell, Item> {(cell, indexPath, identifier) in
            switch identifier {
            case .block, .invisible:
                break
            case .month(let monthItem):
                cell.update(with: monthItem)
            }
        }
        return cellRegistration
    }
    
    func getBlockCellRegistration() -> UICollectionView.CellRegistration<BlockCell, Item> {
        let cellRegistration = UICollectionView.CellRegistration<BlockCell, Item> { (cell, indexPath, identifier) in
            switch identifier {
            case .invisible, .month:
                break
            case .block(let blockItem):
                cell.update(with: blockItem)
            }
        }
        return cellRegistration
    }
}
