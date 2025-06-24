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
    
    enum Item: Hashable {
        case book(BookCellItem)
        case activeHint
        case archivedHint
        
        var title: String? {
            switch self {
            case .book:
                return nil
            case .activeHint:
                return String(localized: "bookType.active.hint")
            case .archivedHint:
                return String(localized: "bookType.archived.hint")
            }
        }
    }
    
    var collectionView: UICollectionView!
    var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        tabBarItem = UITabBarItem(title: String(localized: "controller.books.title"), image: UIImage(systemName: "book"), tag: 1)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("BookListViewController is deinited")
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = String(localized: "controller.books.title")
        
        view.backgroundColor = AppColor.background
        
        let doneBarItem = UIBarButtonItem(title: String(localized: "button.done"), style: .plain, target: self, action: #selector(close))
        doneBarItem.tintColor = AppColor.main
        navigationItem.rightBarButtonItem = doneBarItem
        
        let newBarItem = UIBarButtonItem(title: String(localized: "books.new"), style: .plain, target: self, action: #selector(new))
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
        let bookCellRegistration = UICollectionView.CellRegistration<BookListCell, BookCellItem> { [weak self] (cell, indexPath, item) in
            guard let self = self else { return }
            cell.detail = self.detailAccessoryForListCellItem(item)
            cell.update(with: item)
        }
        
        let hintCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> { (cell, indexPath, item) in
            var content = UIListContentConfiguration.valueCell()
            content.text = item.title
            content.textProperties.alignment = .center
            content.textProperties.color = .secondaryLabel
            cell.contentConfiguration = content
        }
        
        let headerRegistration = UICollectionView.SupplementaryRegistration
        <HeaderReuseView>(elementKind: UICollectionView.elementKindSectionHeader) { [weak self] supplementaryView, elementKind, indexPath in
            guard let self = self else { return }
            guard let section = self.dataSource.sectionIdentifier(for: indexPath.section) else { fatalError("Unknown section") }
            
            supplementaryView.titleLabel.text = section.title
        }
        
        // data source
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { (collectionView, indexPath, item) -> UICollectionViewCell? in
            switch item {
            case .activeHint, .archivedHint:
                return collectionView.dequeueConfiguredReusableCell(using: hintCellRegistration, for: indexPath, item: item)
            case .book(let bookCellItem):
                return collectionView.dequeueConfiguredReusableCell(using: bookCellRegistration, for: indexPath, item: bookCellItem)
            }
        }
        
        dataSource.supplementaryViewProvider = { collectionView, kind, index in
            return collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: index)
        }
        
        dataSource.reorderingHandlers.canReorderItem = { item in
            switch item {
            case .book:
                return true
            case .activeHint:
                return false
            case .archivedHint:
                return false
            }
        }
        
        dataSource.reorderingHandlers.didReorder = { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateOrder()
            }
        }
    }
    
    @objc
    func reloadData() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        // Active
        if let activeBooks = try? DataManager.shared.fetchAllBookInfos(for: .active) {
            snapshot.appendSections([.active])
            
            var items: [Item] = []
            if activeBooks.count == 0 {
                items = [.activeHint]
            } else {
                items = activeBooks.map{ Item.book(BookCellItem(bookInfo: $0)) }
            }
            
            snapshot.appendItems(items, toSection: .active)
        }
        // Archived
        if let archivedBooks = try? DataManager.shared.fetchAllBookInfos(for: .archived) {
            snapshot.appendSections([.archived])
            
            var items: [Item] = []
            if archivedBooks.count == 0 {
                items = [.archivedHint]
            } else {
                items = archivedBooks.map{ Item.book(BookCellItem(bookInfo: $0)) }
            }
            
            snapshot.appendItems(items, toSection: .archived)
        }
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    func detailAccessoryForListCellItem(_ item: BookCellItem) -> UICellAccessory {
        return UICellAccessory.detail(options: UICellAccessory.DetailOptions(reservedLayoutWidth: .custom(44), tintColor: AppColor.main), actionHandler: { [weak self] in
            self?.goToDetail(for: item)
        })
    }
    
    @objc
    func new() {
        let activeBooks = DataManager.shared.books.filter({ $0.bookType == .active }).sorted(by: { $0.order < $1.order })

        var bookOrder = 0
        if let lastestBook = activeBooks.last {
            bookOrder = lastestBook.order + 1
        }
        let newBook = Book(title: "", color: AppColor.main.generateLightDarkString(), order: bookOrder)
        let nav = NavigationController(rootViewController: BookDetailViewController(book: newBook))
        
        navigationController?.present(nav, animated: true)
    }
    
    @objc
    func close() {
        dismiss(animated: true)
    }
    
    func goToDetail(for item: BookCellItem) {
        let nav = NavigationController(rootViewController: BookDetailViewController(book: item.bookInfo.book))
        
        navigationController?.present(nav, animated: true)
    }
    
    func updateOrder() {
        var newBooks: [Book] = []

        // Active
        let activeBooks = dataSource.snapshot().itemIdentifiers(inSection: .active).compactMap { item in
            switch item {
            case .book(let cellItem):
                return cellItem.bookInfo.book
            default:
                return nil
            }
        }
        for (index, book) in activeBooks.enumerated() {
            var newOrderBook = book
            newOrderBook.bookType = .active
            newOrderBook.order = index
            newBooks.append(newOrderBook)
        }
        // Archived
        let archivedBooks = dataSource.snapshot().itemIdentifiers(inSection: .archived).compactMap { item in
            switch item {
            case .book(let cellItem):
                return cellItem.bookInfo.book
            default:
                return nil
            }
        }
        for (index, book) in archivedBooks.enumerated() {
            var newOrderBook = book
            newOrderBook.bookType = .archived
            newOrderBook.order = index
            newBooks.append(newOrderBook)
        }
        _ = DataManager.shared.update(books: newBooks)
    }
}

extension BookListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}
