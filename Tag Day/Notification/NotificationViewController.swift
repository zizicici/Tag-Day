//
//  NotificationViewController.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/6/27.
//

import Foundation
import UIKit
import SnapKit
import UserNotifications

class NotificationViewController: UIViewController {
    private var tableView: UITableView!
    private var dataSource: DataSource!
    
    enum Section: Hashable {
        case permission
        case book(Book)

        var header: String? {
            switch self {
            case .permission:
                return nil
            case .book:
                return nil
            }
        }
        
        var footer: String? {
            switch self {
            case .permission:
                return nil
            case .book:
                return nil
            }
        }
    }
    
    enum Item: Hashable {
        case permission(UNAuthorizationStatus)
        case toggle(Book, BookConfig, Bool)
        case time(BookConfig)
        case content(BookConfig)
        
        var title: String? {
            switch self {
            case .permission(let authStatus):
                switch authStatus {
                case .notDetermined:
                    return String(localized: "notificationEditor.auth.notDetermined")
                case .denied:
                    return String(localized: "notificationEditor.auth.needToSettings")
                case .authorized:
                    return nil
                case .provisional:
                    return String(localized: "notificationEditor.auth.needToSettings")
                case .ephemeral:
                    return String(localized: "notificationEditor.auth.needToSettings")
                @unknown default:
                    fatalError()
                }
            case .toggle:
                return String(localized: "notificationEditor.toggle.title")
            case .time:
                return String(localized: "notificationEditor.time.title")
            case .content:
                return String(localized: "notificationEditor.content.title")
            }
        }
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
    
    deinit {
        print("NotificationViewController is deinited")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = String(localized: "notificationEditor.title")
        
        configureHierarchy()
        configureDataSource()
        reloadData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: Notification.Name.SettingsUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: Notification.Name.DatabaseUpdated, object: nil)
    }
    
    func configureHierarchy() {
        tableView = UIDraggableTableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = AppColor.background
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: NSStringFromClass(UITableViewCell.self))
        tableView.register(DateCell.self, forCellReuseIdentifier: NSStringFromClass(DateCell.self))
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 50.0
        tableView.delegate = self
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }
        tableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
    }
    
    func configureDataSource() {
        dataSource = DataSource(tableView: tableView) { [weak self] (tableView, indexPath, item) -> UITableViewCell? in
            guard let self = self else { return nil }
            guard let identifier = dataSource.itemIdentifier(for: indexPath) else { return nil }
            switch identifier {
            case .permission:
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(UITableViewCell.self), for: indexPath)
                var content = UIListContentConfiguration.cell()
                content.text = identifier.title
                content.textProperties.color = AppColor.dynamicColor
                content.textProperties.alignment = .center
                cell.accessoryView = nil
                cell.accessoryType = .none
                cell.contentConfiguration = content
                
                return cell
            case .toggle(let book, let config, let isEnable):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(UITableViewCell.self), for: indexPath)
                let itemSwitch = UISwitch()
                itemSwitch.isEnabled = isEnable
                itemSwitch.isOn = config.isNotificationOn
                itemSwitch.tag = Int(config.bookID)
                itemSwitch.addTarget(self, action: #selector(self.toggle(_:)), for: .touchUpInside)
                itemSwitch.onTintColor = AppColor.dynamicColor
                var content = UIListContentConfiguration.cell()
                content.text = book.title
                content.image = book.image
                content.textProperties.color = .label
                cell.accessoryView = itemSwitch
                cell.accessoryType = .none
                cell.contentConfiguration = content
                
                return cell
            case .time(let config):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(DateCell.self), for: indexPath)
                if let cell = cell as? DateCell {
                    let timeZoneSeconds = Int64(Calendar.current.timeZone.secondsFromGMT() * 1000)
                    let displayTime = (config.notificationTime != nil) ? (config.notificationTime! - timeZoneSeconds) : nil
                    cell.update(with: DateCellItem(title: identifier.title, nanoSecondsFrom1970: displayTime, mode: .time))
                    cell.selectDateAction = { nanoSeconds in
                        var newConfig = config
                        newConfig.notificationTime = nanoSeconds + timeZoneSeconds
                        _ = DataManager.shared.update(bookConfig: newConfig)
                    }
                }
                
                return cell
            case .content(let config):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(UITableViewCell.self), for: indexPath)
                var content = UIListContentConfiguration.valueCell()
                content.text = identifier.title
                content.textProperties.color = .label
                content.secondaryText = config.notificationText
                cell.accessoryView = nil
                cell.accessoryType = .disclosureIndicator
                cell.contentConfiguration = content
                
                return cell
            }
        }
    }
    
    @objc
    func reloadData() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.apply(with: settings.authorizationStatus)
            }
        }
    }
    
    func apply(with authStatus: UNAuthorizationStatus) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        
        let allowAction: Bool
        switch authStatus {
        case .notDetermined:
            allowAction = false
            snapshot.appendSections([.permission])
            snapshot.appendItems([.permission(authStatus)], toSection: .permission)
        case .denied:
            allowAction = false
            snapshot.appendSections([.permission])
            snapshot.appendItems([.permission(authStatus)], toSection: .permission)
        case .authorized:
            allowAction = true
        case .provisional:
            allowAction = false
            snapshot.appendSections([.permission])
            snapshot.appendItems([.permission(authStatus)], toSection: .permission)
        case .ephemeral:
            allowAction = false
            snapshot.appendSections([.permission])
            snapshot.appendItems([.permission(authStatus)], toSection: .permission)
        @unknown default:
            fatalError()
        }
        
        let books: [Book] = (try? DataManager.shared.fetchAllBooks()) ?? []
        
        for book in books {
            if let bookID = book.id, let bookConfig = fetchBookConfig(by: bookID) {
                snapshot.appendSections([.book(book)])
                if bookConfig.isNotificationOn {
                    snapshot.appendItems([.toggle(book, bookConfig, allowAction), .time(bookConfig), .content(bookConfig)], toSection: .book(book))
                } else {
                    snapshot.appendItems([.toggle(book, bookConfig, allowAction)], toSection: .book(book))
                }
            }
        }
        
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    func fetchBookConfig(by bookID: Int64) -> BookConfig? {
        if let record = try? DataManager.shared.fetchBookConfig(bookID: bookID) {
            return record
        } else {
            let result = DataManager.shared.add(bookConfig: BookConfig(bookID: bookID))
            if result {
                return try? DataManager.shared.fetchBookConfig(bookID: bookID)
            } else {
                return nil
            }
        }
    }
    
    func handle(authStatus: UNAuthorizationStatus) {
        switch authStatus {
        case .notDetermined:
            NotificationManager.shared.requestPermission()
        case .denied, .provisional, .ephemeral:
            jumpToSettings()
        case .authorized:
            break
        @unknown default:
            fatalError()
        }
    }
    
    func jumpToSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:])
        }
    }
    
    @objc
    func toggle(_ notificationSwitch: UISwitch) {
        let bookID = notificationSwitch.tag
        guard var config = fetchBookConfig(by: Int64(bookID)) else { return }
        
        config.update(to: notificationSwitch.isOn)
        
        _ = DataManager.shared.update(bookConfig: config)
    }
    
    func showAlert(for config: BookConfig) {
        let alertController = UIAlertController(title: String(localized: "notificationEditor.alert.content.title"), message: String(localized: "notificationEditor.alert.content.message"), preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = ""
            textField.text = config.notificationText
        }
        let cancelAction = UIAlertAction(title: String(localized: "button.cancel"), style: .cancel) { _ in
            //
        }
        let okAction = UIAlertAction(title: String(localized: "button.ok"), style: .default) { [weak self] _ in
            if let text = alertController.textFields?.first?.text {
                self?.save(content: text, for: config)
            }
        }

        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        present(alertController, animated: ConsideringUser.animated, completion: nil)
    }
    
    func save(content: String, for config: BookConfig) {
        var config = config
        config.notificationText = content
        _ = DataManager.shared.update(bookConfig: config)
    }
}

extension NotificationViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let item = dataSource.itemIdentifier(for: indexPath) {
            switch item {
            case .permission(let authStatus):
                handle(authStatus: authStatus)
            case .content(let config):
                showAlert(for: config)
            default:
                break
            }
        }
    }
}
