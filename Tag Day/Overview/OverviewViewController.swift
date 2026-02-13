//
//  OverviewViewController.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/10/1.
//

import Foundation
import UIKit
import SnapKit
import ZCCalendar

class OverviewViewController: UIViewController {
    static let sectionHeaderElementKind = "sectionHeaderElementKind"
    
    enum Section: Hashable {
        case row(GregorianMonth)
    }
    
    enum Item: Hashable {
        case block(OverviewItem)
        case invisible(String)
    }
    
    private var yearButton: UIBarButtonItem?
    private var displayButton: UIBarButtonItem?
    
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>! = nil
    private var calendarTransitionDelegate: CalendarTransitionDelegate?
    
    private var books: [Book] = []
    private var tags: [Tag] = []
    private var records: [DayRecord] = []
    
    private var displayHandler: DisplayHandler!
    
    private var sectionRecordMaxCount: [Int: Int] = [:]
    
    private var isSymbol: Bool = false {
        didSet {
            reloadData()
        }
    }
    
    private var didScrollToday: Bool = false {
        willSet {
            if didScrollToday == false, newValue == true {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.25) { [weak self] in
                    guard let self = self else { return }
                    self.scroll(to: ZCCalendar.manager.today, animated: ConsideringUser.animated)
                }
            }
        }
    }
    
    private var collectionView: UIDraggableCollectionView! = nil
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        displayHandler = DayDisplayHandler(delegate: self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("OverviewViewController is deinited")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = AppColor.background
        
        title = String(localized: "books.calendar")
        
        yearButton = UIBarButtonItem(title: displayHandler.getTitle(), style: .plain, target: self, action: #selector(showYearPicker))
        yearButton?.tintColor = AppColor.dynamicColor
        navigationItem.leftBarButtonItems = [yearButton].compactMap{ $0 }
        
        displayButton = UIBarButtonItem(image: UIImage(systemName: "slider.horizontal.2.square"), style: .plain, target: nil, action: nil)
        displayButton?.tintColor = AppColor.dynamicColor
        navigationItem.rightBarButtonItems = [displayButton].compactMap{ $0 }
        
        configureHierarchy()
        configureDataSource()
        reloadData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .DatabaseUpdated, object: nil)
    }
    
    private func configureHierarchy() {
        collectionView = UIDraggableCollectionView(frame: CGRect.zero, collectionViewLayout: createLayout())
        collectionView.backgroundColor = AppColor.background
        collectionView.delaysContentTouches = false
        collectionView.canCancelContentTouches = true
        collectionView.scrollsToTop = true
        collectionView.delegate = self
        collectionView.keyboardDismissMode = .onDrag
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(view)
            make.leading.trailing.bottom.equalTo(view)
        }
        collectionView.scrollIndicatorInsets = UIEdgeInsets(top: 28.0, left: 0.0, bottom: 10.0, right: 0.0)
        collectionView.contentInset = .init(top: 0.0, left: 0.0, bottom: 100.0, right: 0.0)
    }
    
    private func configureDataSource() {
        let blockCellRegistration = UICollectionView.CellRegistration<BlockCell, Item> { (cell, indexPath, identifier) in
            switch identifier {
            case .block(let blockItem):
                cell.update(with: blockItem)
            case .invisible:
                break
            }
        }
        let invisibleCellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, Item> { (cell, indexPath, identifier) in }
        
        let headerRegistration = UICollectionView.SupplementaryRegistration
        <MonthTitleSupplementaryView>(elementKind: Self.sectionHeaderElementKind) { [weak self] (supplementaryView, string, indexPath) in
            guard let self = self else { return }
            guard let section = self.dataSource.sectionIdentifier(for: indexPath.section) else { return }
            switch section {
            case .row(let gregorianMonth):
                let month = gregorianMonth.month
                let startWeekdayOrder = WeekdayOrder(rawValue: WeekStartType.current.rawValue) ?? WeekdayOrder.firstDayOfWeek
                supplementaryView.update(monthText: month.name, yearText: nil, startWeekOrder: startWeekdayOrder)
            }
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { (collectionView: UICollectionView, indexPath: IndexPath, identifier: Item) -> UICollectionViewCell? in
            switch identifier {
            case .block:
                return collectionView.dequeueConfiguredReusableCell(using: blockCellRegistration, for: indexPath, item: identifier)
            case .invisible:
                return collectionView.dequeueConfiguredReusableCell(using: invisibleCellRegistration, for: indexPath, item: identifier)
            }
        }
        
        dataSource.supplementaryViewProvider = { [weak self] (view, kind, index) in
            return self?.collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: index)
        }
    }
}

extension OverviewViewController: DisplayHandlerDelegate {
    @objc
    func reloadData() {
        yearButton?.title = displayHandler.getTitle()
        displayButton?.menu = getSettingsMenu()
        
        books = (try? DataManager.shared.fetchAllBooks()) ?? []
        tags = (try? DataManager.shared.fetchAllTags()) ?? []
        records = (try? DataManager.shared.fetchAllDayRecords(after: Int64(displayHandler.getLeading()))) ?? []
        
        applyData()
    }
    
    func applyData() {
        let filterRecord = records.filter { record in
            return record.day <= displayHandler.getTrailing()
        }
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        
        let year = displayHandler.getSelectedYear()
        
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
            
            let items: [OverviewItem] = Array(1...ZCCalendar.manager.dayCount(at: month, year: year)).map({ day in
                let gregorianDay = GregorianDay(year: year, month: month, day: day)
                let julianDay = gregorianDay.julianDay
                
                let backgroundColor: UIColor = AppColor.paper
                let foregroundColor: UIColor = AppColor.text
                
//                let secondaryCalendar: String?
//                let a11ySecondaryCallendar: String?
//                switch SecondaryCalendar.getValue() {
//                case .none:
//                    secondaryCalendar = nil
//                    a11ySecondaryCallendar = secondaryCalendar
//                case .chineseCalendar:
//                    let chineseDayInfo = ChineseCalendarManager.shared.findChineseDayInfo(gregorianDay, variant: .chinese)
//                    if let solarTerm = ChineseCalendarManager.shared.getSolarTerm(for: gregorianDay) {
//                        secondaryCalendar = solarTerm.name
//                        a11ySecondaryCallendar = (chineseDayInfo?.pronounceString() ?? "") + solarTerm.name
//                    } else {
//                        secondaryCalendar = chineseDayInfo?.shortDisplayString()
//                        a11ySecondaryCallendar = chineseDayInfo?.pronounceString()
//                    }
//                case .rokuyo:
//                    if let kyureki = ChineseCalendarManager.shared.findChineseDayInfo(gregorianDay, variant: .kyureki) {
//                        secondaryCalendar = Rokuyo.get(at: kyureki).name
//                    } else {
//                        secondaryCalendar = nil
//                    }
//                    a11ySecondaryCallendar = secondaryCalendar
//                }
                
                let isToday: Bool = TodayIndicator.getValue() == .enable ? ZCCalendar.manager.isToday(gregorianDay: gregorianDay) : false
                
                let recordsInADay = filterRecord.filter{ $0.day == julianDay }
                let bookInfo = getBookCounts(records: recordsInADay, books: books)
                
                return OverviewItem(index: julianDay, backgroundColor: backgroundColor, foregroundColor: foregroundColor, isToday: isToday, bookInfo: bookInfo, isSymbol: isSymbol)
                
//                return BlockItem(index: julianDay, backgroundColor: backgroundColor, foregroundColor: foregroundColor, isToday: isToday, tags: tags, records: records.filter{ $0.day == gregorianDay.julianDay }, tagDisplayType: TagDisplayType.getValue(), secondaryCalendar: secondaryCalendar, a11ySecondaryCalendar: a11ySecondaryCallendar)
            })
            
            snapshot.appendItems(items.map{ Item.block($0) }, toSection: .row(gregorianMonth))
            sectionRecordMaxCount = getMaxRecordsPerSection(from: snapshot)
        }
        
        dataSource.apply(snapshot, animatingDifferences: true) { [weak self] in
            guard let self = self, !self.didScrollToday else { return }
            self.didScrollToday = true
        }
    }
    
    func getBookCounts(records: [DayRecord], books: [Book]) -> [OverviewItem.BookCount] {
        let recordCounts = records.reduce(into: [Int64: Int]()) { dict, record in
            dict[record.bookID, default: 0] += 1
        }
        
        return books.compactMap { book in
            guard let bookID = book.id, let count = recordCounts[bookID], count > 0 else {
                return nil
            }
            return .init(book: book, count: count)
        }
    }
    
    func getMaxRecordsPerSection(from snapshot: NSDiffableDataSourceSnapshot<Section, Item>) -> [Int: Int] {
        var result = [Int: Int]()
        
        for section in snapshot.sectionIdentifiers {
            let itemsInSection = snapshot.itemIdentifiers(inSection: section)
            
            let recordsCounts = itemsInSection.map { item -> Int in
                switch item {
                case .block(let overviewItem):
                    return overviewItem.bookInfo.count
                case .invisible:
                    return 0
                }
            }
            
            let maxRecords = recordsCounts.max() ?? 0
            
            if let index = snapshot.indexOfSection(section) {
                result[index] = maxRecords
            }
        }
        
        return result
    }
}

extension OverviewViewController {
    func getSettingsMenu() -> UIMenu {
        var children: [UIMenuElement] = []
        
        let tagDisplayMenu = getTagDisplayTypeMenu()
        
        children = [tagDisplayMenu]
        
        return UIMenu(children: children)
    }
    
    func getTagDisplayTypeMenu() -> UIMenu {
        let normalAction = UIAction(title: String(localized: "overview.normal"), state: isSymbol ? .off : .on) { [weak self] _ in
            self?.isSymbol = false
        }
        let symbolAction = UIAction(title: String(localized: "overview.symbol"), state: isSymbol ? .on : .off) { [weak self] _ in
            self?.isSymbol = true
        }
        let tagDisplayActions = [normalAction, symbolAction]
        let tagDisplayTypeMenu = UIMenu(title: String(localized: "overview.display"), subtitle: isSymbol ? symbolAction.title : normalAction.title, image: UIImage(systemName: "swatchpalette"), children: tagDisplayActions)
    
        return tagDisplayTypeMenu
    }
}

extension OverviewViewController {
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
    
    func sectionProvider(index: Int, environment: NSCollectionLayoutEnvironment, cellHeight: CGFloat) -> NSCollectionLayoutSection? {
        if dataSource.sectionIdentifier(for: index) != nil {
            let section = getDayRowSection(environment: environment, cellHeight: cellHeight)
            
            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                    heightDimension: .estimated(100))
            let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: Self.sectionHeaderElementKind, alignment: .top)
            
            section.boundarySupplementaryItems = [sectionHeader]
            
            return section
        } else {
            return nil
        }
    }
    
    func getDayRowSection(environment: NSCollectionLayoutEnvironment, cellHeight: CGFloat) -> NSCollectionLayoutSection {
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
}

extension OverviewViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        guard let cell = collectionView.cellForItem(at: indexPath) else {
            return
        }
        guard let item = dataSource.itemIdentifier(for: indexPath) else {
            return
        }
        
        switch item {
        case .block(let overviewItem):
            let detailViewController = OverviewListViewController(day: overviewItem.day)
            detailViewController.dayPresenter = self
            let nav = NavigationController(rootViewController: detailViewController)
            if !UIAccessibility.isVoiceOverRunning {
                let cellFrame = cell.convert(cell.bounds, to: nil)
                nav.modalPresentationStyle = .custom
                calendarTransitionDelegate = CalendarTransitionDelegate(originFrame: cellFrame, cellBackgroundColor: AppColor.background, detailSize: CGSize(width: min(view.frame.width - 80.0, 300), height: min(view.frame.height * 0.7, 480)))
                nav.transitioningDelegate = calendarTransitionDelegate
            }
            present(nav, animated: ConsideringUser.animated)
        case .invisible:
            break
        }
    }
}

extension OverviewViewController {
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
    
    @objc
    func showYearPicker() {
        let picker = CalendarYearPickerViewController(currentYear: self.displayHandler.getSelectedYear()) { [weak self] selectYear in
            self?.displayHandler.updateSelectedYear(to: selectYear)
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

extension OverviewViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return true
    }
}

extension OverviewViewController: DayPresenter {
    func show(day: GregorianDay) {
        guard let popover = presentedViewController?.popoverPresentationController else { return }
        guard let targetItem = dataSource.snapshot().itemIdentifiers.first (where: { item in
            switch item {
            case .block(let blockItem):
                return blockItem.day == day
            case .invisible:
                return false
            }
        }) else { return }
        guard let indexPath = dataSource.indexPath(for: targetItem) else { return }
        guard let cell = collectionView.cellForItem(at: indexPath) else { return }
        collectionView.scrollRectToVisible(cell.frame, animated: ConsideringUser.animated)
        
        popover.sourceView = cell
        popover.sourceRect = cell.bounds
    }
}
