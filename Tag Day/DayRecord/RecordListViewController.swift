//
//  RecordListViewController.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/9.
//

import UIKit
import SnapKit
import ZCCalendar

class RecordListViewController: UIViewController {
    var day: GregorianDay!
    var book: Book!
    var tags: [Tag] = []
    var records: [DayRecord] = []
    
    enum Section: Hashable {
        case main
    }
    
    struct Item: Hashable {
        var tag: Tag
        var record: DayRecord
    }
    
    private var newButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.titleAlignment = .center
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer({ incoming in
            var outgoing = incoming
            outgoing.font = UIFont.preferredMonospacedFont(for: .body, weight: .medium)
            
            return outgoing
        })
        configuration.baseForegroundColor = AppColor.main
        configuration.title = String(localized: "dayDetail.new")
        configuration.contentInsets.leading = 4.0
        configuration.contentInsets.bottom = 16.0
        let button = UIButton(configuration: configuration)
        return button
    }()
    
    var dataSource: UICollectionViewDiffableDataSource<Section, Item>! = nil
    var collectionView: UICollectionView! = nil
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(day: GregorianDay, book: Book) {
        self.init(nibName: nil, bundle: nil)
        
        self.day = day
        self.book = book
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = AppColor.background
        
        self.title = day.formatString()
        
        configureCollectionView()
        configureDataSource()
        reloadData()
        
        let newBarItem = UIBarButtonItem(customView: newButton)
        newButton.addTarget(self, action: #selector(newAction), for: .touchUpInside)
        toolbarItems = [newBarItem, .flexibleSpace()]
        navigationController?.setToolbarHidden(false, animated: false)
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .DatabaseUpdated, object: nil)
        
        // Auto Display Fast Editor
        if records.count == 0 {
            newAction()
        }
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
        guard let bookID = book.id else { return }
        self.tags = (try? DataManager.shared.fetchAllTags(bookID: bookID)) ?? []
        self.records = (try? DataManager.shared.fetchAllDayRecords(bookID: bookID, day: Int64(self.day.julianDay))) ?? []
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        var items: [Item] = []
        for dayRecord in records {
            if let tag = tags.first(where: { $0.id == dayRecord.tagID }) {
                items.append(Item(tag: tag, record: dayRecord))
            }
        }
        snapshot.appendItems(items, toSection: .main)

        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    @objc
    private func newAction() {
        let detailViewController = FastEditorViewController(day: day, book: book, editMode: .add)
        detailViewController.delegate = self
        let nav = NavigationController(rootViewController: detailViewController)
        showPopoverView(at: newButton, contentViewController: nav, width: 240.0, height: 300.0)
    }
}

extension RecordListViewController {
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
            section.interGroupSpacing = 10.0
            section.contentInsets = NSDirectionalEdgeInsets(top: 8.0, leading: 10.0, bottom: 8.0, trailing: 10.0)
            
            return section
        }, configuration: config)
        
        return layout
    }
}

extension RecordListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

extension RecordListViewController: RecordListCellDelegate {
    func handle(tag: Tag, in button: UIButton, for record: DayRecord) {
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
        
        let walletAction = UIAction(title: String(localized: "dayDetail.tagMenu.wallet"), subtitle: "", image: UIImage(systemName: "arrow.left.arrow.right")) { [weak self] _ in
            self?.showRecordEditor(for: record, editMode: .comment)
        }
        
        let commentAction = UIAction(title: String(localized: "dayDetail.tagMenu.comment"), subtitle: "", image: UIImage(systemName: "text.bubble")) { [weak self] _ in
            self?.showRecordEditor(for: record, editMode: .comment)
        }
        
        let updateDivider = UIMenu(title: String(localized: "dayDetail.tagMenu.update"), options: .displayInline, children: [timeAction, walletAction, commentAction])
        children.append(updateDivider)

        let deleteAction = UIAction(title: String(localized: "button.delete"), subtitle: "", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
            self?.showDeleteAlert(for: record)
        }
        
        let actionDivider = UIMenu(title: String(localized: "dayDetail.tagMenu.more"), children: [deleteAction])
        children.append(actionDivider)
        
        return UIMenu(title: "", children: children)
    }
    
    func commentButton(for record: DayRecord) {
        self.showRecordEditor(for: record, editMode: .comment)
    }
}

extension RecordListViewController {
    func showRecordEditor(for record: DayRecord, editMode: RecordDetailViewController.EditMode) {
        let recordEditor = RecordDetailViewController(dayRecord: record, editMode: editMode)
        let nav = NavigationController(rootViewController: recordEditor)
        
        present(nav, animated: true)
    }
    
    func showDeleteAlert(for record: DayRecord) {
        guard record.id != nil else { return }
        
        let message = String(localized: "dayDetail.delete.alert.message")
        
        let alertController = UIAlertController(title: String(localized: "dayDetail.delete.alert.title"), message: message, preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: String(localized: "button.delete"), style: .destructive) { _ in
            alertController.dismiss(animated: true)
            _ = DataManager.shared.delete(dayRecord: record)
        }
        let cancelAction = UIAlertAction(title: String(localized: "button.cancel"), style: .cancel)
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
}

extension RecordListViewController: FastEditorNavigator {
    func reset(day: GregorianDay, tag: Tag?) {
        //
    }
    
    func add(day: GregorianDay, tag: Tag) {
        guard let bookID = book.id, let tagID = tag.id else {
            return
        }
        let lastOrder = DataManager.shared.fetchLastRecordOrder(bookID: bookID, day: Int64(day.julianDay))
        let newRecord = DayRecord(bookID: bookID, tagID: tagID, day: Int64(day.julianDay), order: lastOrder)
        _ = DataManager.shared.add(dayRecord: newRecord)
        
        // Dismiss
        presentedViewController?.dismiss(animated: true)
    }
    
    func replace(day: GregorianDay, tag: Tag, for record: DayRecord) {
        guard let tagID = tag.id, record.tagID != tagID else {
            return
        }
        var newRecord = record
        newRecord.tagID = tagID
        _ = DataManager.shared.update(dayRecord: newRecord)
        
        // Dismiss
        presentedViewController?.dismiss(animated: true)
    }
}

extension RecordListViewController {
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
        present(nav, animated: true, completion: nil)
        
        if let popover = nav.popoverPresentationController {
            popover.sourceView = sourceView
            popover.permittedArrowDirections = [.up, .down]
        }
    }
}

extension RecordListViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return true
    }
}
