//
//  RecordListViewController.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/9.
//

import UIKit
import SnapKit
import ZCCalendar

protocol DayPresenter: AnyObject {
    func show(day: GregorianDay)
}

class RecordListViewController: UIViewController {
    var day: GregorianDay!
    var book: Book!
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
    
    convenience init(day: GregorianDay, book: Book) {
        self.init(nibName: nil, bundle: nil)
        
        self.day = day
        self.book = book
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
        
        let newBarItem = UIBarButtonItem(title: String(localized: "dayDetail.new"), style: .plain, target: self, action: #selector(newAction))
        newBarItem.tintColor = AppColor.dynamicColor
        toolbarItems = [newBarItem, .flexibleSpace()]
        navigationController?.setToolbarHidden(false, animated: false)
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .DatabaseUpdated, object: nil)
        
        // Auto Display Fast Editor
        if records.count == 0 {
            newAction()
        }
    }
    
    override func accessibilityPerformEscape() -> Bool {
        dismiss(animated: true)
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
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        collectionView.dragInteractionEnabled = true
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

        dataSource.apply(snapshot, animatingDifferences: true) {
            if let navBar = self.navigationController?.navigationBar {
                UIAccessibility.post(notification: .screenChanged, argument: navBar)
            }
        }
    }
    
    @objc
    private func newAction() {
        let detailViewController = FastEditorViewController(day: day, book: book, editMode: .add)
        detailViewController.delegate = self
        let nav = NavigationController(rootViewController: detailViewController)
        
        let buttonView = toolbarItems?.first?.value(forKey: "view") as? UIView
        
        showPopoverView(at: buttonView ?? view, contentViewController: nav, width: 240.0, height: 300.0)
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
            section.interGroupSpacing = 16.0
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

extension RecordListViewController: UICollectionViewDragDelegate {
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        if let item = dataSource.itemIdentifier(for: indexPath) {
            let tag = item.tag
            let itemProvider = NSItemProvider(object: tag.title as NSString)
            let dragItem = UIDragItem(itemProvider: itemProvider)
            dragItem.localObject = item
            return [dragItem]
        } else {
            return []
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        guard let cell = collectionView.cellForItem(at: indexPath) else {
            return nil
        }
        let previewParameters = UIDragPreviewParameters()
        previewParameters.visiblePath = UIBezierPath(rect: cell.bounds)
        previewParameters.backgroundColor = .clear
        previewParameters.shadowPath = UIBezierPath(rect: .zero)
        return previewParameters
    }
}

extension RecordListViewController: UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let destinationIndexPath = coordinator.destinationIndexPath else {
            return
        }
        switch coordinator.proposal.operation {
        case .cancel:
            break
        case .forbidden:
            break
        case .copy:
            break
        case .move:
            if let item = coordinator.items.first {
                if let cellItem = item.dragItem.localObject as? Item {
                    let sourceRecord = cellItem.record
                    if let destination = dataSource.itemIdentifier(for: destinationIndexPath) {
                        let destinationRecord = destination.record
                        var snapshot = dataSource.snapshot()
                        if let sourceIndexPath = item.sourceIndexPath, sourceIndexPath != destinationIndexPath {
                            snapshot.deleteItems([cellItem])
                            dataSource.apply(snapshot)
                            if sourceIndexPath.item < destinationIndexPath.item {
                                snapshot.insertItems([cellItem], afterItem: destination)
                            } else {
                                snapshot.insertItems([cellItem], beforeItem: destination)
                            }
                            dataSource.apply(snapshot)
                            updateRecordOrdering(from: sourceRecord, to: destinationRecord)
                        } else {
                            dataSource.apply(snapshot)
                        }
                    }
                }
            }
        @unknown default:
            fatalError()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if session.localDragSession != nil {
            if collectionView.hasActiveDrag {
                return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
            } else {
                return UICollectionViewDropProposal(operation: .cancel)
            }
        } else {
            return UICollectionViewDropProposal(operation: .forbidden)
        }
    }
}

extension RecordListViewController {
    private func updateRecordOrdering(from source: DayRecord, to destination: DayRecord) {
        guard let sourceIndex = records.firstIndex(where: { $0.id == source.id}), let destinationIndex = records.firstIndex(where: { $0.id == destination.id }), sourceIndex != destinationIndex else {
            return
        }
        var newOrderRecords = records
        let record = newOrderRecords.remove(at: sourceIndex)
        newOrderRecords.insert(record, at: destinationIndex)
        
        var saveRecords: [DayRecord] = []
        for (index, element) in newOrderRecords.enumerated() {
            var newOrderRecord = element
            newOrderRecord.order = Int64(index)
            saveRecords.append(newOrderRecord)
        }
        _ = DataManager.shared.update(dayRecords: saveRecords)
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
        
        let commentAction = UIAction(title: String(localized: "dayDetail.tagMenu.comment"), subtitle: "", image: UIImage(systemName: "text.bubble")) { [weak self] _ in
            self?.showRecordEditor(for: record, editMode: .comment)
        }
        
        let updateDivider = UIMenu(title: String(localized: "dayDetail.tagMenu.update"), options: .displayInline, children: [timeAction, commentAction])
        children.append(updateDivider)

        let deleteAction = UIAction(title: String(localized: "button.delete"), subtitle: "", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
            self?.showDeleteAlert(for: record)
        }
        
        let actionDivider = UIMenu(title: String(localized: "dayDetail.tagMenu.more"), children: [deleteAction])
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

extension RecordListViewController {
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
        let newRecord = DayRecord(bookID: bookID, tagID: tagID, day: Int64(day.julianDay), order: lastOrder + 1)
        if let savedRecord = DataManager.shared.add(dayRecord: newRecord) {
            // Dismiss
            presentedViewController?.dismiss(animated: true) {
                self.showRecordAlert(for: savedRecord)
            }
        }
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

extension UIViewController {
    func showRecordAlert(for record: DayRecord) {
        let timeAction = UIAlertAction(title: String(localized: "dayDetail.tagMenu.time"), style: .default) { [weak self] _ in
            self?.showRecordEditor(for: record, editMode: .time)
        }
        
        let commentAction = UIAlertAction(title: String(localized: "dayDetail.tagMenu.comment"), style: .default) { [weak self] _ in
            self?.showRecordEditor(for: record, editMode: .comment)
        }
        let cancelAction = UIAlertAction(title: String(localized: "button.cancel"), style: .cancel)
        
        if UIAccessibility.isVoiceOverRunning {
            let alertController = UIAlertController(title: String(localized: "dayDetail.tagMenu.alert.title"), message: nil, preferredStyle: .alert)
            alertController.addAction(timeAction)
            alertController.addAction(commentAction)
            alertController.addAction(cancelAction)
            
            present(alertController, animated: true)
        } else {
            var remainingTime: Int = 5

            let alertController = UIAlertController(title: String(localized: "dayDetail.tagMenu.alert.title"), message: String(format: String(localized: "dayDetail.tagMenu.alert.message%i"), remainingTime), preferredStyle: .actionSheet)
            alertController.addAction(timeAction)
            alertController.addAction(commentAction)
            alertController.addAction(cancelAction)
            
            present(alertController, animated: true)
            
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                remainingTime -= 1
                alertController.message = String(format: String(localized: "dayDetail.tagMenu.alert.message%i"), remainingTime)
                
                if remainingTime <= 0 {
                    timer.invalidate()
                    alertController.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
    
    func showRecordEditor(for record: DayRecord, editMode: RecordDetailViewController.EditMode) {
        let recordEditor = RecordDetailViewController(dayRecord: record, editMode: editMode)
        let nav = NavigationController(rootViewController: recordEditor)
        
        present(nav, animated: true)
    }
}

extension GregorianDay {
    public static func - (left: GregorianDay, right: Int) -> GregorianDay {
        return GregorianDay(JDN: left.julianDay - right)
    }
}
