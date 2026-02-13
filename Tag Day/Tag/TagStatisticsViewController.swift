//
//  TagStatisticsViewController.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/6/17.
//

import Foundation
import UIKit
import SnapKit
import ZCCalendar
import Collections

class TagStatisticsViewController: UIViewController {
    private var tag: Tag!
    private var start: GregorianDay! {
        didSet {
            reloadData()
        }
    }
    private var end: GregorianDay! {
        didSet {
            reloadData()
        }
    }
    
    private var calendarBarItem: UIBarButtonItem?
    private var calendarTransitionDelegate: CalendarTransitionDelegate?
    
    private var tableView: UITableView!
    private var dataSource: DataSource!
    
    private var orderedRange: (start: GregorianDay, end: GregorianDay) {
        guard start.julianDay <= end.julianDay else {
            return (end, start)
        }
        return (start, end)
    }
    
    enum Section: Int, Hashable {
        case time
        case baseStats
        case durationStats
        
        var header: String? {
            switch self {
            case .time:
                return String(localized: "statistics.section.time")
            case .baseStats:
                return String(localized: "statistics.section.baseStats")
            case .durationStats:
                return String(localized: "statistics.section.durationStats")
            }
        }
        
        var footer: String? {
            return nil
        }
    }
    
    enum Item: Hashable {
        case start(GregorianDay)
        case end(GregorianDay)
        case result(String, String)
    }
    
    class DataSource: UITableViewDiffableDataSource<Section, Item> {
        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            let sectionKind = sectionIdentifier(for: section)
            return sectionKind?.header
        }
        
        override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
            let sectionKind = sectionIdentifier(for: section)
            return sectionKind?.footer
        }
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(tag: Tag, start: GregorianDay, end: GregorianDay) {
        self.init()
        self.tag = tag
        self.start = start
        self.end = end
    }
    
    deinit {
        print("TagStatisticsViewController is deinited")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = AppColor.background
        
        let closeItem = UIBarButtonItem(title: String(localized: "button.close"), style: .plain, target: self, action: #selector(dismissViewController))
        closeItem.tintColor = AppColor.dynamicColor
        navigationItem.leftBarButtonItem = closeItem
        
        let editTagItem = UIBarButtonItem(title: String(localized: "tag.edit"), style: .plain, target: self, action: #selector(editTagAction))
        editTagItem.tintColor = AppColor.dynamicColor
        
        let calendarBarItem = UIBarButtonItem(image: UIImage(systemName: "calendar"), style: .plain, target: nil, action: nil)
        calendarBarItem.tintColor = AppColor.dynamicColor
        calendarBarItem.accessibilityLabel = String(localized: "a11y.changeDateRange")
        self.calendarBarItem = calendarBarItem
        
        toolbarItems = [editTagItem, .flexibleSpace(), calendarBarItem]
        navigationController?.setToolbarHidden(false, animated: false)
        
        navigationItem.title = tag.title
        
        let recordsItem = UIBarButtonItem(title: String(localized: "statistics.records"), style: .plain, target: self, action: #selector(showRecordsAction))
        recordsItem.tintColor = AppColor.dynamicColor
        navigationItem.rightBarButtonItem = recordsItem
        
        configureHierarchy()
        configureDataSource()
        reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setToolbarHidden(false, animated: false)
    }
    
    func configureHierarchy() {
        tableView = UIDraggableTableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = AppColor.background
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: NSStringFromClass(UITableViewCell.self))
        tableView.register(DateCell.self, forCellReuseIdentifier: NSStringFromClass(DateCell.self))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 50.0
        tableView.delegate = self
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }
        tableView.contentInset = UIEdgeInsets(top: 0.0, left: 0, bottom: 0, right: 0)
    }
    
    func configureDataSource() {
        dataSource = DataSource(tableView: tableView) { [weak self] (tableView, indexPath, item) -> UITableViewCell? in
            guard let self = self else { return nil }
            guard let identifier = self.dataSource.itemIdentifier(for: indexPath) else { return nil }
            
            switch identifier {
            case .start(let day):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(DateCell.self), for: indexPath)
                if let cell = cell as? DateCell {
                    cell.update(with: DateCellItem(title: String(localized: "statistics.start"), nanoSecondsFrom1970: nil, day: day, mode: .date))
                    cell.selectDateAction = { [weak self] nanoSeconds in
                        guard let self = self else { return }
                        let newDay = GregorianDay(nanoSeconds: nanoSeconds)
                        self.start = newDay
                    }
                }
                return cell
            case .end(let day):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(DateCell.self), for: indexPath)
                if let cell = cell as? DateCell {
                    cell.update(with: DateCellItem(title: String(localized: "statistics.end"), nanoSecondsFrom1970: nil, day: day, mode: .date))
                    cell.selectDateAction = { [weak self] nanoSeconds in
                        guard let self = self else { return }
                        let newDay = GregorianDay(nanoSeconds: nanoSeconds)
                        self.end = newDay
                    }
                }
                return cell
            case .result(let title, let value):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(UITableViewCell.self), for: indexPath)
                var content = UIListContentConfiguration.valueCell()
                content.text = title
                content.textProperties.color = .label
                content.secondaryText = value
                cell.contentConfiguration = content
                return cell
            }
        }
    }
    
    @objc
    func reloadData() {
        let range = orderedRange
        
        // Load Data from database
        guard let records = try? DataManager.shared.fetchAllDayRecords(tagID: tag.id!, from: Int64(range.start.julianDay), to: Int64(range.end.julianDay)) else { return }
        var orderedCounts = OrderedDictionary<Int64, Int>()
        for record in records {
            orderedCounts[record.day, default: 0] += 1
        }
        let durationRecords: [Int64] = records.compactMap{ $0.duration }
        let totalTime = humanReadableTime(TimeInterval(durationRecords.reduce(0, +)) / 1000.0)
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        
        snapshot.appendSections([.time])
        snapshot.appendItems([.start(start), .end(end)], toSection: .time)
        
        snapshot.appendSections([.baseStats])
        snapshot.appendItems([.result(String(localized: "statistics.count"), "\(records.count)")])
        snapshot.appendItems([.result(String(localized: "statistics.days"), "\(orderedCounts.keys.count)")])
        
        if durationRecords.count > 0 {
            snapshot.appendSections([.durationStats])
            snapshot.appendItems([.result(String(localized: "statistics.duration.count"), "\(durationRecords.count)")])
            snapshot.appendItems([.result(String(localized: "statistics.duration.total"), totalTime)])
        }
        
        dataSource.apply(snapshot, animatingDifferences: false)
        
        calendarBarItem?.menu = getDatePickerMenu()
    }
    
    @objc
    func dismissViewController() {
        dismiss(animated: ConsideringUser.animated)
    }
    
    @objc
    func editTagAction() {
        guard let tagID = tag?.id, let tag = try? DataManager.shared.fetchTag(id: tagID) else { return }
        let nav = NavigationController(rootViewController: TagDetailViewController(tag: tag))
        
        present(nav, animated: ConsideringUser.animated)
    }
    
    @objc
    func showRecordsAction() {
        let range = orderedRange
        let recordListViewController = TagRangeRecordListViewController(tag: tag, start: range.start, end: range.end)
        let nav = NavigationController(rootViewController: recordListViewController)
        if !UIAccessibility.isVoiceOverRunning {
            let sourceView: UIView = (navigationItem.rightBarButtonItem?.value(forKey: "view") as? UIView) ?? self.view
            let sourceFrame = sourceView.convert(sourceView.bounds, to: nil)
            nav.modalPresentationStyle = .custom
            calendarTransitionDelegate = CalendarTransitionDelegate(originFrame: sourceFrame, cellBackgroundColor: AppColor.background, detailSize: CGSize(width: 300, height: 480))
            nav.transitioningDelegate = calendarTransitionDelegate
        }
        present(nav, animated: ConsideringUser.animated)
    }
    
    func humanReadableTime(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2  // 只显示最大的两个单位
        formatter.allowedUnits = [.hour, .minute]
        return formatter.string(from: interval)?.replacingOccurrences(of: " ", with: "") ?? ""
    }

    enum DatePickerMenuItem {
        case today
        case month
        case year
        
        case lastMonth
        case target(GregorianMonth)
        
        case latest(Int)
        
        var title: String {
            switch self {
            case .today:
                return String(localized: "datePicker.item.today")
            case .month:
                return String(localized: "datePicker.item.month")
            case .year:
                return String(localized: "datePicker.item.year")
            case .lastMonth:
                return String(localized: "datePicker.item.lastMonth")
            case .target(let month):
                return month.title
            case .latest(let dayCount):
                return String(format: String(localized: "datePicker.item.latest%i"), dayCount)
            }
        }
        
        var subtitle: String? {
            let today = ZCCalendar.manager.today
            switch self {
            case .today:
                return nil
            case .month:
                return nil
            case .year:
                return nil
            case .lastMonth:
                if let lastMonth = ZCCalendar.manager.previousMonth(month: today.month, year: today.year) {
                    return GregorianMonth(year: lastMonth.year, month: lastMonth.month).title
                } else {
                    return nil
                }
            case .target:
                return nil
            case .latest:
                return nil
            }
        }
        
        var start: GregorianDay {
            let today = ZCCalendar.manager.today
            switch self {
            case .today:
                return today
            case .month:
                return ZCCalendar.manager.firstDay(at: today.month, year: today.year)
            case .year:
                return ZCCalendar.manager.firstDay(at: .jan, year: today.year)
            case .lastMonth:
                if let lastMonth = ZCCalendar.manager.previousMonth(month: today.month, year: today.year) {
                    return ZCCalendar.manager.firstDay(at: lastMonth.month, year: lastMonth.year)
                } else {
                    return today
                }
            case .target(let month):
                return month.startDay
            case .latest(let dayCount):
                return today - dayCount + 1
            }
        }
        
        var end: GregorianDay {
            let today = ZCCalendar.manager.today
            switch self {
            case .today:
                return today
            case .month:
                return ZCCalendar.manager.lastDay(at: today.month, year: today.year)
            case .year:
                return ZCCalendar.manager.lastDay(at: .dec, year: today.year)
            case .lastMonth:
                if let lastMonth = ZCCalendar.manager.previousMonth(month: today.month, year: today.year) {
                    return ZCCalendar.manager.lastDay(at: lastMonth.month, year: lastMonth.year)
                } else {
                    return today
                }
            case .target(let month):
                return month.endDay
            case .latest:
                return today
            }
        }
    }
    
    func getDatePickerMenu() -> UIMenu {
        var elements: [UIMenuElement] = []
        
        let firstItems: [DatePickerMenuItem] = [.today, .month, .year].reversed()
        let firstPageDivider = UIMenu(title: "", options: .displayInline, children: firstItems.map({ action(for: $0) }))
        elements.append(firstPageDivider)
        
        let targetMonthItems: [DatePickerMenuItem] = previousFiveMonthsExcludingLastMonth().map({ .target(GregorianMonth(year: $0.year, month: $0.month)) }).reversed()
        let targetMonthPageMenu = UIMenu(title: String(localized: "datePicker.menu.more"), children: targetMonthItems.map({ action(for: $0) }))
        
        let secondItems = [DatePickerMenuItem.lastMonth]
        var secondChildren: [UIMenuElement] = secondItems.map({ action(for: $0) })
        secondChildren.append(targetMonthPageMenu)
        
        let secondPageDivider = UIMenu(title: "", options: .displayInline, children: secondChildren.reversed())
        elements.append(secondPageDivider)
        
        let moreDayCounts: [Int] = [2, 3, 4, 5, 10, 15, 20, 45, 60, 90, 120, 180, 360].reversed()
        let moreDayCountsPageMenu = UIMenu(title: String(localized: "datePicker.menu.more"), children: moreDayCounts.map({ DatePickerMenuItem.latest($0) }).map({ action(for: $0) }))
        
        let thirdItems = [DatePickerMenuItem.latest(7), .latest(30), .latest(365)]
        
        var thirdChildren: [UIMenuElement] = thirdItems.map({ action(for: $0) })
        thirdChildren.append(moreDayCountsPageMenu)
        
        let thirdPageDivider = UIMenu(title: "", options: .displayInline, children: thirdChildren.reversed())
        elements.append(thirdPageDivider)
        
        return UIMenu(children: elements.reversed())
    }
    
    func action(for item: DatePickerMenuItem) -> UIAction {
        return UIAction(title: item.title, subtitle: item.subtitle, state: isMatched(for: item) ? .on : .off) { [weak self] _ in
            self?.start = item.start
            self?.end = item.end
        }
    }
    
    func isMatched(for item: DatePickerMenuItem) -> Bool {
        return item.start == start && item.end == end
    }
    
    func previousFiveMonthsExcludingLastMonth() -> [(month: Month, year: Int)] {
        let today = ZCCalendar.manager.today
        guard let lastMonth = ZCCalendar.manager.previousMonth(month: today.month, year: today.year) else {
            return []
        }
        
        var result: [(month: Month, year: Int)] = []
        var currentMonth = lastMonth
        
        for _ in 0..<5 {
            guard let prev = ZCCalendar.manager.previousMonth(month: currentMonth.month, year: currentMonth.year) else {
                break
            }
            result.append(prev)
            currentMonth = prev
        }
        
        return result
    }
}

extension TagStatisticsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

private final class TagRangeRecordListViewController: UIViewController {
    private var tag: Tag!
    private var start: GregorianDay!
    private var end: GregorianDay!
    private var records: [DayRecord] = []
    
    enum Section: Hashable {
        case main
    }
    
    struct Item: Hashable {
        var record: DayRecord
    }
    
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>! = nil
    private var collectionView: UICollectionView! = nil
    
    private var orderedRange: (start: GregorianDay, end: GregorianDay) {
        guard start.julianDay <= end.julianDay else {
            return (end, start)
        }
        return (start, end)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(tag: Tag, start: GregorianDay, end: GregorianDay) {
        self.init(nibName: nil, bundle: nil)
        
        self.tag = tag
        self.start = start
        self.end = end
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = AppColor.background
        
        updateTitle()
        
        configureCollectionView()
        configureDataSource()
        reloadData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .DatabaseUpdated, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setToolbarHidden(true, animated: false)
    }
    
    private func updateTitle() {
        title = tag.title
        let range = orderedRange
        let startText = range.start.formatString() ?? ""
        let endText = range.end.formatString() ?? ""
        navigationItem.prompt = String(format: String(localized: "statistics.range%@%@"), startText, endText)
    }
    
    private func configureCollectionView() {
        collectionView = UIDraggableCollectionView(frame: CGRect.zero, collectionViewLayout: createLayout())
        collectionView.backgroundColor = AppColor.background
        collectionView.delegate = self
        collectionView.dragInteractionEnabled = false
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }
    }
    
    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<RecordListCell, Item> { [weak self] (cell, indexPath, item) in
            guard let self = self else { return }
            let day = GregorianDay(JDN: Int(item.record.day))
            cell.delegate = self
            cell.update(with: .init(day: day, tags: [self.displayTag(for: item.record)], record: item.record))
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            let cell = collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemIdentifier)
            return cell
        })
    }
    
    @objc
    private func reloadData() {
        guard let tagID = tag.id else { return }
        
        if let latestTag = try? DataManager.shared.fetchTag(id: tagID) {
            tag = latestTag
        }
        
        let range = orderedRange
        records = (try? DataManager.shared.fetchAllDayRecords(tagID: tagID, from: Int64(range.start.julianDay), to: Int64(range.end.julianDay))) ?? []
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems(records.map({ .init(record: $0) }), toSection: .main)
        
        dataSource.apply(snapshot, animatingDifferences: true) {
            if let navBar = self.navigationController?.navigationBar {
                UIAccessibility.post(notification: .screenChanged, argument: navBar)
            }
        }
        
        updateTitle()
    }
    
    @objc
    private func dismissAction() {
        dismiss(animated: ConsideringUser.animated)
    }
    
    private func displayTag(for record: DayRecord) -> Tag {
        guard var displayTag = tag else { return .empty() }
        let day = GregorianDay(JDN: Int(record.day))
        displayTag.title = day.formatString() ?? ""
        return displayTag
    }
}

extension TagRangeRecordListViewController {
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

extension TagRangeRecordListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

extension TagRangeRecordListViewController: RecordListCellDelegate {
    func handle(tag: Tag, in button: UIButton, for record: DayRecord) {
        //
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
