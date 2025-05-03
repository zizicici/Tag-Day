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
        updateNavigationBarStyle()
        
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
        let bookCellRegistration = UICollectionView.CellRegistration<TagListCell, TagCellItem> { (cell, indexPath, item) in
            cell.update(with: item)
        }
        
        // data source
        dataSource = UICollectionViewDiffableDataSource<Section, TagCellItem>(collectionView: collectionView) { (collectionView, indexPath, item) -> UICollectionViewCell? in
            return collectionView.dequeueConfiguredReusableCell(using: bookCellRegistration, for: indexPath, item: item)
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
}

extension TagListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}
