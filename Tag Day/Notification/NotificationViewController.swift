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

        var header: String? {
            switch self {
            case .permission:
                return nil
            }
        }
        
        var footer: String? {
            switch self {
            case .permission:
                return nil
            }
        }
    }
    
    enum Item: Hashable {
        case permission(UNAuthorizationStatus)
        
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
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: NSNotification.Name.SettingsUpdate, object: nil)
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
        tableView.contentInset = UIEdgeInsets(top: 0.0, left: 0, bottom: 0, right: 0)
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
                content.textProperties.color = AppColor.main
                content.textProperties.alignment = .center
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
        let manager = NotificationManager.shared
        
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

        dataSource.apply(snapshot, animatingDifferences: false)
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
}

extension NotificationViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let item = dataSource.itemIdentifier(for: indexPath) {
            switch item {
            case .permission(let authStatus):
                handle(authStatus: authStatus)
            }
        }
    }
}
