//
//  TagCircleDayViewController.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/8/7.
//

import UIKit
import SnapKit
import ZCCalendar

protocol TagCircleDayActionHandler: NSObject {
    func remove(at index: Int)
    func update(tags: [Tag], at index: Int)
}

class TagCircleDayViewController: UIViewController {
    var book: Book!
    var tags: [Tag]?
    var currentTags: [Tag] = [] {
        didSet {
            handler?.update(tags: currentTags, at: index)
            reloadData()
        }
    }
    var index: Int!
    
    weak var handler: TagCircleDayActionHandler?
    
    enum Section: Hashable {
        case main
    }
    
    struct Item: Hashable {
        var index: Int
        var tag: Tag
    }
    
    var dataSource: UICollectionViewDiffableDataSource<Section, Item>! = nil
    var collectionView: UICollectionView! = nil
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(item: TagCircle.Item) {
        self.init(nibName: nil, bundle: nil)
        
        self.book = item.book
        self.currentTags = item.tags
        self.index = item.index
        self.title = item.title
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = AppColor.background
        
        accessibilityViewIsModal = true
        
        let deleteItem = UIBarButtonItem(title: String(localized: "tagCircle.remove"), style: .plain, target: self, action: #selector(removeAction))
        deleteItem.tintColor = UIColor.systemRed
        navigationItem.rightBarButtonItems = [deleteItem]
        
        let newBarItem = UIBarButtonItem(title: String(localized: "dayDetail.new"), style: .plain, target: self, action: #selector(newAction))
        newBarItem.tintColor = AppColor.dynamicColor
        
        let cancelItem = UIBarButtonItem(title: String(localized: "button.cancel"), style: .plain, target: self, action: #selector(dismissAction))
        cancelItem.tintColor = AppColor.dynamicColor
        
        toolbarItems = [newBarItem, .flexibleSpace(), cancelItem]
        navigationController?.setToolbarHidden(false, animated: false)
        
        configureCollectionView()
        configureDataSource()
        reloadData()
    }
    
    private func configureCollectionView() {
        collectionView = UIDraggableCollectionView(frame: CGRect.zero, collectionViewLayout: createLayout())
        collectionView.backgroundColor = AppColor.background
        collectionView.delegate = self
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }
    }
    
    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<RecordListCell, Item> { [weak self] (cell, indexPath, item) in
            guard let self = self else { return }
            cell.delegate = self
            if let tags = self.tags {
                cell.update(with: .init(day: ZCCalendar.manager.today, tags: tags, record: .init(bookID: book.id!, tagID: item.tag.id!, day: Int64(ZCCalendar.manager.today.julianDay), order: Int64(item.index))))
            }
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            let cell = collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemIdentifier)
            
            return cell
        })
    }
    
    @objc
    private func reloadData() {
        guard let bookID = book.id else { return }
        self.tags = (try? DataManager.shared.fetchAllTags(bookID: bookID)) ?? []
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        var items: [Item] = []
        for (index, tag) in currentTags.enumerated() {
            items.append(.init(index: index, tag: tag))
        }
        snapshot.appendItems(items, toSection: .main)

        dataSource.apply(snapshot, animatingDifferences: true) {
            if let navBar = self.navigationController?.navigationBar {
                UIAccessibility.post(notification: .screenChanged, argument: navBar)
            }
        }
    }
}

extension TagCircleDayViewController {
    func createLayout() -> UICollectionViewLayout {
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .vertical
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { index, environment in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                 heightDimension: .estimated(100))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                  heightDimension: .estimated(100))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                             subitems: [item])

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 16.0
            section.contentInsets = NSDirectionalEdgeInsets(top: 8.0, leading: 10.0, bottom: 8.0, trailing: 10.0)
            
            return section
        }, configuration: config)
        
        return layout
    }
}

extension TagCircleDayViewController: UICollectionViewDelegate {
    
}

extension TagCircleDayViewController: RecordListCellDelegate {
    func getButtonMenu(for record: DayRecord) -> UIMenu {
        let deleteAction = UIAction(title: String(localized: "button.delete"), subtitle: "", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
            let index = Int(record.order)
            self?.currentTags.remove(at: index)
        }
        
        return UIMenu(title: "", children: [deleteAction])
    }
    
    func handle(tag: Tag, in button: UIButton, for record: DayRecord) {
        let detailViewController = FastEditorViewController(day: ZCCalendar.manager.today, book: book, editMode: .replace(tag, record))
        detailViewController.delegate = self
        let nav = NavigationController(rootViewController: detailViewController)
        showPopoverView(at: button, contentViewController: nav, width: 240.0, height: 300.0)
    }
    
    func commentButton(for record: DayRecord) {
        //
    }
    
    func timeButton(for record: DayRecord) {
        //
    }
}

extension TagCircleDayViewController {
    @objc
    private func removeAction() {
        let handler = handler
        let index = index
        dismiss(animated: ConsideringUser.animated) {
            if let index = index {
                handler?.remove(at: index)
            }
        }
    }
    
    @objc
    private func newAction() {
        let detailViewController = FastEditorViewController(day: ZCCalendar.manager.today, book: book, editMode: .add)
        detailViewController.delegate = self
        let nav = NavigationController(rootViewController: detailViewController)
        
        let buttonView = toolbarItems?.first?.value(forKey: "view") as? UIView
        
        showPopoverView(at: buttonView ?? view, contentViewController: nav, width: 240.0, height: 300.0)
    }
    
    @objc
    private func dismissAction() {
        dismiss(animated: ConsideringUser.animated)
    }
}

extension TagCircleDayViewController {
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

extension TagCircleDayViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return true
    }
}

extension TagCircleDayViewController: FastEditorNavigator {
    func add(day: GregorianDay, tag: Tag) {
        currentTags.append(tag)
        
        // Dismiss
        presentedViewController?.dismiss(animated: ConsideringUser.animated)
    }
    
    func replace(day: GregorianDay, tag: Tag, for record: DayRecord) {
        let index = Int(record.order)
        currentTags[index] = tag
        
        // Dismiss
        presentedViewController?.dismiss(animated: ConsideringUser.animated)
    }
}
