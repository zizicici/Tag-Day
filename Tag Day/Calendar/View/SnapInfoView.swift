//
//  SnapInfoView.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/7/4.
//

import UIKit
import SnapKit

struct SnapDisplayData: Equatable, Hashable {
    let tag: Tag
    let records: [DayRecord]
}

class SnapInfoView: UIView {
    static let sectionHeaderElementKind = "sectionHeaderElementKind"

    enum Section: Hashable {
        case main
    }
    
    enum Item: Hashable {
        case info(SnapDisplayData)
        case record(SnapInfoItem)
    }
    
    private var displayData: SnapDisplayData? {
        didSet {
            if oldValue != displayData {
                reloadData()
            }
            if displayData != nil {
                if isHidden {
                    isHidden = false
                    UIView.animate(withDuration: animationDuration) {
                        self.alpha = 1
                    }
                }
                
                hideTask?.cancel()

                let task = DispatchWorkItem { [weak self] in
                    self?.hideWithAnimation()
                }
                hideTask = task
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: task)
            }
        }
    }
    
    private var collectionView: UICollectionView! = nil
    
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>! = nil
    
    private var hideTask: DispatchWorkItem?
    
    private var animationDuration: CGFloat = 0.3
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configureHierarchy()
        configureDataSource()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(displayData: SnapDisplayData) {
        self.displayData = displayData
    }
    
    private func configureHierarchy() {
        collectionView = UIDraggableCollectionView(frame: CGRect.zero, collectionViewLayout: createLayout())
        collectionView.backgroundColor = AppColor.paper
        collectionView.delaysContentTouches = false
        collectionView.canCancelContentTouches = true
        collectionView.scrollsToTop = false
        collectionView.delegate = self
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
        collectionView.showsVerticalScrollIndicator = false
        collectionView.layer.cornerRadius = 16.0
        collectionView.clipsToBounds = true
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .vertical
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { index, environment in
            let itemHeight = 40.0
            
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                 heightDimension: .estimated(itemHeight))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                  heightDimension: .estimated(itemHeight))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                             subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 10.0
            section.contentInsets = .init(top: 10, leading: 16, bottom: 16, trailing: 10)
            
            return section
        }, configuration: config)
        return layout
    }
    
    private func configureDataSource() {
        let tagInfoCellRegistration = UICollectionView.CellRegistration<TagInfoCell, Item> { [weak self] (cell, indexPath, identifier) in
            guard let self = self else { return }
            guard let displayData = self.displayData else { return }
            cell.update(with: InfoItem(tag: displayData.tag, count: displayData.records.count))
        }
        let recordCellRegistration = UICollectionView.CellRegistration<SnapInfoCell, Item> { (cell, indexPath, identifier) in
            switch identifier {
            case .info:
                break
            case .record(let item):
                cell.update(with: item)
            }
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: Item) -> UICollectionViewCell? in
            // Return the cell.
            switch identifier {
            case .info:
                return collectionView.dequeueConfiguredReusableCell(using: tagInfoCellRegistration, for: indexPath, item: identifier)
            case .record:
                return collectionView.dequeueConfiguredReusableCell(using: recordCellRegistration, for: indexPath, item: identifier)
            }
        }
    }
    
    func reloadData() {
        guard let displayData = displayData else { return }
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems([.info(displayData)], toSection: .main)
        snapshot.appendItems(displayData.records.enumerated().map{ .record(SnapInfoItem.init(dayRecord: $0.element, tag: displayData.tag, index: $0.offset)) }, toSection: .main)
        
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    private func hideWithAnimation() {
        UIView.animate(withDuration: animationDuration, animations: {
            self.alpha = 0
        }) { _ in
            self.isHidden = true
        }
    }
}

extension SnapInfoView: UICollectionViewDelegate {
    
}
