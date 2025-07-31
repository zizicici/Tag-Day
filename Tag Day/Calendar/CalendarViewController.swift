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
    
    enum EditMode {
        case normal
        case overwrite
        
        var image: String {
            switch self {
            case .normal:
                return "pencil"
            case .overwrite:
                return "bolt"
            }
        }
        
        var title: String {
            switch self {
            case .normal:
                return String(localized: "editMode.normal")
            case .overwrite:
                return String(localized: "editMode.overwrite")
            }
        }
        
        var subtitle: String? {
            switch self {
            case .normal:
                return String(localized: "editMode.normal.hint")
            case .overwrite:
                return String(localized: "editMode.overwrite.hint")
            }
        }
        
        var attributes: UIMenuElement.Attributes {
            switch self {
            case .normal:
                return []
            case .overwrite:
                return [.destructive]
            }
        }
        
        var options: UIMenu.Options {
            switch self {
            case .normal:
                return []
            case .overwrite:
                return [.destructive]
            }
        }
    }
    
    static let monthTagElementKind: String = "monthTagElementKind"
    
    // UIBarButtonItem
        
    private var yearButton: UIBarButtonItem?
    private var settingsButton: UIBarButtonItem?
    private var moreButton: UIBarButtonItem?
    
    // Search
    let searchController = UISearchController(searchResultsController: nil)

    // Data
    
    internal var dataSource: UICollectionViewDiffableDataSource<Section, Item>! = nil
    private var book: Book? {
        didSet {
            if oldValue?.id != book?.id {
                // Book Changed
                switchEditMode(to: .normal)
            }
        }
    }
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
    
    private var editMode: EditMode = .normal
    
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
        
        let searchButton = UIBarButtonItem(image: UIImage(systemName: "magnifyingglass.circle", withConfiguration: UIImage.SymbolConfiguration(weight: .medium)), style: .plain, target: self, action: #selector(showSearchBar))
        searchButton.accessibilityLabel = String(localized: "search")
        searchButton.tintColor = AppColor.dynamicColor
        
        settingsButton = UIBarButtonItem(image: UIImage(systemName: "slider.horizontal.2.square", withConfiguration: UIImage.SymbolConfiguration(weight: .medium)), style: .plain, target: nil, action: nil)
        settingsButton?.accessibilityLabel = String(localized: "display.settings")
        settingsButton?.tintColor = AppColor.dynamicColor
        
        moreButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis", withConfiguration: UIImage.SymbolConfiguration(weight: .medium)), style: .plain, target: self, action: #selector(moreAction))
        moreButton?.tintColor = AppColor.dynamicColor
        
        navigationItem.rightBarButtonItems = [moreButton, settingsButton, searchButton].compactMap{ $0 }
        
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
        case .block(let blockItem):
            impactFeedbackGeneratorCoourred()
            tap(in: cell, for: blockItem)
        case .info(let infoItem):
            guard case .info(let gregorianMonth) = dataSource.sectionIdentifier(for: indexPath.section) else { return }
            impactFeedbackGeneratorCoourred()
            tap(in: cell, for: infoItem, month: gregorianMonth)
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
        switch editMode {
        case .normal:
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
        case .overwrite:
            let detailViewController = FastEditorViewController(day: blockItem.day, book: current, editMode: .overwrite)
            detailViewController.delegate = self
            let nav = NavigationController(rootViewController: detailViewController)
            showPopoverView(at: targetView, contentViewController: nav, width: 240.0, height: 300.0)
        }
    }
    
    private func tap(in targetView: UIView, for infoItem: InfoItem, month: GregorianMonth) {
        let statisticViewController = TagStatisticsViewController(tag: infoItem.tag, start: month.startDay, end: month.endDay)
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
        
        let headerRegistration = UICollectionView.SupplementaryRegistration
        <MonthTitleSupplementaryView>(elementKind: Self.sectionHeaderElementKind) { [weak self] (supplementaryView, string, indexPath) in
            guard let self = self else { return }
            guard let section = self.dataSource.sectionIdentifier(for: indexPath.section) else { return }
            switch section {
            case .row(let gregorianMonth):
                let month = gregorianMonth.month
                let startWeekdayOrder = WeekdayOrder(rawValue: WeekStartType.current.rawValue) ?? WeekdayOrder.firstDayOfWeek
                supplementaryView.update(text: month.name, startWeekOrder: startWeekdayOrder)
            case .info:
                break
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
                }
            case .info:
                switch identifier {
                case .block, .invisible:
                    return nil
                case .info:
                    return collectionView.dequeueConfiguredReusableCell(using: infoCellRegistration, for: indexPath, item: identifier)
                }
            }
        }
        dataSource.supplementaryViewProvider = { (view, kind, index) in
            return self.collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: index)
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
        
//        updateMoreMenu()
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
            case .invisible, .info:
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
        let todayIndicatorMenu = getTodayIndicatorMenu()
        
        children = [todayIndicatorMenu, tagDisplayMenu, monthlyStatsMenu]
        
        if #available(iOS 26.0, *) {
        } else {
            children.append(getBookTitleDisplayMenu())
        }
        
        return UIMenu(children: children)
    }
    
    private func updateMoreMenu() {        
        moreButton?.menu = getMoreMenu()
    }
    
    private func getEditModeDivider() -> UIMenu {
        let editActions: [UIAction] = [EditMode.normal, EditMode.overwrite].map { mode in
            return UIAction(title: mode.title, subtitle: mode.subtitle, image: UIImage(systemName: mode.image), attributes: mode.attributes, state: editMode == mode ? .on : .off) { [weak self] _ in
                self?.switchEditMode(to: mode)
            }
        }
        
        return UIMenu(title: String(localized: "editMode.title"), subtitle: editMode.title, image: UIImage(systemName: editMode.image), options: editMode.options, children: editActions)
    }
    
    func getMoreMenu() -> UIMenu {
        var children: [UIMenuElement] = []
        
        let moreAction = UIAction(title: String(localized: "controller.more.title"), image: UIImage(systemName: "ellipsis.circle")) { [weak self] _ in
            self?.moreAction()
        }

        children.append(moreAction)
        
        return UIMenu(children: children)
    }
    
    @objc
    func moreAction() {
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
    
    func switchEditMode(to editMode: EditMode) {
        self.editMode = editMode
        updateSettingsMenu()
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
    
    func reset(day: GregorianDay, tag: Tag?) {
        guard let bookID = book?.id else { return }
        let result = DataManager.shared.resetDayRecord(bookID: bookID, day: Int64(day.julianDay))
        if result, let tag = tag, let tagID = tag.id {
            _ = DataManager.shared.add(dayRecord: DayRecord(bookID: bookID, tagID: tagID, day: Int64(day.julianDay), order: 0))
        }
        
        // Dismiss
        presentedViewController?.dismiss(animated: ConsideringUser.animated) {
            self.tap(day: day + 1)
        }
    }
}

extension CalendarViewController {
    func tap(day: GregorianDay) {
        let targetItem = dataSource.snapshot().itemIdentifiers.first { item in
            switch item {
            case .block(let blockItem):
                return blockItem.day == day
            case .invisible, .info:
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
            case .invisible, .info:
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

extension GregorianMonth {
    var startDay: GregorianDay {
        return ZCCalendar.manager.firstDay(at: month, year: year)
    }
    
    var endDay: GregorianDay {
        return ZCCalendar.manager.lastDay(at: month, year: year)
    }
}
