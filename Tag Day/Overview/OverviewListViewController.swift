//
//  OverviewListViewController.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/11/28.
//

import UIKit
import SnapKit
import ZCCalendar

class OverviewListViewController: UIViewController {
    var day: GregorianDay!
    var books: [Book] = []
    var tags: [Tag] = []
    var records: [DayRecord] = []
    
    weak var dayPresenter: DayPresenter?

    enum Section: Hashable {
        case main
    }
    
    struct Item: Hashable {
        var tag: Tag
        var record: DayRecord
    }
    
    var dataSource: UICollectionViewDiffableDataSource<Section, Item>! = nil
    var collectionView: UICollectionView! = nil
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(day: GregorianDay) {
        self.init(nibName: nil, bundle: nil)
        
        self.day = day
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = AppColor.background
        
        accessibilityViewIsModal = true
        
        updateTitle()
        
        let nextDayItem = UIBarButtonItem(image: UIImage(systemName: "chevron.forward", withConfiguration: UIImage.SymbolConfiguration(pointSize: 10.0, weight: .bold)), style: .plain, target: self, action: #selector(nextDayAction))
        nextDayItem.accessibilityLabel = String(localized: "a11y.forward")
        nextDayItem.tintColor = AppColor.text.withAlphaComponent(0.75)
        navigationItem.rightBarButtonItems = [nextDayItem]
        
        let preiviousDayItem = UIBarButtonItem(image: UIImage(systemName: "chevron.backward", withConfiguration: UIImage.SymbolConfiguration(pointSize: 10.0, weight: .bold)), style: .plain, target: self, action: #selector(previousDayAction))
        preiviousDayItem.accessibilityLabel = String(localized: "a11y.backward")
        preiviousDayItem.tintColor = AppColor.text.withAlphaComponent(0.75)
        navigationItem.leftBarButtonItem = preiviousDayItem
        
        configureCollectionView()
        configureDataSource()
        reloadData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .DatabaseUpdated, object: nil)
    }
    
    override func accessibilityPerformEscape() -> Bool {
        dismiss(animated: ConsideringUser.animated)
        return true
    }
    
    private func updateTitle() {
        self.title = day.formatString()
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
            cell.update(with: .init(day: self.day, tags: self.tags, record: item.record))
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            let cell = collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemIdentifier)
            
            return cell
        })
    }
    
    @objc
    private func reloadData() {
        books = (try? DataManager.shared.fetchAllBooks()) ?? []
        tags = (try? DataManager.shared .fetchAllTags()) ?? []
        records = (try? DataManager.shared.fetchAllDayRecords(at: Int64(day.julianDay))) ?? []
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        var items: [Item] = []
        
        for book in books {
            for dayRecord in records.filter({ $0.bookID == book.id }) {
                if let tag = tags.first(where: { $0.id == dayRecord.tagID }) {
                    items.append(Item(tag: tag, record: dayRecord))
                }
            }
        }
        
        snapshot.appendItems(items, toSection: .main)

        dataSource.apply(snapshot, animatingDifferences: true) {
            if let navBar = self.navigationController?.navigationBar {
                UIAccessibility.post(notification: .screenChanged, argument: navBar)
            }
        }
    }
    
    @objc
    private func nextDayAction() {
        dayPresenter?.show(day: day + 1)
        day = day + 1
        updateTitle()
        reloadData()
    }
    
    @objc
    private func previousDayAction() {
        dayPresenter?.show(day: day - 1)
        day = day - 1
        updateTitle()
        reloadData()
    }
    
    @objc
    private func presentingClose() {
        presentingViewController?.dismiss(animated: ConsideringUser.animated)
    }
}

extension OverviewListViewController {
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

extension OverviewListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

extension OverviewListViewController: RecordListCellDelegate {
    func handle(tag: Tag, in button: UIButton, for record: DayRecord) {
        guard let book = books.filter({ $0.id == tag.bookID }).first else { return }
        let detailViewController = FastEditorViewController(day: day, book: book, editMode: .replace(tag, record))
        detailViewController.delegate = self
        let nav = NavigationController(rootViewController: detailViewController)
        showPopoverView(at: button, contentViewController: nav, width: 240.0, height: 300.0)
    }
    
    func getButtonMenu(for record: DayRecord) -> UIMenu {
        var children: [UIMenuElement] = []
        
        let timeAction = UIAction(title: String(localized: "dayDetail.tagMenu.time"), subtitle: "", image: UIImage(systemName: "clock")) { [weak self] _ in
            self?.showRecordEditor(for: record, editMode: .time)
        }
        
        let commentAction = UIAction(title: String(localized: "dayDetail.tagMenu.comment"), subtitle: "", image: UIImage(systemName: "text.bubble")) { [weak self] _ in
            self?.showRecordEditor(for: record, editMode: .comment)
        }
        
        let updateDivider = UIMenu(title: String(localized: "dayDetail.tagMenu.update"), options: .displayInline, children: [timeAction, commentAction])
        children.append(updateDivider)

        let deleteAction = UIAction(title: String(localized: "button.delete"), subtitle: "", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
            self?.showDeleteAlert(for: record)
        }
        
        let actionDivider = UIMenu(title: String(localized: "dayDetail.tagMenu.more"), options: .displayInline, children: [deleteAction])
        children.append(actionDivider)
        
        return UIMenu(title: "", children: children)
    }
    
    func commentButton(for record: DayRecord) {
        showRecordEditor(for: record, editMode: .comment)
    }
    
    func timeButton(for record: DayRecord) {
        showRecordEditor(for: record, editMode: .time)
    }
}

extension OverviewListViewController: FastEditorNavigator {
    func add(day: GregorianDay, tag: Tag) {
        //
    }
    
    func replace(day: GregorianDay, tag: Tag, for record: DayRecord) {
        guard let tagID = tag.id, record.tagID != tagID else {
            return
        }
        var newRecord = record
        newRecord.tagID = tagID
        _ = DataManager.shared.update(dayRecord: newRecord)
        
        // Dismiss
        presentedViewController?.dismiss(animated: ConsideringUser.animated)
    }
}

extension OverviewListViewController {
    func showPopoverView(at sourceView: UIView, contentViewController: UIViewController, width: CGFloat = 280.0, height: CGFloat? = nil) {
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
            popover.permittedArrowDirections = [.up, .down]
        }
    }
}

extension OverviewListViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return true
    }
}
