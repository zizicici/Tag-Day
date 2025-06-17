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
    
    private var tableView: UITableView!
    private var dataSource: DataSource!
    
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
        navigationController?.navigationBar.tintColor = AppColor.main
        
        let closeItem = UIBarButtonItem(title: String(localized: "button.close"), style: .plain, target: self, action: #selector(dismissViewController))
        navigationItem.leftBarButtonItem = closeItem
        
        navigationItem.title = tag.title
        
        configureHierarchy()
        configureDataSource()
        reloadData()
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
        // Load Data from database
        guard let records = try? DataManager.shared.fetchAllDayRecords(tagID: tag.id!, from: Int64(start.julianDay), to: Int64(end.julianDay)) else { return }
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
        
        snapshot.appendSections([.durationStats])
        snapshot.appendItems([.result(String(localized: "statistics.duration.count"), "\(durationRecords.count)")])
        snapshot.appendItems([.result(String(localized: "statistics.duration.total"), totalTime)])
        
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    @objc
    func dismissViewController() {
        dismiss(animated: true)
    }
    
    func humanReadableTime(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2  // 只显示最大的两个单位
        formatter.allowedUnits = [.hour, .minute]
        return formatter.string(from: interval)?.replacingOccurrences(of: " ", with: "") ?? ""
    }
}

extension TagStatisticsViewController: UITableViewDelegate {
    
}
