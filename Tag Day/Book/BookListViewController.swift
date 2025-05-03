//
//  BookListViewController.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/3.
//

import Foundation
import UIKit
import SnapKit

class BookListViewController: UIViewController {
    enum Section: Int, Hashable {
        case active
        case archived
        
        var title: String {
            switch self {
            case .active:
                return String(localized: "bookType.active.title")
            case .archived:
                return String(localized: "bookType.archived.title")
            }
        }
    }
    
    var collectionView: UICollectionView!
    var dataSource: UICollectionViewDiffableDataSource<Section, BookCellItem>!
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        tabBarItem = UITabBarItem(title: String(localized: "controller.books.title"), image: UIImage(systemName: "book"), tag: 1)
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
        
        title = String(localized: "controller.books.title")
        
        view.backgroundColor = AppColor.background
        updateNavigationBarStyle()
        
        configureHierarchy()
        configureDataSource()
        applySnapshots()
    }
    
    func createLayout() -> UICollectionViewLayout {
        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        configuration.backgroundColor = AppColor.background
        configuration.headerMode = .supplementary
        configuration.headerTopPadding = 20.0
        
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
        let bookCellRegistration = UICollectionView.CellRegistration<BookListCell, BookCellItem> { (cell, indexPath, item) in
            cell.update(with: item)
        }
        
        let headerRegistration = UICollectionView.SupplementaryRegistration
        <HeaderReuseView>(elementKind: UICollectionView.elementKindSectionHeader) { [weak self] supplementaryView, elementKind, indexPath in
            guard let self = self else { return }
            guard let section = self.dataSource.sectionIdentifier(for: indexPath.section) else { fatalError("Unknown section") }
            
            supplementaryView.titleLabel.text = section.title
        }
        
        // data source
        dataSource = UICollectionViewDiffableDataSource<Section, BookCellItem>(collectionView: collectionView) { (collectionView, indexPath, item) -> UICollectionViewCell? in
            return collectionView.dequeueConfiguredReusableCell(using: bookCellRegistration, for: indexPath, item: item)
        }
        
        dataSource.supplementaryViewProvider = { collectionView, kind, index in
            return collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: index)
        }
    }
    
    func applySnapshots() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, BookCellItem>()
        snapshot.appendSections([.active])
        var items: [BookCellItem] = []
        if let activeBook = try? DataManager.shared.fetchAllBookInfos(bookType: .active) {
            items = activeBook.map{ BookCellItem(bookInfo: $0) }
            snapshot.appendItems(items, toSection: .active)
        }
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

extension BookListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}
