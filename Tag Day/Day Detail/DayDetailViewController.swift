//
//  DayDetailViewController.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/9.
//

import UIKit
import SnapKit
import ZCCalendar

class DayDetailViewController: UIViewController {
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
        let button = UIButton(configuration: configuration)
        button.showsMenuAsPrimaryAction = true
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
        
        let newBarItem = UIBarButtonItem(systemItem: .add, menu: getMenu())
        newBarItem.tintColor = AppColor.main
        toolbarItems = [newBarItem]
        navigationController?.setToolbarHidden(false, animated: false)
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .DatabaseUpdated, object: nil)
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
        let cellRegistration = UICollectionView.CellRegistration<DayDetailCell, Item> { [weak self] (cell, indexPath, item) in
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
}

extension DayDetailViewController {
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
            section.interGroupSpacing = 40.0
            section.contentInsets = NSDirectionalEdgeInsets(top: 10.0, leading: 20.0, bottom: 10.0, trailing: 20.0)
            
            return section
        }, configuration: config)
        
        return layout
    }
}

extension DayDetailViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

extension DayDetailViewController: DayDetailCellDelegate {
    func getButtonMenu(for record: DayRecord) -> UIMenu {
        var children: [UIMenuElement] = []
        children = tags.map({ tag in
            return UIAction(title: tag.title, subtitle: tag.subtitle, image: UIImage(systemName: "square.fill")?.withTintColor(UIColor(string: tag.color) ?? .white, renderingMode: .alwaysOriginal), state: record.tagID == tag.id ? .on : .off) { _ in
                guard let tagID = tag.id, record.tagID != tagID else {
                    return
                }
                var newRecord = record
                newRecord.tagID = tagID
                _ = DataManager.shared.update(dayRecord: newRecord)
            }
        })
        let deleteAction = UIAction(title: String(localized: "button.delete"), subtitle: "", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
            self?.showDeleteAlert(for: record)
        }
        let currentPageDivider = UIMenu(title: "", options: .displayInline, children: [deleteAction])

        children.append(currentPageDivider)
        return UIMenu(title: String(localized: "dayDetail.tagMenu.title"), children: children)
    }
}

extension DayDetailViewController {
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
    
    func getMenu() -> UIMenu {
        let recordDay = day.julianDay
        var children: [UIMenuElement] = []
        children = tags.map({ tag in
            return UIAction(title: tag.title, subtitle: tag.subtitle, image: UIImage(systemName: "square.fill")?.withTintColor(UIColor(string: tag.color) ?? .white, renderingMode: .alwaysOriginal)) { [weak self] _ in
                guard let bookID = self?.book.id,let tagID = tag.id else {
                    return
                }
                let newRecord = DayRecord(bookID: bookID, tagID: tagID, day: Int64(recordDay))
                _ = DataManager.shared.add(dayRecord: newRecord)
            }
        })
        return UIMenu(title: "", children: children)
    }
}
