//
//  CalendarViewController+Layout.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/4/29.
//

import UIKit

extension CalendarViewController {
    func getDayRowSection(environment: NSCollectionLayoutEnvironment, cellHeight: CGFloat) -> NSCollectionLayoutSection {
        let containerWidth = environment.container.contentSize.width
        let itemWidth = DayGrid.itemWidth(in: containerWidth)
        let itemHeight = cellHeight
        let interSpacing = DayGrid.interSpacing
        let count: Int = DayGrid.countInRow

        let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(itemWidth),
                                             heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .absolute(itemHeight))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                         subitems: [item])
        group.interItemSpacing = .fixed(interSpacing)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = interSpacing
        
        let inset = (containerWidth - CGFloat(count)*itemWidth - CGFloat(count - 1) * interSpacing) / 2.0
        section.contentInsets = NSDirectionalEdgeInsets(top: interSpacing / 2.0, leading: inset, bottom: interSpacing / 2.0, trailing: inset)
        
        return section
    }
    
    func getInfoSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let containerWidth = environment.container.contentSize.width
        let itemWidth = DayGrid.itemWidth(in: containerWidth)
        let count: Int = DayGrid.countInRow
        let interSpacing = DayGrid.interSpacing

        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.25), heightDimension: .absolute(28.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(28.0))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.interItemSpacing = .flexible(4.0)
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 6.0
        
        let inset = (containerWidth - CGFloat(count)*itemWidth - CGFloat(count - 1) * interSpacing) / 2.0
        section.contentInsets = NSDirectionalEdgeInsets(top: interSpacing / 2.0 + 10.0, leading: inset, bottom: interSpacing / 2.0 + 20.0, trailing: inset)
        
        return section
    }
    
    func sectionProvider(index: Int, environment: NSCollectionLayoutEnvironment, cellHeight: CGFloat) -> NSCollectionLayoutSection? {
        if let section = dataSource.sectionIdentifier(for: index) {
            switch section {
            case .row:
                let section = getDayRowSection(environment: environment, cellHeight: cellHeight)
                
                let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                             heightDimension: .estimated(100))
                let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerSize,
                    elementKind: Self.sectionHeaderElementKind, alignment: .top)
                
                section.boundarySupplementaryItems = [sectionHeader]
                
                return section
            case .info:
                let section = getInfoSection(environment: environment)
                
                return section
            }
        } else {
            return nil
        }
    }
}
