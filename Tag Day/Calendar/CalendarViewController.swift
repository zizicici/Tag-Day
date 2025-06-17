//
//  CalendarViewController.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/4/27.
//

import UIKit
import SnapKit
import Toast
import ZCCalendar

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
                    self.scrollToToday()
                }
            }
        }
    }
    
    private var editMode: EditMode = .normal
    
    // Debounce
    private var reloadDataDebounce: Debounce<Int>!
    
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
        
        settingsButton = UIBarButtonItem(image: UIImage(systemName: "slider.horizontal.2.square", withConfiguration: UIImage.SymbolConfiguration(weight: .medium)), style: .plain, target: nil, action: nil)
        settingsButton?.tintColor = AppColor.main
        
        moreButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis", withConfiguration: UIImage.SymbolConfiguration(weight: .medium)), style: .plain, target: self, action: #selector(moreAction))
        moreButton?.tintColor = AppColor.main
        
        navigationItem.rightBarButtonItems = [moreButton, settingsButton].compactMap{ $0 }
        
        yearButton = UIBarButtonItem(title: displayHandler.getTitle(), style: .plain, target: self, action: #selector(showYearPicker))
        yearButton?.tintColor = AppColor.main
        navigationItem.leftBarButtonItems = [yearButton].compactMap{ $0 }
        
        reloadDataDebounce = Debounce(duration: 0.02, block: { [weak self] value in
            await self?.commit()
        })
        
        NotificationCenter.default.addObserver(self, selector: #selector(currentBookNeedReload), name: .CurrentBookChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(needReload), name: .ActiveTagsUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(needReload), name: .DayRecordsUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(needReload), name: .TodayUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(needReload), name: .SettingsUpdate, object: nil)
    }
    
    @objc
    func currentBookNeedReload() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) { [weak self] in
            guard let self = self else { return }
            self.scrollToToday()
        }
        needReload()
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
            impactFeedbackGeneratorCoourred()
            tap(in: cell, for: infoItem)
        }
    }
    
    override func hover(in indexPath: IndexPath) {
        super.hover(in: indexPath)
        guard let blockItem = dataSource.itemIdentifier(for: indexPath) else {
            return
        }
        switch blockItem {
        case .invisible:
            break
        case .block(let blockItem):
            let style = ToastStyle.getStyle(messageColor: blockItem.foregroundColor, backgroundColor: blockItem.backgroundColor)
            view.makeToast(blockItem.calendarString, position: .top, style: style)
        case .info:
            break
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
                showPopoverView(at: targetView, contentViewController: nav, width: 240.0, height: 300.0)
            } else {
                let detailViewController = RecordListViewController(day: blockItem.day, book: current)
                detailViewController.dayPresenter = self
                let nav = NavigationController(rootViewController: detailViewController)
                showPopoverView(at: targetView, contentViewController: nav, width: 280.0, height: 400.0)
            }
        case .overwrite:
            let detailViewController = FastEditorViewController(day: blockItem.day, book: current, editMode: .overwrite)
            detailViewController.delegate = self
            let nav = NavigationController(rootViewController: detailViewController)
            showPopoverView(at: targetView, contentViewController: nav, width: 240.0, height: 300.0)
        }
    }
    
    private func tap(in targetView: UIView, for infoItem: InfoItem) {
        let statisticViewController = TagStatisticsViewController(tag: infoItem.tag, start: infoItem.month.startDay, end: infoItem.month.endDay)
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
            var cellHeight: CGFloat = DayGrid.itemHeight(in: environment.container.contentSize.width)
            if let count = self.sectionRecordMaxCount[index], count > 1 {
                cellHeight = 39.0 + 20.0 * CGFloat(count) + 3.0 * (CGFloat(count) - 1.0)
            }
            
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
        collectionView.scrollsToTop = false
        collectionView.delegate = self
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

        applyData()
    }
    
    private func applyData() {
        book = DataManager.shared.currentBook
        tags = DataManager.shared.activeTags
        records = DataManager.shared.dayRecords
        if let snapshot = displayHandler.getSnapshot(tags: tags, records: records) {
            sectionRecordMaxCount = getMaxRecordsPerSection(from: snapshot, shouldDeduplicate: getTagDisplayType() == .aggregation)
            dataSource.apply(snapshot, animatingDifferences: true) { [weak self] in
                guard let self = self, !self.didScrollToday else { return }
                self.didScrollToday = true
            }
            self.updateVisibleItems()
        }
    }
    
    func scrollToToday(animated: Bool = true) {
        let item = dataSource.snapshot().itemIdentifiers.first { item in
            switch item {
            case .invisible, .info:
                return false
            case .block(let blockItem):
                if blockItem.day == ZCCalendar.manager.today {
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
        
        let displayDivider = UIMenu(title: "", options: [.displayInline], children: [tagDisplayMenu, monthlyStatsMenu])
        
        children.append(displayDivider)

        let editActions: [UIAction] = [EditMode.normal, EditMode.overwrite].map { mode in
            return UIAction(title: mode.title, subtitle: mode.subtitle, image: UIImage(systemName: mode.image), attributes: mode.attributes, state: editMode == mode ? .on : .off) { [weak self] _ in
                self?.switchEditMode(to: mode)
            }
        }
        
        let editModeDivider = UIMenu(title: String(localized: "editMode.title"), subtitle: editMode.title, image: UIImage(systemName: editMode.image), options: editMode.options, children: editActions)
        children.append(editModeDivider)
        
        return UIMenu(children: children)
    }
    
    private func updateMoreMenu() {        
        moreButton?.menu = getMoreMenu()
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
        navigationController?.present(NavigationController(rootViewController: MoreViewController()), animated: true)
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
            presentedViewController?.dismiss(animated: true) { [weak self] in
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
        presentedViewController?.dismiss(animated: true) {
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
                collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: true)
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
        collectionView.scrollRectToVisible(cell.frame, animated: true)
        
        popover.sourceView = cell
    }
}

extension CalendarViewController {
    func getMaxRecordsPerSection(from snapshot: NSDiffableDataSourceSnapshot<Section, Item>, shouldDeduplicate: Bool) -> [Int: Int] {
        var result = [Int: Int]()
        
        for section in snapshot.sectionIdentifiers {
            let itemsInSection = snapshot.itemIdentifiers(inSection: section)
            
            // 计算每个item的records数量（考虑去重）
            let recordsCounts = itemsInSection.map { item -> Int in
                if shouldDeduplicate {
                    // 去重逻辑：基于tagID属性去重
                    let uniqueRecords = item.records.reduce(into: [Int64: DayRecord]()) { result, record in
                        result[record.tagID] = record
                    }
                    return uniqueRecords.count
                } else {
                    return item.records.count
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

extension GregorianMonth {
    var startDay: GregorianDay {
        return ZCCalendar.manager.firstDay(at: month, year: year)
    }
    
    var endDay: GregorianDay {
        return ZCCalendar.manager.lastDay(at: month, year: year)
    }
}
