//
//  BatchEditorViewController.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/8/2.
//

import Foundation
import UIKit
import SnapKit
import ZCCalendar

class BatchEditorViewController: UIViewController {
    static let sectionHeaderElementKind = "sectionHeaderElementKind"
    
    enum Section: Hashable {
        case row(GregorianMonth)
    }
    
    enum Item: Hashable {
        case block(BlockItem)
        case invisible(String)
        
        var records: [DayRecord] {
            switch self {
            case .block(let blockItem):
                return blockItem.records
            case .invisible:
                return []
            }
        }
        
        var blockDay: GregorianDay? {
            switch self {
            case .block(let blockItem):
                return blockItem.day
            case .invisible:
                return nil
            }
        }
    }
    
    private var yearButton: UIBarButtonItem?
    private var saveButton: UIBarButtonItem?
    private var cancelButton: UIBarButtonItem?
    private var stateButton: UIBarButtonItem?
    private var resetButton: UIBarButtonItem?
    private var replaceButton: UIBarButtonItem?
    private var appendButton: UIBarButtonItem?
    private var applyTagCircleButton: UIBarButtonItem?
    private var exitTagCircleButton: UIBarButtonItem?
    
    private var collectionView: UICollectionView! = nil
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>! = nil
    private var sectionRecordMaxCount: [Int: Int] = [:]
    
    private var currentYear: Int = 0 {
        didSet {
            updateYearButton()
            reloadData()
        }
    }
    private var book: Book?
    private var tags: [Tag] = []
    private var records: [DayRecord] = []
    
    // Select Items -> selectedDay -> Update Selected Items
    private var selectedDays: [GregorianDay] = [] {
        didSet {
            updateSelection()
            updateBottomBarItems()
        }
    }
    
    //
    private weak var tagCircleEditor: TagCircleEditorViewController?
    private var tagCircleContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.text
        
        return view
    }()
    private var isReplacing: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = AppColor.background
        
        book = DataManager.shared.currentBook
        tags = DataManager.shared.activeTags
        records = DataManager.shared.dayRecords
        
        setupTopBarItems()
        setupBottomBarItems()
        
        configureHierarchy()
        configureDataSource()
        
        updateBottomBarItems()
        
        currentYear = ZCCalendar.manager.today.year
        
        navigationController?.presentationController?.delegate = self
    }
    
    func setupTopBarItems() {
        saveButton = UIBarButtonItem(title: String(localized: "button.save"), style: .done, target: self, action: #selector(saveAction))
        saveButton?.tintColor = AppColor.dynamicColor
        
        cancelButton = UIBarButtonItem(title: String(localized: "button.cancel"), style: .plain, target: self, action: #selector(dismissAction))
        cancelButton?.tintColor = AppColor.dynamicColor
        
        navigationItem.rightBarButtonItems = [saveButton, cancelButton].compactMap{ $0 }
        
        yearButton = UIBarButtonItem(title: "", style: .plain, target: self, action: #selector(showYearPicker))
        yearButton?.tintColor = AppColor.dynamicColor
        navigationItem.leftBarButtonItems = [yearButton].compactMap{ $0 }
    }
    
    func setupBottomBarItems() {
        stateButton = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        stateButton?.tintColor = AppColor.dynamicColor
        stateButton?.menu = getStateMenu()
        
        resetButton = UIBarButtonItem(title: String(localized: "batchEditor.reset"), style: .plain, target: self, action: #selector(resetAction))
        resetButton?.tintColor = AppColor.dynamicColor
        
        replaceButton = UIBarButtonItem(title: String(localized: "batchEditor.replace"), style: .plain, target: nil, action: nil)
        replaceButton?.tintColor = AppColor.dynamicColor
        replaceButton?.menu = getReplaceMenu()
        
        appendButton = UIBarButtonItem(title: String(localized: "batchEditor.append"), style: .plain, target: nil, action: nil)
        appendButton?.tintColor = AppColor.dynamicColor
        appendButton?.menu = getAppendMenu()
        
        toolbarItems = [stateButton, .flexibleSpace(), resetButton, replaceButton, appendButton].compactMap{ $0 }
        navigationController?.setToolbarHidden(false, animated: false)
        
        applyTagCircleButton = UIBarButtonItem(title: String(localized: "batchEditor.apply"), style: .plain, target: self, action: #selector(applyTagCircleAction))
        applyTagCircleButton?.tintColor = AppColor.dynamicColor
        
        exitTagCircleButton = UIBarButtonItem(title: String(localized: "batchEditor.exit"), style: .plain, target: self, action: #selector(exitTagCircleAction))
        exitTagCircleButton?.tintColor = AppColor.dynamicColor
    }
    
    private func configureHierarchy() {
        collectionView = UIDraggableCollectionView(frame: CGRect.zero, collectionViewLayout: createLayout())
        collectionView.backgroundColor = AppColor.background
        collectionView.delaysContentTouches = false
        collectionView.canCancelContentTouches = true
        collectionView.scrollsToTop = true
        collectionView.delegate = self
        collectionView.keyboardDismissMode = .onDrag
        collectionView.isEditing = true
        collectionView.allowsSelectionDuringEditing = true
        collectionView.allowsMultipleSelectionDuringEditing = true
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = true
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(view)
            make.leading.trailing.bottom.equalTo(view)
        }
        collectionView.scrollIndicatorInsets = UIEdgeInsets(top: CGFloat.leastNormalMagnitude, left: 0.0, bottom: 0.0, right: 0.0)
        collectionView.contentInset = .init(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
    }
    
    private func configureDataSource() {
        let blockCellRegistration = getBlockCellRegistration()
        let invisibleCellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, Item> { (cell, indexPath, identifier) in }
        
        let headerRegistration = UICollectionView.SupplementaryRegistration
        <MonthTitleSupplementaryView>(elementKind: Self.sectionHeaderElementKind) { [weak self] (supplementaryView, string, indexPath) in
            guard let self = self else { return }
            guard let section = self.dataSource.sectionIdentifier(for: indexPath.section) else { return }
            switch section {
            case .row(let gregorianMonth):
                let month = gregorianMonth.month
                let startWeekdayOrder = WeekdayOrder(rawValue: WeekStartType.current.rawValue) ?? WeekdayOrder.firstDayOfWeek
                supplementaryView.update(text: month.name, startWeekOrder: startWeekdayOrder)
            }
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { [weak self]
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: Item) -> UICollectionViewCell? in
            guard let self = self else { return nil }
            guard let section = self.dataSource.sectionIdentifier(for: indexPath.section) else { fatalError("Unknown section") }
            switch section {
            case .row:
                switch identifier {
                case .block:
                    return collectionView.dequeueConfiguredReusableCell(using: blockCellRegistration, for: indexPath, item: identifier)
                case .invisible:
                    return collectionView.dequeueConfiguredReusableCell(using: invisibleCellRegistration, for: indexPath, item: identifier)
                }
            }
        }
        dataSource.supplementaryViewProvider = { (view, kind, index) in
            return self.collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: index)
        }
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .vertical
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { [weak self] index, environment in
            guard let self = self else {
                return nil
            }
            let displayCount = max(1, self.sectionRecordMaxCount[index] ?? 1)
            let cellHeight: CGFloat = 39.0 + 20.0 * CGFloat(displayCount) + 3.0 * (CGFloat(displayCount) - 1.0)
            
            return self.sectionProvider(index: index, environment: environment, cellHeight: cellHeight)
        }, configuration: config)
        return layout
    }
    
    private func sectionProvider(index: Int, environment: NSCollectionLayoutEnvironment, cellHeight: CGFloat) -> NSCollectionLayoutSection? {
        if let section = dataSource.sectionIdentifier(for: index) {
            switch section {
            case .row:
                let section = getDayRowSection(environment: environment, cellHeight: cellHeight)
                
                let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                        heightDimension: .estimated(100))
                let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerSize,
                    elementKind: Self.sectionHeaderElementKind, alignment: .top)
                
                section.boundarySupplementaryItems = [sectionHeader]
                
                return section
            }
        } else {
            return nil
        }
    }
    
    private func getDayRowSection(environment: NSCollectionLayoutEnvironment, cellHeight: CGFloat) -> NSCollectionLayoutSection {
        let containerWidth = environment.container.contentSize.width
        let itemWidth = DayGrid.itemWidth(in: containerWidth)
        let itemHeight = cellHeight
        let interSpacing = DayGrid.interSpacing
        let count: Int = DayGrid.countInRow
        
        let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(itemWidth),
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .absolute(itemHeight))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                       subitems: [item])
        group.interItemSpacing = .fixed(interSpacing)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = interSpacing
        
        let inset = (containerWidth - CGFloat(count)*itemWidth - CGFloat(count - 1) * interSpacing) / 2.0
        section.contentInsets = NSDirectionalEdgeInsets(top: interSpacing / 2.0, leading: inset, bottom: interSpacing / 2.0, trailing: inset)
        
        return section
    }
    
    @objc
    private func reloadData() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        
        let year = currentYear
        
        let firstDayOfWeek: WeekdayOrder = WeekdayOrder(rawValue: WeekStartType.current.rawValue) ?? WeekdayOrder.firstDayOfWeek
        
        for month in Month.allCases {
            let firstDay = GregorianDay(year: year, month: month, day: 1)
            let firstWeekOrder = firstDay.weekdayOrder()
            
            let firstOffset = (firstWeekOrder.rawValue - (firstDayOfWeek.rawValue % 7) + 7) % 7
            
            let gregorianMonth = GregorianMonth(year: year, month: month)
            
            snapshot.appendSections([.row(gregorianMonth)])
            if firstOffset >= 1 {
                snapshot.appendItems(Array(1...firstOffset).map({ index in
                    let uuid = "\(month)-\(index)"
                    return Item.invisible(uuid)
                }))
            }
            
            let items: [BlockItem] = Array(1...ZCCalendar.manager.dayCount(at: month, year: year)).map({ day in
                let gregorianDay = GregorianDay(year: year, month: month, day: day)
                let julianDay = gregorianDay.julianDay
                
                let backgroundColor: UIColor = AppColor.paper
                let foregroundColor: UIColor = AppColor.text
                
                let secondaryCalendar: String?
                let a11ySecondaryCallendar: String?
                switch SecondaryCalendar.getValue() {
                case .none:
                    secondaryCalendar = nil
                    a11ySecondaryCallendar = secondaryCalendar
                case .chineseCalendar:
                    let chineseDayInfo = ChineseCalendarManager.shared.findChineseDayInfo(gregorianDay, variant: .chinese)
                    if let solarTerm = ChineseCalendarManager.shared.getSolarTerm(for: gregorianDay) {
                        secondaryCalendar = solarTerm.name
                        a11ySecondaryCallendar = (chineseDayInfo?.pronounceString() ?? "") + solarTerm.name
                    } else {
                        secondaryCalendar = chineseDayInfo?.shortDisplayString()
                        a11ySecondaryCallendar = chineseDayInfo?.pronounceString()
                    }
                case .rokuyo:
                    if let kyureki = ChineseCalendarManager.shared.findChineseDayInfo(gregorianDay, variant: .kyureki) {
                        secondaryCalendar = Rokuyo.get(at: kyureki).name
                    } else {
                        secondaryCalendar = nil
                    }
                    a11ySecondaryCallendar = secondaryCalendar
                }
                
                let isToday: Bool = false
                
                return BlockItem(index: julianDay, backgroundColor: backgroundColor, foregroundColor: foregroundColor, isToday: isToday, tags: tags, records: records.filter{ $0.day == gregorianDay.julianDay }, tagDisplayType: TagDisplayType.getValue(), secondaryCalendar: secondaryCalendar, a11ySecondaryCalendar: a11ySecondaryCallendar)
            })
            
            snapshot.appendItems(items.map{ Item.block($0) }, toSection: .row(gregorianMonth))
        }
        
        sectionRecordMaxCount = getMaxRecordsPerSection(from: snapshot, activeTags: tags, shouldDeduplicate: TagDisplayType.getValue() == .aggregation)
        
        dataSource.apply(snapshot, animatingDifferences: false) { [weak self] in
            self?.updateSelection()
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                self?.scroll(to: ZCCalendar.manager.today, animated: true)
            }
        }
    }
    
    func getMaxRecordsPerSection(from snapshot: NSDiffableDataSourceSnapshot<Section, Item>, activeTags: [Tag], shouldDeduplicate: Bool) -> [Int: Int] {
        var result = [Int: Int]()
        
        for section in snapshot.sectionIdentifiers {
            let itemsInSection = snapshot.itemIdentifiers(inSection: section)
            
            // 计算每个item的records数量（考虑去重）
            let recordsCounts = itemsInSection.map { item -> Int in
                if shouldDeduplicate {
                    // 去重逻辑：基于tagID属性去重
                    let uniqueRecords = item.records.reduce(into: [Int64: DayRecord]()) { result, record in
                        if activeTags.first(where: {$0.id == record.tagID}) != nil {
                            result[record.tagID] = record
                        }
                    }
                    return uniqueRecords.count
                } else {
                    return item.records.filter({activeTags.map({$0.id}).compactMap({$0}).contains([$0.tagID])} ).count
                }
            }
            
            // 找出当前section中的最大records数量
            let maxRecords = recordsCounts.max() ?? 0
            
            if let index = snapshot.indexOfSection(section) {
                result[index] = maxRecords
            }
        }
        
        return result
    }
    
    func scroll(to day: GregorianDay, animated: Bool) {
        let item = dataSource.snapshot().itemIdentifiers.first { item in
            switch item {
            case .invisible:
                return false
            case .block(let blockItem):
                if blockItem.day == day {
                    return true
                } else {
                    return false
                }
            }
        }
        if let item = item, let indexPath = dataSource.indexPath(for: item) {
            collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: animated)
        }
    }
}

extension BatchEditorViewController {
    func addTagCircleEditor() {
        let tagCircleEditor = TagCircleEditorViewController()
        guard let editorView = tagCircleEditor.view else { return }
        
        addChild(tagCircleEditor)
        view.addSubview(editorView)
        tagCircleEditor.didMove(toParent: self)
        
        editorView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            make.height.equalTo(140.0)
        }
        
        self.tagCircleEditor = tagCircleEditor
        
        toolbarItems = [exitTagCircleButton, .flexibleSpace(), applyTagCircleButton].compactMap{ $0 }
    }
    
    func removeTagCircleEditor() {
        tagCircleEditor?.willMove(toParent: nil)
        tagCircleEditor?.view.removeFromSuperview()
        tagCircleEditor?.removeFromParent()
        tagCircleEditor = nil
        
        toolbarItems = [stateButton, .flexibleSpace(), resetButton, replaceButton, appendButton].compactMap{ $0 }
    }
    
    @objc
    func exitTagCircleAction() {
        removeTagCircleEditor()
    }
    
    @objc
    func applyTagCircleAction() {
        if let tagCirle = tagCircleEditor?.tagCache, tagCirle.count > 0 {
            var newRecords: [DayRecord] = []
            if isReplacing {
                let targetDays: [Int64] = selectedDays.map{ Int64($0.julianDay) }
                
                newRecords = records.filter({ record in
                    return !targetDays.contains(record.day)
                })
            } else {
                newRecords = records
            }
            
            var addRecords: [DayRecord] = []
            
            let tagCirleDayCount = tagCirle.count
            let sortedDay = selectedDays.sorted(by: { $0.julianDay < $1.julianDay })
            for (dayIndex, day) in sortedDay.enumerated() {
                let tags = tagCirle[dayIndex % tagCirleDayCount]
                
                let lastOrder: Int64 = newRecords.filter({ $0.day == Int64(day.julianDay) }).map({ $0.order }).max() ?? -1
                
                addRecords.append(contentsOf: tags.enumerated().map({ (tagIndex, tag) in
                    var newValue: Int64 = Int64(UUID().hashValue)
                    if newValue > 0 {
                        newValue *= -1
                    }
                    let newRecord = DayRecord(id: newValue, bookID: tag.bookID, tagID: tag.id ?? 0, day: Int64(day.julianDay), order: lastOrder + 1 + Int64(tagIndex))
                    return newRecord
                }))
            }
            
            records = newRecords + addRecords
            
            reloadData()
        }
        removeTagCircleEditor()
    }
}

extension BatchEditorViewController {
    func updateBottomBarItems() {
        let count = selectedDays.count
        let isEnabled = count > 0
        updateStateButton(count: count)
        stateButton?.isEnabled = isEnabled
        resetButton?.isEnabled = isEnabled
        replaceButton?.isEnabled = isEnabled
        appendButton?.isEnabled = isEnabled
    }
    
    @objc
    func resetAction() {
        let targetDays: [Int64] = selectedDays.map{ Int64($0.julianDay) }
        
        records = records.filter({ record in
            return !targetDays.contains(record.day)
        })
        
        reloadData()
    }
    
    func getReplaceMenu() -> UIMenu {
        let tagElements: [UIMenuElement] = tags.reversed().map({ tag in
            return UIAction(title: tag.title, subtitle: tag.subtitle, image: UIImage(systemName: "rectangle.fill")?.withTintColor(tag.dynamicColor, renderingMode: .alwaysOriginal)) { [weak self] _ in
                self?.replaceSelectedDay(tag: tag)
            }
        })
        let singleSelectionMenu = UIMenu(title: String(localized: "batchEditor.singleTag"), image: UIImage(systemName: "tag"), children: tagElements)
        
        let tagsCircleAction: UIAction = UIAction(title: String(localized: "batchEditor.tagsCircle"), image: UIImage(systemName: "repeat")) { [weak self] _ in
            self?.isReplacing = true
            self?.addTagCircleEditor()
        }
        
        return UIMenu(children: [singleSelectionMenu, tagsCircleAction].reversed())
    }
    
    func getAppendMenu() -> UIMenu {
        let tagElements: [UIMenuElement] = tags.reversed().map({ tag in
            return UIAction(title: tag.title, subtitle: tag.subtitle, image: UIImage(systemName: "rectangle.fill")?.withTintColor(tag.dynamicColor, renderingMode: .alwaysOriginal)) { [weak self] _ in
                self?.appendSelectedDay(tag: tag)
            }
        })
        let singleSelectionMenu = UIMenu(title: String(localized: "batchEditor.singleTag"), image: UIImage(systemName: "tag"), children: tagElements)
        
        let tagsCircleAction: UIAction = UIAction(title: String(localized: "batchEditor.tagsCircle"), image: UIImage(systemName: "repeat")) { [weak self] _ in
            self?.isReplacing = false
            self?.addTagCircleEditor()
        }
        
        return UIMenu(children: [singleSelectionMenu, tagsCircleAction].reversed())
    }
    
    func getStateMenu() -> UIMenu {
        let clearSelectionAction: UIAction = UIAction(title: String(localized: "batchEditor.clearSelection"), image: UIImage(systemName: "xmark.square")) { [weak self] _ in
            self?.deselectAllSelected()
        }
        return UIMenu(children: [clearSelectionAction])
    }
    
    func deselectAllSelected() {
        selectedDays.removeAll()
    }
    
    func replaceSelectedDay(tag: Tag) {
        let targetDays: [Int64] = selectedDays.map{ Int64($0.julianDay) }
        
        var newRecords = records.filter({ record in
            return !targetDays.contains(record.day)
        })
        
        newRecords.append(contentsOf: selectedDays.map({ day in
            var newValue: Int64 = Int64(UUID().hashValue)
            if newValue > 0 {
                newValue *= -1
            }
            let newRecord = DayRecord(id: newValue, bookID: tag.bookID, tagID: tag.id ?? 0, day: Int64(day.julianDay), order: 0)
            return newRecord
        }))
        
        records = newRecords
        
        reloadData()
    }
    
    func appendSelectedDay(tag: Tag) {
        var newRecords = records
        
        newRecords.append(contentsOf: selectedDays.map({ day in
            var newValue: Int64 = Int64(UUID().hashValue)
            if newValue > 0 {
                newValue *= -1
            }
            let lastOrder: Int64 = records.filter({ $0.day == Int64(day.julianDay) }).map({ $0.order }).max() ?? -1
            let newRecord = DayRecord(id: newValue, bookID: tag.bookID, tagID: tag.id ?? 0, day: Int64(day.julianDay), order: lastOrder + 1)
            return newRecord
        }))
        
        records = newRecords
        
        reloadData()
    }
}

extension BatchEditorViewController {
    func getAddRecords() -> [DayRecord] {
        let addRecords = records.filter{ ($0.id ?? 0) < 0 }
        return addRecords
    }
    
    func getDeleteRecords() -> [DayRecord] {
        let storedRecords = DataManager.shared.dayRecords
        let deleteRecords = storedRecords.filter { record in
            !records.contains(record)
        }
        return deleteRecords
    }
    
    func updateYearButton() {
        yearButton?.title = String(format: (String(localized: "calendar.title.year%i")), currentYear)
    }
    
    func updateStateButton(count: Int) {
        stateButton?.title = String(format: String(localized: "batchEditor.choose%d"), count)
    }
    
    @objc
    func saveAction() {
        let addRecords = getAddRecords()
        let deleteRecords = getDeleteRecords()

        guard !(addRecords.count == 0 && deleteRecords.count == 0) else {
            dismissAction()
            return
        }
        let alertController = UIAlertController(title: String(localized: "batchEditor.alert.save.title"), message: String(format: String(localized: "batchEditor.alert.save.message%d%d"), addRecords.count, deleteRecords.count), preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: String(localized: "button.cancel"), style: .cancel) { _ in
            //
        }
        let okAction = UIAlertAction(title: String(localized: "button.ok"), style: .default) { [weak self] _ in
            self?.update(add: addRecords, delete: deleteRecords)
        }

        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        present(alertController, animated: ConsideringUser.animated, completion: nil)
    }
    
    func update(add: [DayRecord], delete: [DayRecord]) {
        _ = DataManager.shared.delete(dayRecords: delete)
        _ = DataManager.shared.add(dayRecords: add.map({ dayRecord in
            var newRecord = dayRecord
            newRecord.id = nil
            return newRecord
        }))
        
        dismiss(animated: ConsideringUser.animated)
    }
    
    @objc
    func dismissAction() {
        let addRecords = getAddRecords()
        let deleteRecords = getDeleteRecords()
        if addRecords.count == 0 && deleteRecords.count == 0 {
            dismiss(animated: ConsideringUser.animated)
        } else {
            showDismissAlert()
        }
    }
    
    func showDismissAlert() {
        let alertController = UIAlertController(title: String(localized: "batchEditor.alert.dismiss.title"), message: nil, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: String(localized: "button.cancel"), style: .cancel) { _ in
            //
        }
        let okAction = UIAlertAction(title: String(localized: "button.confirm"), style: .default) { [weak self] _ in
            self?.dismiss(animated: ConsideringUser.animated)
        }

        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        present(alertController, animated: ConsideringUser.animated, completion: nil)
    }
    
    @objc
    func showYearPicker() {
        let picker = CalendarYearPickerViewController(currentYear: self.currentYear) { [weak self] selectYear in
            self?.currentYear = selectYear
        }
        
        let buttonView = navigationItem.leftBarButtonItem?.value(forKey: "view") as? UIView
        
        showPopoverView(at: buttonView ?? view, contentViewController: picker, width: 140)
    }
    
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

extension BatchEditorViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        if (presentationController.presentedViewController as? NavigationController)?.children.first == self {
            let addRecords = getAddRecords()
            let deleteRecords = getDeleteRecords()
            if addRecords.count == 0 && deleteRecords.count == 0 {
                return true
            } else {
                showDismissAlert()
                return false
            }
        } else {
            return true
        }
    }
}

extension BatchEditorViewController {
    func addDayIfNeeded(_ day: GregorianDay) {
        guard !selectedDays.contains(day) else { return }
        selectedDays.append(day)
    }
    
    func removeDayIfNeeded(_ day: GregorianDay) {
        guard selectedDays.contains(day) else { return }
        selectedDays.removeAll(where: { $0 == day })
    }
    
    func updateSelection() {
        let items = dataSource.snapshot().itemIdentifiers.filter { item in
            if let day = item.blockDay {
                return self.selectedDays.contains(day)
            } else {
                return false
            }
        }
        let indexPaths = items.compactMap { item in
            dataSource.indexPath(for: item)
        }
        if indexPaths.count == 0, (collectionView.indexPathsForSelectedItems?.count ?? 0) > 0 {
            for indexPath in collectionView.indexPathsForSelectedItems ?? [] {
                collectionView.deselectItem(at: indexPath, animated: true)
            }
        } else {
            for indexPath in indexPaths {
                if collectionView.indexPathsForSelectedItems?.contains(indexPath) == true {
                    // Do nothing
                } else {
                    collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
                }
            }
        }
    }
}

extension BatchEditorViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return false }
        switch item {
        case .block:
            return true
        case .invisible:
            return false
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = dataSource.itemIdentifier(for: indexPath)
        if let day = item?.blockDay {
            addDayIfNeeded(day)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let item = dataSource.itemIdentifier(for: indexPath)
        if let day = item?.blockDay {
            removeDayIfNeeded(day)
        }
    }
}

extension BatchEditorViewController {
    func getBlockCellRegistration() -> UICollectionView.CellRegistration<BlockCell, Item> {
        let cellRegistration = UICollectionView.CellRegistration<BlockCell, Item> { (cell, indexPath, identifier) in
            switch identifier {
            case .invisible:
                break
            case .block(let blockItem):
                cell.update(with: blockItem)
            }
        }
        return cellRegistration
    }
}
