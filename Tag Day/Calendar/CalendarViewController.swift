//
//  CalendarViewController.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/4/27.
//

import UIKit
import SnapKit
import ZCCalendar
import Collections

class CalendarViewController: CalendarBaseViewController, DisplayHandlerDelegate {
    static let sectionHeaderElementKind = "sectionHeaderElementKind"
    static let yearlyStatsHeaderElementKind = "yearlyStatsHeaderElementKind"
    
    static let monthTagElementKind: String = "monthTagElementKind"
    
    // UIBarButtonItem
        
    private var yearButton: UIBarButtonItem?
    private var settingsButton: UIBarButtonItem?
    private var actionButton: UIBarButtonItem?
    private var moreButton: UIBarButtonItem?
    
    // Search
    let searchController = UISearchController(searchResultsController: nil)

    // Data
    
    internal var dataSource: UICollectionViewDiffableDataSource<Section, Item>! = nil
    private var book: Book?
    private var tags: [Tag] = []
    private var records: [DayRecord] = []
    
    // Handler
    
    private var displayHandler: DisplayHandler!
    
    private var sectionRecordMaxCount: [Int: Int] = [:]
    
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
    
    private var calendarTransitionDelegate: CalendarTransitionDelegate?
    
    private var snapDisplayData: SnapDisplayData? = nil {
        didSet {
            if oldValue != snapDisplayData {
                if let displayData = snapDisplayData {
                    impactFeedbackGeneratorCoourred()
                    snapView.update(displayData: displayData)
                }
            }
        }
    }
    
    private var snapView: SnapInfoView = {
        let snapView = SnapInfoView(frame: .zero)
        snapView.isUserInteractionEnabled = false
        snapView.isHidden = true
        snapView.layer.shadowColor = UIColor.black.withAlphaComponent(0.1).cgColor
        snapView.layer.shadowRadius = 5.0
        snapView.layer.shadowOpacity = 0.5
        snapView.layer.shadowOffset = .zero
        
        return snapView
    }()

    // Debounce
    private var reloadDataDebounce: Debounce<Int>!
    
    private var searchDebounce: Debounce<String>!
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        displayHandler = DayDisplayHandler(delegate: self)
        
        tabBarItem = UITabBarItem(title: String(localized: "controller.calendar.title"), image: UIImage(systemName: "calendar"), tag: 0)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("CalendarViewController is deinited")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = AppColor.background
        
        configureHierarchy()
        configureDataSource()
        
        addGestures()
        
        settingsButton = UIBarButtonItem(image: UIImage(systemName: "slider.horizontal.2.square"), style: .plain, target: nil, action: nil)
        settingsButton?.accessibilityLabel = String(localized: "display.settings")
        settingsButton?.tintColor = AppColor.dynamicColor
        
        actionButton = UIBarButtonItem(image: UIImage(systemName: "square.grid.2x2"), style: .plain, target: nil, action: nil)
        actionButton?.accessibilityLabel = String(localized: "edit.action")
        actionButton?.tintColor = AppColor.dynamicColor
        
        moreButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), style: .plain, target: nil, action: nil)
        moreButton?.tintColor = AppColor.dynamicColor
        if #available(iOS 26.0, *) {
            moreButton?.sharesBackground = false
        } else {
            // Fallback on earlier versions
        }
        
        navigationItem.rightBarButtonItems = [moreButton, actionButton, settingsButton].compactMap{ $0 }
        
        yearButton = UIBarButtonItem(title: displayHandler.getTitle(), style: .plain, target: self, action: #selector(showYearPicker))
        yearButton?.tintColor = AppColor.dynamicColor
        navigationItem.leftBarButtonItems = [yearButton].compactMap{ $0 }
        
        reloadDataDebounce = Debounce(duration: 0.02, block: { [weak self] value in
            await self?.commit()
        })
        
        searchDebounce = Debounce(duration: 0.5, block: { [weak self] value in
            await self?.commit()
        })
        
        view.addSubview(snapView)
        snapView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view).inset(40)
            make.top.equalTo(view.safeAreaLayoutGuide).inset(40)
            make.height.equalTo(200)
        }
        
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = String(localized: "search")
        searchController.searchBar.tintColor = AppColor.dynamicColor
        
        NotificationCenter.default.addObserver(self, selector: #selector(needReload), name: .CurrentBookChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(needReload), name: .ActiveTagsUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(needReload), name: .DayRecordsUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(needReload), name: .TodayUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(needReload), name: .SettingsUpdate, object: nil)
    }
    
    @objc
    func needReload() {
        reloadDataDebounce.emit(value: 0)
    }
    
    func commit() {
        reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.reloadData()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func tap(in indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) else {
            return
        }
        guard let item = dataSource.itemIdentifier(for: indexPath) else {
            return
        }
        switch item {
        case .invisible:
            break
        case .empty:
            break
        case .block(let blockItem):
            impactFeedbackGeneratorCoourred()
            tap(in: cell, for: blockItem)
        case .info(let infoItem):
            impactFeedbackGeneratorCoourred()
            tap(in: cell, for: infoItem)
        }
    }
    
    override func hover(position: CGPoint) {
        if let lastIndexPath = lastIndexPath, let cell = collectionView.cellForItem(at: lastIndexPath) as? BlockCell, let item = dataSource.itemIdentifier(for: lastIndexPath) {
            switch item {
            case .block(let item):
                let positionInCell = cell.convert(position, from: collectionView)
                
                let tagData: [SnapDisplayData]
                switch item.tagDisplayType {
                case .normal:
                    tagData = item.records.compactMap { record in
                        item.tags.first(where: { $0.id == record.tagID }).map { .init(tag: $0, records: [record]) }
                    }
                case .aggregation:
                    var groupedRecords = OrderedDictionary<Int64, [DayRecord]>()
                    for record in item.records {
                        groupedRecords[record.tagID, default: []].append(record)
                    }
                    tagData = groupedRecords.compactMap { tagID, records in
                        item.tags.first(where: { $0.id == tagID }).map { .init(tag: $0, records: records) }
                    }
                }
                
                if let tagIndex = cell.getTagOrder(in: positionInCell) {
                    snapDisplayData = tagData[tagIndex]
                } else {
                    snapDisplayData = nil
                }
            default:
                snapDisplayData = nil
            }
        }
    }
    
    private func tap(in targetView: UIView, for blockItem: BlockItem) {
        guard let current = self.book else { return }
        if blockItem.records.count == 0 {
            let detailViewController = FastEditorViewController(day: blockItem.day, book: current, editMode: .add)
            detailViewController.delegate = self
            let nav = NavigationController(rootViewController: detailViewController)
            if !UIAccessibility.isVoiceOverRunning {
                showPopoverView(at: targetView, contentViewController: nav, width: 240.0, height: 300.0)
            } else {
                present(nav, animated: ConsideringUser.animated)
            }
        } else {
            let detailViewController = RecordListViewController(day: blockItem.day, book: current)
            detailViewController.dayPresenter = self
            let nav = NavigationController(rootViewController: detailViewController)
            if !UIAccessibility.isVoiceOverRunning {
                let cellFrame = targetView.convert(targetView.bounds, to: nil)
                nav.modalPresentationStyle = .custom
                calendarTransitionDelegate = CalendarTransitionDelegate(originFrame: cellFrame, cellBackgroundColor: AppColor.background, detailSize: CGSize(width: min(view.frame.width - 80.0, 300), height: min(view.frame.height * 0.7, 480)))
                nav.transitioningDelegate = calendarTransitionDelegate
            }
            present(nav, animated: ConsideringUser.animated)
        }
    }
    
    private func tap(in targetView: UIView, for infoItem: InfoItem) {
        guard let range = infoItem.displayRange else { return }
        let statisticViewController = TagStatisticsViewController(tag: infoItem.tag, start: range.start, end: range.end)
        let nav = NavigationController(rootViewController: statisticViewController)

        showPopoverView(at: targetView, contentViewController: nav, width: 280.0, height: 400.0)
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
    
    private func configureDataSource() {
        let blockCellRegistration = getBlockCellRegistration()
        let invisibleCellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, Item> { (cell, indexPath, identifier) in }
        let infoCellRegistration = getInfoCellRegistration()
        let emptyInfoCellRegistration = UICollectionView.CellRegistration<InfoEmptyCell, Item> { (cell, indexPath, identifier) in
            if case .empty(let text) = identifier {
                cell.update(text: text)
            }
        }
        
        let headerRegistration = UICollectionView.SupplementaryRegistration
        <MonthTitleSupplementaryView>(elementKind: Self.sectionHeaderElementKind) { [weak self] (supplementaryView, string, indexPath) in
            guard let self = self else { return }
            guard let section = self.dataSource.sectionIdentifier(for: indexPath.section) else { return }
            switch section {
            case .row(let gregorianMonth):
                let startWeekdayOrder = WeekdayOrder(rawValue: WeekStartType.current.rawValue) ?? WeekdayOrder.firstDayOfWeek
                let monthHeader = monthHeader(for: gregorianMonth)
                supplementaryView.update(monthText: monthHeader.month, yearText: monthHeader.year, startWeekOrder: startWeekdayOrder)
            case .info:
                break
            }
        }
        
        let yearlyHeaderRegistration = UICollectionView.SupplementaryRegistration
        <YearlyStatsSupplementaryView>(elementKind: Self.yearlyStatsHeaderElementKind) { [weak self] (supplementaryView, string, indexPath) in
            guard let self = self else { return }
            guard let section = self.dataSource.sectionIdentifier(for: indexPath.section) else { return }
            switch section {
            case .info(let gregorianMonth, .yearly):
                supplementaryView.update(title: yearlyStatsTitle(for: gregorianMonth.year))
            default:
                supplementaryView.update(title: nil)
            }
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { [weak self]
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: Item) -> UICollectionViewCell? in
            // Return the cell.
            guard let self = self else { return nil }
            guard let section = self.dataSource.sectionIdentifier(for: indexPath.section) else { fatalError("Unknown section") }
            switch section {
            case .row:
                switch identifier {
                case .block:
                    return collectionView.dequeueConfiguredReusableCell(using: blockCellRegistration, for: indexPath, item: identifier)
                case .invisible:
                    return collectionView.dequeueConfiguredReusableCell(using: invisibleCellRegistration, for: indexPath, item: identifier)
                case .info:
                    return nil
                case .empty:
                    return nil
                }
            case .info:
                switch identifier {
                case .block, .invisible:
                    return nil
                case .info:
                    return collectionView.dequeueConfiguredReusableCell(using: infoCellRegistration, for: indexPath, item: identifier)
                case .empty:
                    return collectionView.dequeueConfiguredReusableCell(using: emptyInfoCellRegistration, for: indexPath, item: identifier)
                }
            }
        }
        dataSource.supplementaryViewProvider = { [weak self] (view, kind, index) in
            guard let self = self else { return nil }
            if kind == Self.sectionHeaderElementKind {
                return self.collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: index)
            }
            if kind == Self.yearlyStatsHeaderElementKind {
                return self.collectionView.dequeueConfiguredReusableSupplementary(using: yearlyHeaderRegistration, for: index)
            }
            return nil
        }
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

    @objc
    internal func reloadData() {
        yearButton?.title = displayHandler.getTitle()
        
        updateMoreMenu()
        updateActionMenu()
        updateSettingsMenu()
        navigationItem.leftBarButtonItems?.forEach { $0.tintColor = AppColor.dynamicColor }
        navigationItem.rightBarButtonItems?.forEach { $0.tintColor = AppColor.dynamicColor }

        applyData()
    }
    
    private func applyData() {
        book = DataManager.shared.currentBook
        tags = DataManager.shared.activeTags
        records = DataManager.shared.dayRecords.filter({ dayRecord in
            if let searchText = self.searchText {
                return dayRecord.comment?.contains(searchText) == true
            } else {
                return true
            }
        })
        if let snapshot = displayHandler.getSnapshot(tags: tags, records: records) {
            sectionRecordMaxCount = getMaxRecordsPerSection(from: snapshot, activeTags: tags, shouldDeduplicate: getTagDisplayType() == .aggregation)
            dataSource.apply(snapshot, animatingDifferences: true) { [weak self] in
                guard let self = self, !self.didScrollToday else { return }
                self.didScrollToday = true
            }
            self.updateVisibleItems()
        }
    }
    
    func scroll(to day: GregorianDay, animated: Bool) {
        let item = dataSource.snapshot().itemIdentifiers.first { item in
            switch item {
            case .invisible, .info, .empty:
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
    
    private func updateSettingsMenu() {
        settingsButton?.menu = getSettingsMenu()
    }
    
    func getSettingsMenu() -> UIMenu {
        var children: [UIMenuElement] = []
        
        let tagDisplayMenu = getTagDisplayTypeMenu()
        let monthlyStatsMenu = getMonthlyStatsTypeMenu()
        let yearlyStatsMenu = getYearlyStatsTypeMenu()
        let todayIndicatorMenu = getTodayIndicatorMenu()
        let crossYearDisplayMenu = getCrossYearMonthDisplayMenu()
        
        children = [todayIndicatorMenu, crossYearDisplayMenu, tagDisplayMenu, monthlyStatsMenu, yearlyStatsMenu]
        
        if #available(iOS 26.0, *) {
        } else {
            children.append(getBookTitleDisplayMenu())
        }
        
        return UIMenu(children: children)
    }
    
    private func updateActionMenu() {
        var children: [UIMenuElement] = []
        
        let batchEditorAction = UIAction(title: String(localized: "controller.batchEditor.title"), image: UIImage(systemName: "square.grid.2x2")) { [weak self] _ in
            self?.showBatchEditor()
        }
        children.append(batchEditorAction)
        
        actionButton?.menu = UIMenu(children: children)
    }
    
    private func updateMoreMenu() {        
        moreButton?.menu = getMoreMenu()
    }
    
    func getMoreMenu() -> UIMenu {
        var children: [UIMenuElement] = []
        
        let calendarAction = UIAction(title: String(localized: "books.calendar"), image: UIImage(systemName: "calendar")) { [weak self] action in
            self?.showCalendar()
        }
        children.append(calendarAction)
        
        let searchAction = UIAction(title: String(localized: "search"), image: UIImage(systemName: "magnifyingglass")) { [weak self] _ in
            self?.showSearchBar()
        }
        children.append(searchAction)
        
        let moreAction = UIAction(title: String(localized: "controller.more.title"), image: UIImage(systemName: "ellipsis.circle")) { [weak self] _ in
            self?.showMore()
        }
        
        children.append(moreAction)
        
        return UIMenu(children: children)
    }
    
    func showCalendar() {
        let overviewViewController = OverviewViewController()
        
        navigationController?.present(NavigationController(rootViewController: overviewViewController), animated: ConsideringUser.animated)
    }
    
    @objc
    func showMore() {
        navigationController?.present(NavigationController(rootViewController: MoreViewController()), animated: ConsideringUser.animated)
    }
    
    @objc
    func showYearPicker() {
        let picker = CalendarYearPickerViewController(currentYear: self.displayHandler.getSelectedYear()) { [weak self] selectYear in
            self?.displayHandler.updateSelectedYear(to: selectYear)
        }
        
        let buttonView = navigationItem.leftBarButtonItem?.value(forKey: "view") as? UIView
        
        showPopoverView(at: buttonView ?? view, contentViewController: picker, width: 140)
    }
    
    var searchText: String? {
        if let text = searchController.searchBar.text, !text.isBlank, !text.isEmpty {
            return text
        } else {
            return nil
        }
    }
    
    @objc
    func showSearchBar() {
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.searchController.isActive = true
            self.searchController.searchBar.becomeFirstResponder()
        }
    }
    
    func showBatchEditor() {
        navigationController?.present(NavigationController(rootViewController: BatchEditorViewController()), animated: ConsideringUser.animated)
    }
}

extension CalendarViewController {
    public func display(to day: GregorianDay) {
        displayHandler.updateSelectedYear(to: day.year)
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            self.scroll(to: day, animated: ConsideringUser.animated)
        }
    }
}

extension CalendarViewController: FastEditorNavigator {
    func replace(day: GregorianDay, tag: Tag, for record: DayRecord) {
        //
    }
    
    func add(day: GregorianDay, tag: Tag) {
        guard let bookID = book?.id, let tagID = tag.id else {
            return
        }
        let lastOrder = DataManager.shared.fetchLastRecordOrder(bookID: bookID, day: Int64(day.julianDay))
        let newRecord = DayRecord(bookID: bookID, tagID: tagID, day: Int64(day.julianDay), order: lastOrder + 1)
        if let savedRecord = DataManager.shared.add(dayRecord: newRecord) {
            // Dismiss
            presentedViewController?.dismiss(animated: ConsideringUser.animated) { [weak self] in
                self?.showRecordAlert(for: savedRecord)
            }
        }
    }
}

extension CalendarViewController {
    func tap(day: GregorianDay) {
        let targetItem = dataSource.snapshot().itemIdentifiers.first { item in
            switch item {
            case .block(let blockItem):
                return blockItem.day == day
            case .invisible, .info, .empty:
                return false
            }
        }
        if let item = targetItem {
            if let indexPath = dataSource.indexPath(for: item) {
                collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: ConsideringUser.animated)
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.25) {
                    self.tap(in: indexPath)
                }
            }
        }
    }
}

extension CalendarViewController: DayPresenter {
    func show(day: GregorianDay) {
        guard let popover = presentedViewController?.popoverPresentationController else { return }
        guard let targetItem = dataSource.snapshot().itemIdentifiers.first (where: { item in
            switch item {
            case .block(let blockItem):
                return blockItem.day == day
            case .invisible, .info, .empty:
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

extension CalendarViewController {
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
}

extension CalendarViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        searchDebounce.emit(value: searchController.searchBar.text ?? "")
    }
}

extension CalendarViewController: UISearchControllerDelegate {
    func willPresentSearchController(_ searchController: UISearchController) {
        searchController.searchBar.tintColor = AppColor.dynamicColor
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        UIView.animate(withDuration: 0.2) {
            self.navigationItem.searchController = nil
        }
    }
}

private extension CalendarViewController {
    func monthHeader(for gregorianMonth: GregorianMonth) -> (month: String, year: String?) {
        let monthName = gregorianMonth.month.name
        let selectedYear = displayHandler.getSelectedYear()

        if CrossYearMonthDisplay.getValue() == .enable, gregorianMonth.year != selectedYear {
            let yearText = "\(gregorianMonth.year)"
            return (monthName, yearText)
        }

        return (monthName, nil)
    }
    
    func yearlyStatsTitle(for year: Int) -> String {
        return "\(year)"
    }
}

extension GregorianMonth {
    var startDay: GregorianDay {
        return ZCCalendar.manager.firstDay(at: month, year: year)
    }
    
    var endDay: GregorianDay {
        return ZCCalendar.manager.lastDay(at: month, year: year)
    }
}
