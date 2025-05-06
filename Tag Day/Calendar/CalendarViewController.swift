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
    static let monthTagElementKind: String = "monthTagElementKind"
    
    // UI
    
    private var weekdayOrderView: WeekdayOrderView!
    
    // UIBarButtonItem
        
    private var moreButton: UIBarButtonItem?
    private var yearPickerButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.titleAlignment = .center
        configuration.cornerStyle = .capsule
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer({ incoming in
            var outgoing = incoming
            outgoing.font = UIFont.preferredMonospacedFont(for: .body, weight: .medium)
            
            return outgoing
        })
        let button = UIButton(configuration: configuration)
        button.showsMenuAsPrimaryAction = false
        button.tintColor = AppColor.main
        return button
    }()

    // Data
    
    internal var dataSource: UICollectionViewDiffableDataSource<Section, Item>! = nil
    
    // Handler
    
    private var displayHandler: DisplayHandler!
    
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
        updateNavigationBarStyle(hideShadow: true)
        weekdayOrderView = WeekdayOrderView(itemCount: 7, itemWidth: DayGrid.itemWidth(in: view.frame.width), interSpacing: DayGrid.interSpacing)
        weekdayOrderView.backgroundColor = AppColor.navigationBar
        view.addSubview(weekdayOrderView)
        weekdayOrderView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalTo(view).inset(-15.0)
            make.height.equalTo(30.0)
        }
        weekdayOrderView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        weekdayOrderView.layer.cornerRadius = 30.0
        
        configureHierarchy()
        configureDataSource()
        
        view.bringSubviewToFront(weekdayOrderView)
        
        addGestures()
        
        moreButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis", withConfiguration: UIImage.SymbolConfiguration(weight: .thin)), style: .plain, target: self, action: #selector(moreAction))
//        updateMoreMenu()
        navigationItem.rightBarButtonItem = moreButton
        
        yearPickerButton.configurationUpdateHandler = { [weak self] button in
            guard let self = self else { return }
            var config = button.configuration
            
            config?.title = self.displayHandler.getTitle()
            
            button.configuration = config
        }
        yearPickerButton.addTarget(self, action: #selector(showYearPicker(_ :)), for: .touchUpInside)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: yearPickerButton)
        yearPickerButton.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(40)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .CurrentBookChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .TodayUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .SettingsUpdate, object: nil)
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
        case .invisible, .month:
            break
        case .block(let blockItem):
            impactFeedbackGeneratorCoourred()
            tap(in: cell, for: blockItem)
        }
    }
    
    override func hover(in indexPath: IndexPath) {
        super.hover(in: indexPath)
        guard let blockItem = dataSource.itemIdentifier(for: indexPath) else {
            return
        }
        switch blockItem {
        case .invisible, .month:
            break
        case .block(let blockItem):
            let style = ToastStyle.getStyle(messageColor: blockItem.foregroundColor, backgroundColor: blockItem.backgroundColor)
            view.makeToast(blockItem.calendarString, position: .top, style: style)
        }
    }
    
    private func tap(in targetView: UIView, for blockItem: BlockItem) {
//        let detailViewController = BlockDetailViewController(blockItem: blockItem)
//        showPopoverView(at: targetView, contentViewController: detailViewController)
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .vertical
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { [weak self] index, environment in
            guard let self = self else {
                return nil
            }
            return self.sectionProvider(index: index, environment: environment)
        }, configuration: config)
        return layout
    }
    
    private func configureDataSource() {
        let monthCellRegistration = getMonthSectionCellRegistration()
        let blockCellRegistration = getBlockCellRegistration()
        let invisibleCellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, Item> { (cell, indexPath, identifier) in
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { [weak self]
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: Item) -> UICollectionViewCell? in
            // Return the cell.
            guard let self = self else { return nil }
            guard let section = self.dataSource.sectionIdentifier(for: indexPath.section) else { fatalError("Unknown section") }
            switch section {
            case .month:
                switch identifier {
                case .block:
                    fatalError("Wrong Identifier")
                case .month:
                    return collectionView.dequeueConfiguredReusableCell(using: monthCellRegistration, for: indexPath, item: identifier)
                case .invisible:
                    return collectionView.dequeueConfiguredReusableCell(using: invisibleCellRegistration, for: indexPath, item: identifier)
                }
            case .row:
                switch identifier {
                case .month:
                    fatalError("Wrong Identifier")
                case .block:
                    return collectionView.dequeueConfiguredReusableCell(using: blockCellRegistration, for: indexPath, item: identifier)
                case .invisible:
                    return collectionView.dequeueConfiguredReusableCell(using: invisibleCellRegistration, for: indexPath, item: identifier)
                }
            }
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
        collectionView.contentInset = .init(top: 30.0, left: 0.0, bottom: 100.0, right: 0.0)
    }

    @objc
    internal func reloadData() {
        let startWeekdayOrder = WeekdayOrder(rawValue: WeekStartType.current.rawValue) ?? WeekdayOrder.firstDayOfWeek
        weekdayOrderView.startWeekdayOrder = startWeekdayOrder
        yearPickerButton.setNeedsUpdateConfiguration()
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: yearPickerButton)

        applyData()
    }
    
    private func applyData() {
        let tags = DataManager.shared.tags
        let records = DataManager.shared.dayRecords
        if let snapshot = displayHandler.getSnapshot(tags: tags, records: records) {
            dataSource.apply(snapshot, animatingDifferences: true) { [weak self] in
                guard let self = self, !self.didScrollToday else { return }
                self.didScrollToday = true
            }
            self.updateVisibleItems()
        }
    }
    
    func scrollToToday() {
        let item = dataSource.snapshot().itemIdentifiers.first { item in
            switch item {
            case .month, .invisible:
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
            collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: true)
        }
    }
    
    private func updateMoreMenu() {
        let children: [UIMenuElement] = [getWeekStartTypeMenu()]
        
        moreButton?.menu = UIMenu(title: "", options: .displayInline, children: children)
    }
    
    @objc
    func moreAction() {
        navigationController?.present(NavigationController(rootViewController: MoreViewController()), animated: true)
    }
    
    @objc
    func showYearPicker(_ sender: UIView) {
        let picker = CalendarYearPickerViewController(currentYear: self.displayHandler.getSelectedYear()) { [weak self] selectYear in
            self?.displayHandler.updateSelectedYear(to: selectYear)
        }
        showPopoverView(at: sender, contentViewController: picker, width: 140)
    }
}
