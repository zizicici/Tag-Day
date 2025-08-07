//
//  TagCircleEditorViewController.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/8/6.
//

import Foundation
import UIKit
import SnapKit
import Collections

struct TagCircle {
    struct Item: Hashable {
        var index: Int
        var book: Book
        var tags: [Tag]
        var backgroundColor: UIColor
        var foregroundColor: UIColor
        
        var title: String {
            return String(format: String(localized: "tagCircle.index%d"), index + 1)
        }
        
        var recordString: String {
            if tags.count > 0 {
                return tags.map( { String(format: String(localized: "a11y.%@record%i"), $0.title, 1)} ).joined(separator: ",")
            } else {
                return String(localized: "a11y.no.records")
            }
        }
    }
}

class TagCircleEditorViewController: UIViewController {
    enum Item: Hashable {
        case item(TagCircle.Item)
        case add
    }
    
    private var collectionView: UICollectionView! = nil
    private var dataSource: UICollectionViewDiffableDataSource<Int, Item>! = nil
    private var sectionRecordMaxCount: Int {
        return tagCache.map { $0.count }.max() ?? 1
    }
    
    private(set) var tagCache: [[Tag]] = [] {
        didSet {
            applyData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = AppColor.background
        
        configureHierarchy()
        configureDataSource()
        
        applyData()
    }
    
    private func configureHierarchy() {
        let separator = UIView()
        separator.backgroundColor = UIColor.separator
        view.addSubview(separator)
        separator.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(view)
            make.height.equalTo(0.5)
        }
        
        let label = UILabel()
        label.text = String(localized: "tagCircle.title")
        label.textColor = AppColor.text
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.top.equalTo(view).inset(10.0)
            make.leading.equalTo(view).inset(20.0)
        }
        
        collectionView = UIDraggableCollectionView(frame: CGRect.zero, collectionViewLayout: createLayout())
        collectionView.backgroundColor = AppColor.background
        collectionView.delaysContentTouches = false
        collectionView.canCancelContentTouches = true
        collectionView.scrollsToTop = true
        collectionView.delegate = self
        collectionView.keyboardDismissMode = .onDrag
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(label.snp.bottom).offset(10.0)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalTo(view)
        }
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .horizontal
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { [weak self] _, environment in
            guard let self = self else {
                return nil
            }
            let displayCount = max(1, self.sectionRecordMaxCount)
            let cellHeight: CGFloat = 39.0 + 20.0 * CGFloat(displayCount) + 3.0 * (CGFloat(displayCount) - 1.0)
            
            return self.getDayRowSection(environment: environment, cellHeight: cellHeight)
        }, configuration: config)
        return layout
    }
    
    private func getDayRowSection(environment: NSCollectionLayoutEnvironment, cellHeight: CGFloat) -> NSCollectionLayoutSection {
        let containerWidth = environment.container.contentSize.width
        let itemWidth = DayGrid.itemWidth(in: containerWidth)
        let itemHeight = cellHeight
        let interSpacing = 6.0
        
        let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(itemWidth),
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(itemWidth),
                                               heightDimension: .absolute(itemHeight))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                       subitems: [item])
        group.interItemSpacing = .fixed(interSpacing)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = interSpacing
        section.boundarySupplementaryItems = []
        
        section.contentInsets = NSDirectionalEdgeInsets(top: 4.0, leading: 20.0, bottom: 10.0, trailing: 20.0)
        
        return section
    }
    
    private func configureDataSource() {
        let blockCellRegistration = getBlockCellRegistration()
        let addCellRegistration = getAddCellRegistration()
        
        dataSource = UICollectionViewDiffableDataSource<Int, Item>(collectionView: collectionView) { (collectionView: UICollectionView, indexPath: IndexPath, identifier: Item) -> UICollectionViewCell? in
            switch identifier {
            case .item:
                return collectionView.dequeueConfiguredReusableCell(using: blockCellRegistration, for: indexPath, item: identifier)
            case .add:
                return collectionView.dequeueConfiguredReusableCell(using: addCellRegistration, for: indexPath, item: identifier)
            }
        }
    }
    
    private func applyData() {
        guard let book = DataManager.shared.currentBook else { return }
        
        var snapshot = NSDiffableDataSourceSnapshot<Int, Item>()
        
        snapshot.appendSections([0])
        
        let tagCircleItems: [TagCircle.Item] = tagCache.enumerated().map { (key: Int, value: [Tag]) in
            return .init(index: key, book: book, tags: value, backgroundColor: AppColor.paper, foregroundColor: AppColor.text)
        }
        var items: [Item] = tagCircleItems.map{ .item($0) }
        items.append(.add)
        
        snapshot.appendItems(items, toSection: 0)
        
        dataSource.apply(snapshot)
    }
    
    private func editTagCircle(with item: TagCircle.Item, at cell: UICollectionViewCell) {
        let dayViewController = TagCircleDayViewController(item: item)
        dayViewController.handler = self
        let nav = NavigationController(rootViewController: dayViewController)
        showPopoverView(at: cell, contentViewController: nav)
    }
}

extension TagCircleEditorViewController {
    func getBlockCellRegistration() -> UICollectionView.CellRegistration<TagCircleCell, Item> {
        let cellRegistration = UICollectionView.CellRegistration<TagCircleCell, Item> { (cell, indexPath, identifier) in
            switch identifier {
            case .add:
                break
            case .item(let circleItem):
                cell.update(with: circleItem)
            }
        }
        return cellRegistration
    }
    
    func getAddCellRegistration() -> UICollectionView.CellRegistration<TagCircleAddCell, Item> {
        let cellRegistration = UICollectionView.CellRegistration<TagCircleAddCell, Item> { (cell, indexPath, identifier) in
            switch identifier {
            case .add:
                break
            case .item:
                break
            }
        }
        return cellRegistration
    }
}

extension TagCircleEditorViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        guard let item = dataSource.itemIdentifier(for: indexPath) else {
            return
        }
        switch item {
        case .item(let item):
            if let cell = collectionView.cellForItem(at: indexPath) {
                editTagCircle(with: item, at: cell)
            }
        case .add:
            tagCache.append([])
        }
    }
}

extension TagCircleEditorViewController: TagCircleDayActionHandler {
    func remove(at index: Int) {
        guard index < tagCache.count else { return }
        tagCache.remove(at: index)
    }
    
    func update(tags: [Tag], at index: Int) {
        guard index < tagCache.count else { return }
        tagCache[index] = tags
    }
}

extension TagCircleEditorViewController {
    func showPopoverView(at sourceView: UIView, contentViewController: UIViewController, width: CGFloat = 280.0, height: CGFloat? = nil, arrowDirections: UIPopoverArrowDirection = [.up, .down]) {
        let nav = contentViewController
        if let height = height {
            nav.preferredContentSize = CGSize(width: width, height: height)
        } else {
            let size = contentViewController.view.systemLayoutSizeFitting(CGSize(width: width, height: 1000), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
            nav.preferredContentSize = size
        }

        nav.modalPresentationStyle = .popover

        if let pres = nav.presentationController {
            pres.delegate = self
        }
        present(nav, animated: ConsideringUser.animated, completion: nil)

        if let popover = nav.popoverPresentationController {
            popover.sourceView = sourceView
            popover.sourceRect = sourceView.bounds
            popover.permittedArrowDirections = arrowDirections
        }
    }
}

extension TagCircleEditorViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return true
    }
}
