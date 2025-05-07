//
//  TagListViewController.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/3.
//

import Foundation
import UIKit
import SnapKit

class TagListViewController: UIViewController {
    enum Section: Int, Hashable {
        case main
    }
    
    var collectionView: UICollectionView!
    var dataSource: UICollectionViewDiffableDataSource<Section, TagCellItem>!
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        tabBarItem = UITabBarItem(title: String(localized: "controller.tags.title"), image: UIImage(systemName: "tag"), tag: 1)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("CalendarViewController is deinited")
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = String(localized: "controller.tags.title")
        
        view.backgroundColor = AppColor.background

        let doneBarItem = UIBarButtonItem(title: String(localized: "button.done"), style: .plain, target: self, action: #selector(close))
        doneBarItem.tintColor = AppColor.main
        navigationItem.rightBarButtonItem = doneBarItem
        
        let newBarItem = UIBarButtonItem(title: String(localized: "tags.new"), style: .plain, target: self, action: #selector(new))
        newBarItem.tintColor = AppColor.main
        toolbarItems = [newBarItem]
        navigationController?.setToolbarHidden(false, animated: false)
        
        configureHierarchy()
        configureDataSource()
        reloadData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .DatabaseUpdated, object: nil)
    }
    
    func createLayout() -> UICollectionViewLayout {
        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        configuration.backgroundColor = AppColor.background
        
        return UICollectionViewCompositionalLayout.list(using: configuration)
    }
    
    func configureHierarchy() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        view.addSubview(collectionView)
    }
    
    func configureDataSource() {
        // list cell
        let bookCellRegistration = UICollectionView.CellRegistration<TagListCell, TagCellItem> { [weak self] (cell, indexPath, item) in
            guard let self = self else { return }
            cell.detail = self.detailAccessoryForListCellItem(item)
            cell.update(with: item)
        }
        
        // data source
        dataSource = UICollectionViewDiffableDataSource<Section, TagCellItem>(collectionView: collectionView) { (collectionView, indexPath, item) -> UICollectionViewCell? in
            return collectionView.dequeueConfiguredReusableCell(using: bookCellRegistration, for: indexPath, item: item)
        }
        
        dataSource.reorderingHandlers.canReorderItem = { _ in
            return true
        }
        
        dataSource.reorderingHandlers.didReorder = { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateOrder()
            }
        }
    }
    
    @objc
    func reloadData() {
        guard let bookID = DataManager.shared.currentBook?.id else { return }
        var snapshot = NSDiffableDataSourceSnapshot<Section, TagCellItem>()
        snapshot.appendSections([.main])
        var items: [TagCellItem] = []
        if let tags = try? DataManager.shared.fetchAllTags(for: bookID) {
            items = tags.map{ TagCellItem(tag: $0) }
            snapshot.appendItems(items, toSection: .main)
        }
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    func detailAccessoryForListCellItem(_ item: TagCellItem) -> UICellAccessory {
        return UICellAccessory.detail(options: UICellAccessory.DetailOptions(reservedLayoutWidth: .custom(44), tintColor: AppColor.main), actionHandler: { [weak self] in
            self?.goToDetail(for: item)
        })
    }
    
    @objc
    func new() {
        guard let bookID = DataManager.shared.currentBook?.id else {
            return
        }
        var tagIndex = 0
        if let latestTag = DataManager.shared.tags.last {
            tagIndex = latestTag.order + 1
        }
        let newTag = Tag(bookID: bookID, title: "", color: "", order: tagIndex)
        let nav = NavigationController(rootViewController: TagDetailViewController(tag: newTag))
        
        navigationController?.present(nav, animated: true)
    }
    
    @objc
    func close() {
        dismiss(animated: true)
    }
    
    func goToDetail(for item: TagCellItem) {
        let nav = NavigationController(rootViewController: TagDetailViewController(tag: item.tag))

        navigationController?.present(nav, animated: true)
    }
    
    func updateOrder() {
        let tags = dataSource.snapshot().itemIdentifiers(inSection: .main)
        var newTags: [Tag] = []
        for (index, tag) in tags.enumerated() {
            var newOrderTag = tag.tag
            newOrderTag.order = index
            newTags.append(newOrderTag)
        }
        _ = DataManager.shared.update(tags: newTags)
    }
}

extension TagListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}
