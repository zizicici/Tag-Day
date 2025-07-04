//
//  RecordDetailViewController.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/13.
//

import UIKit
import SnapKit
import ZCCalendar

class RecordDetailViewController: UIViewController {
    private var record: DayRecord!
    
    private var tableView: UITableView!
    private var dataSource: DataSource!
    
    enum Section: Int, Hashable {
        case time
        case duration
        case comment
        
        var header: String? {
            switch self {
            case .time:
                return String(localized: "dayRecord.time")
            case .duration:
                return nil
            case .comment:
                return String(localized: "dayRecord.comment")
            }
        }
        
        var footer: String? {
            switch self {
            case .time:
                return String(localized: "dayDetail.timeOption.startAndEnd.subtitle")
            case .duration:
                return nil
            case .comment:
                return nil
            }
        }
    }
    
    enum Item: Hashable {
        case startTimeToggle(Bool)
        case startTime(Int64?)
        case endTimeToggle(Bool)
        case endTime(Int64?)
        case durationOption(DurationOption?)
        case duration(DurationConfiguration)
        case comment(String?)
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
    
    enum EditMode {
        case comment
        case time
    }
    
    private var editMode: EditMode = .comment
    
    private var isEdited: Bool = false
    
    private var comment: String? {
        get {
            return record.comment
        }
        set {
            if record.comment != newValue {
                record.comment = newValue
                isEdited = true
                updateSaveButtonStatus()
            }
        }
    }
    
    weak var commentCell: TextViewCell?
    
    private var timeOption: TimeOption? {
        didSet {
            switch timeOption {
            case .startAndEnd:
                if startTime == nil {
                    startTime = Int64(Date().combine(with: day).timeIntervalSince1970) / 60 * 60 * 1000
                }
                if endTime == nil {
                    endTime = Int64(Date().combine(with: day).timeIntervalSince1970) / 60 * 60 * 1000
                }
            case .startOnly:
                if startTime == nil {
                    startTime = Int64(Date().combine(with: day).timeIntervalSince1970) / 60 * 60 * 1000
                }
            case .endOnly:
                if endTime == nil {
                    endTime = Int64(Date().combine(with: day).timeIntervalSince1970) / 60 * 60 * 1000
                }
            case nil:
                break
            }
            reloadData()
        }
    }
    
    private var startTime: Int64? {
        get {
            return record.startTime
        }
        set {
            if record.startTime != newValue {
                record.startTime = newValue
                isEdited = true
                updateSaveButtonStatus()
                updateDuration()
            }
        }
    }
    
    private var endTime: Int64? {
        get {
            return record.endTime
        }
        set {
            if record.endTime != newValue {
                record.endTime = newValue
                isEdited = true
                updateSaveButtonStatus()
                updateDuration()
            }
        }
    }
    
    private var durationOption: DurationOption? {
        didSet {
            reloadData()
        }
    }
    
    private var durationTimeInterval: Int64? {
        get {
            return record.duration
        }
        set {
            if record.duration != newValue {
                record.duration = newValue
                isEdited = true
                updateSaveButtonStatus()
            }
        }
    }
    
    private var day: GregorianDay {
        return GregorianDay(JDN: Int(record.day))
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(dayRecord: DayRecord, editMode: EditMode) {
        self.init()
        self.record = dayRecord
        self.editMode = editMode
        
        switch editMode {
        case .comment:
            break
        case .time:
            if startTime != nil && endTime != nil {
                timeOption = .startAndEnd
            } else {
                if startTime != nil {
                    timeOption = .startOnly
                } else if endTime != nil {
                    timeOption = .endOnly
                } else {
                    timeOption = nil
                }
            }
            switch timeOption {
            case .startAndEnd:
                if let durationTimeInterval = durationTimeInterval {
                    if durationTimeInterval == (endTime ?? 0) - (startTime ?? 0) {
                        durationOption = .automatic
                    } else {
                        durationOption = .custom
                    }
                } else {
                    durationOption = nil
                }
            case .startOnly, .endOnly, nil:
                if durationTimeInterval != nil {
                    durationOption = .custom
                } else {
                    durationOption = nil
                }
            }
        }
    }
    
    deinit {
        print("DayRecordDetailViewController is deinited")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = AppColor.background
        
        let saveItem = UIBarButtonItem(title: String(localized: "button.save"), style: .done, target: self, action: #selector(save))
        saveItem.tintColor = AppColor.dynamicColor
        saveItem.isEnabled = false
        navigationItem.rightBarButtonItem = saveItem
        
        let cancelItem = UIBarButtonItem(title: String(localized: "button.cancel"), style: .plain, target: self, action: #selector(dismissViewController))
        cancelItem.tintColor = AppColor.dynamicColor
        navigationItem.leftBarButtonItem = cancelItem
        
        configureHierarchy()
        configureDataSource()
        reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        _ = commentCell?.becomeFirstResponder()
    }
    
    func configureHierarchy() {
        tableView = UIDraggableTableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = AppColor.background
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: NSStringFromClass(UITableViewCell.self))
        tableView.register(TextViewCell.self, forCellReuseIdentifier: NSStringFromClass(TextViewCell.self))
        tableView.register(DateCell.self, forCellReuseIdentifier: NSStringFromClass(DateCell.self))
        tableView.register(OptionCell<TimeOption>.self, forCellReuseIdentifier: NSStringFromClass(OptionCell<TimeOption>.self))
        tableView.register(OptionCell<DurationOption>.self, forCellReuseIdentifier: NSStringFromClass(OptionCell<DurationOption>.self))
        tableView.register(DurationCell.self, forCellReuseIdentifier: NSStringFromClass(DurationCell.self))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 50.0
        tableView.delegate = self
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }
        tableView.contentInset = UIEdgeInsets(top: -20.0, left: 0, bottom: 0, right: 0)
    }
    
    func configureDataSource() {
        dataSource = DataSource(tableView: tableView) { [weak self] (tableView, indexPath, item) -> UITableViewCell? in
            guard let self = self else { return nil }
            guard let identifier = self.dataSource.itemIdentifier(for: indexPath) else { return nil }
            switch identifier {
            case .startTimeToggle(let isOn):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(UITableViewCell.self), for: indexPath)
                let itemSwitch = UISwitch()
                itemSwitch.isOn = isOn
                itemSwitch.onTintColor = AppColor.dynamicColor
                itemSwitch.addTarget(self, action: #selector(self.startTimeToggle(_:)), for: .touchUpInside)
                cell.accessoryView = itemSwitch
                
                var content = cell.defaultContentConfiguration()
                content.text = String(localized: "dayRecord.time.start")
                cell.contentConfiguration = content
                return cell
            case .startTime(let startTime):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(DateCell.self), for: indexPath)
                if let cell = cell as? DateCell {
                    cell.update(with: DateCellItem(title: "", nanoSecondsFrom1970: startTime, day: self.day))
                    cell.selectDateAction = { [weak self] nanoSeconds in
                        guard let self = self else { return }
                        self.startTime = nanoSeconds
                        self.updateSaveButtonStatus()
                    }
                }
                return cell
            case .endTimeToggle(let isOn):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(UITableViewCell.self), for: indexPath)
                let itemSwitch = UISwitch()
                itemSwitch.isOn = isOn
                itemSwitch.onTintColor = AppColor.dynamicColor
                itemSwitch.addTarget(self, action: #selector(self.endTimeToggle(_:)), for: .touchUpInside)
                cell.accessoryView = itemSwitch
                
                var content = cell.defaultContentConfiguration()
                content.text = String(localized: "dayRecord.time.end")
                cell.contentConfiguration = content
                return cell
            case .endTime(let endTime):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(DateCell.self), for: indexPath)
                if let cell = cell as? DateCell {
                    cell.update(with: DateCellItem(title: "", nanoSecondsFrom1970: endTime, day: self.day))
                    cell.selectDateAction = { [weak self] nanoSeconds in
                        guard let self = self else { return }
                        self.endTime = nanoSeconds
                        self.updateSaveButtonStatus()
                    }
                }
                return cell
            case .durationOption(let durationOption):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(OptionCell<DurationOption>.self), for: indexPath)
                if let cell = cell as? OptionCell<DurationOption> {
                    cell.update(with: durationOption)
                    let noneAction = UIAction(title: DurationOption.noneTitle, state: durationOption == nil ? .on : .off) { [weak self] _ in
                        self?.durationOption = nil
                    }
                    let actions = [DurationOption.automatic, DurationOption.custom].map { target in
                        let action = UIAction(title: target.title, subtitle: target.subtitle, state: durationOption == target ? .on : .off) { [weak self] _ in
                            self?.durationOption = target
                        }
                        return action
                    }
                    let divider = UIMenu(title: "", options: . displayInline, children: actions)
                    let menu = UIMenu(children: [noneAction, divider])
                    cell.tapButton.menu = menu
                }
                return cell
            case .duration(let config):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(DurationCell.self), for: indexPath)
                if let cell = cell as? DurationCell {
                    cell.update(with: config)
                    cell.valueChangedAction = { [weak self] timeInterval in
                        self?.durationTimeInterval = Int64(timeInterval * 1000)
                    }
                }
                return cell
            case .comment(let comment):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(TextViewCell.self), for: indexPath)
                if let cell = cell as? TextViewCell {
                    cell.tintColor = AppColor.dynamicColor
                    cell.update(text: comment, placeholder: String(localized: "dayRecord.placeholder.comment"))
                    cell.textDidChanged = { [weak self] text in
                        self?.comment = text
                    }
                    self.commentCell = cell
                }
                return cell
            }
        }
    }
    
    func reloadData() {
        updateSaveButtonStatus()
        updateDuration()
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        switch editMode {
        case .comment:
            snapshot.appendSections([.comment])
            snapshot.appendItems([.comment(comment)], toSection: .comment)
        case .time:
            snapshot.appendSections([.time])
            
            switch timeOption {
            case .startAndEnd:
                snapshot.appendItems([.startTimeToggle(true), .startTime(startTime), .endTimeToggle(true), .endTime(endTime)], toSection: .time)
            case .startOnly:
                snapshot.appendItems([.startTimeToggle(true), .startTime(startTime), .endTimeToggle(false)], toSection: .time)
            case .endOnly:
                snapshot.appendItems([.startTimeToggle(false), .endTimeToggle(true), .endTime(endTime)], toSection: .time)
            case nil:
                snapshot.appendItems([.startTimeToggle(false), .endTimeToggle(false)], toSection: .time)
            }
            
            snapshot.appendSections([.duration])
            snapshot.appendItems([.durationOption(durationOption)], toSection: .duration)
            
            if let durationOption = durationOption {
                switch durationOption {
                case .custom:
                    snapshot.appendItems([.duration(DurationConfiguration(duration: TimeInterval((durationTimeInterval ?? 0) / 1000)))], toSection: .duration)
                case .automatic:
                    break
                }
            }
        }
        
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    @objc
    func startTimeToggle(_ toggle: UISwitch) {
        switch timeOption {
        case .startAndEnd:
            if !toggle.isOn {
                timeOption = .endOnly
            }
        case .startOnly:
            if !toggle.isOn {
                timeOption = nil
            }
        case .endOnly:
            if toggle.isOn {
                timeOption = .startAndEnd
            }
        case nil:
            if toggle.isOn {
                timeOption = .startOnly
            }
        }
    }
    
    @objc
    func endTimeToggle(_ toggle: UISwitch) {
        switch timeOption {
        case .startAndEnd:
            if !toggle.isOn {
                timeOption = .startOnly
            }
        case .startOnly:
            if toggle.isOn {
                timeOption = .startAndEnd
            }
        case .endOnly:
            if !toggle.isOn {
                timeOption = nil
            }
        case nil:
            if toggle.isOn {
                timeOption = .endOnly
            }
        }
    }
    
    @objc
    func save() {
        // Handle Time For Save
        switch editMode {
        case .comment:
            break
        case .time:
            switch timeOption {
            case .startAndEnd:
                break
            case .startOnly:
                endTime = nil
            case .endOnly:
                startTime = nil
            case nil:
                startTime = nil
                endTime = nil
            }
        }
        updateDuration()
        
        let result = DataManager.shared.update(dayRecord: record)
        if result {
            dismissViewController()
        }
    }
    
    @objc
    func dismissViewController() {
        dismiss(animated: ConsideringUser.animated)
    }
    
    func updateSaveButtonStatus() {
        navigationItem.rightBarButtonItem?.isEnabled = allowSave()
    }
    
    func allowSave() -> Bool {
        switch editMode {
        case .comment:
            let commentFlag = comment?.isValidRecordComment() ?? true
            
            return commentFlag
        case .time:
            let timeFlag: Bool
            
            switch timeOption {
            case .startAndEnd:
                if let startTime = startTime, let endTime = endTime {
                    timeFlag = startTime <= endTime
                } else {
                    timeFlag = true
                }
            case .startOnly:
                timeFlag = true
            case .endOnly:
                timeFlag = true
            case nil:
                timeFlag = true
            }
            
            return timeFlag
        }
    }
    
    func updateDuration() {
        switch editMode {
        case .comment:
            break
        case .time:
            switch durationOption {
            case .custom:
                break
            case .automatic:
                if let startTime = startTime, let endTime = endTime {
                    if endTime >= startTime {
                        durationTimeInterval = endTime - startTime
                    } else {
                        durationTimeInterval = nil
                    }
                } else {
                    durationTimeInterval = nil
                }
            case nil:
                durationTimeInterval = nil
            }
        }
    }
}


extension RecordDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension String {
    func isValidRecordComment() -> Bool{
        return count <= 200
    }
}
