//
//  MoreViewController.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/4/29.
//

import UIKit
import SnapKit
import SafariServices
import AppInfo
import StoreKit

class MoreViewController: UIViewController {
    static let supportEmail = "tagday@zi.ci"

    private var tableView: UITableView!
    private var dataSource: DataSource!
    
    enum Section: Hashable {
        case membership
        case general
        case calendar
        case advanced
        case contact
        case appjun
        case about
        
        var header: String? {
            switch self {
            case .membership:
                return nil
            case .general:
                return String(localized: "more.section.general")
            case .calendar:
                return String(localized: "more.section.calendar")
            case .advanced:
                return String(localized: "more.section.advanced")
            case .contact:
                return String(localized: "more.section.contact")
            case .appjun:
                return String(localized: "more.section.appjun")
            case .about:
                return String(localized: "more.section.about")
            }
        }
        
        var footer: String? {
            return nil
        }
    }
    
    enum Item: Hashable {
        enum GeneralItem: Hashable {
            case language
            case dynamicColor(DynamicColorType)
            
            var title: String {
                switch self {
                case .language:
                    return String(localized: "more.item.settings.language")
                case .dynamicColor:
                    return DynamicColorType.getTitle()
                }
            }
            
            var value: String? {
                switch self {
                case .language:
                    return String(localized: "more.item.settings.language.value")
                case .dynamicColor(let dynamicColor):
                    return dynamicColor.getName()
                }
            }
        }
        
        enum CalendarItem: Hashable {
            case weekStartType(WeekStartType)
            case secondaryCalendar(SecondaryCalendar)
            
            var title: String {
                switch self {
                case .weekStartType:
                    return WeekStartType.getTitle()
                case .secondaryCalendar:
                    return SecondaryCalendar.getTitle()
                }
            }
            
            var value: String? {
                switch self {
                case .weekStartType(let value):
                    return value.getName()
                case .secondaryCalendar(let secondaryCalendar):
                    return secondaryCalendar.getName()
                }
            }
        }
        
        enum AboutItem {
            case specifications
            case share
            case review
            case eula
            case privacyPolicy
            
            var title: String {
                switch self {
                case .specifications:
                    return String(localized: "more.item.about.specifications")
                case .share:
                    return String(localized: "more.item.about.share")
                case .review:
                    return String(localized: "more.item.about.review")
                case .eula:
                    return String(localized: "more.item.about.eula")
                case .privacyPolicy:
                    return String(localized: "more.item.about.privacyPolicy")
                }
            }
            
            var value: String? {
                switch self {
                default:
                    return nil
                }
            }
        }
        
        enum ContactItem: Hashable, CaseIterable {
            case email
            case xiaohongshu
            case bilibili

            var title: String {
                switch self {
                case .email:
                    return String(localized: "more.item.contact.email")
                case .xiaohongshu:
                    return String(localized: "more.item.contact.xiaohongshu")
                case .bilibili:
                    return String(localized: "more.item.contact.bilibili")
                }
            }
            
            var value: String? {
                switch self {
                case .email:
                    return MoreViewController.supportEmail
                case .bilibili, .xiaohongshu:
                    return "@App君"
                }
            }
            
            var image: UIImage? {
                switch self {
                case .email:
                    return UIImage(systemName: "envelope")
                case .xiaohongshu:
                    return UIImage(systemName: "book.closed")
                case .bilibili:
                    return UIImage(systemName: "play.tv")
                }
            }
        }
        
        enum AppJunItem: Hashable {
            case otherApps(AppInfo.App)
            
            var title: String {
                switch self {
                case .otherApps:
                    return ""
                }
            }
            
            var value: String? {
                switch self {
                case .otherApps:
                    return nil
                }
            }
        }
        
        case promotion(String)
        case thanks
        case settings(GeneralItem)
        case calendar(CalendarItem)
        case backup
        case notification
        case contact(ContactItem)
        case appjun(AppJunItem)
        case about(AboutItem)
        
        var title: String {
            switch self {
            case .promotion, .thanks:
                return ""
            case .settings(let item):
                return item.title
            case .calendar(let item):
                return item.title
            case .backup:
                return String(localized: "backup.title")
            case .notification:
                return String(localized: "notificationEditor.title")
            case .contact(let item):
                return item.title
            case .appjun(let item):
                return item.title
            case .about(let item):
                return item.title
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
        
        title = String(localized: "controller.more.title")
        tabBarItem = UITabBarItem(title: String(localized: "controller.more.title"), image: UIImage(systemName: "ellipsis"), tag: 4)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("MoreViewController is deinited")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = AppColor.background
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .automatic
        navigationController?.navigationBar.tintColor = AppColor.dynamicColor
        
        configureHierarchy()
        configureDataSource()
        reloadData()
        
        if Store.shared.membershipDisplayPrice() == nil {
            Store.shared.retryRequestProducts()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .SettingsUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .DatabaseUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .StoreInfoLoaded, object: nil)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func configureHierarchy() {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = AppColor.background
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "reuseIdentifier")
        tableView.register(AppCell.self, forCellReuseIdentifier: NSStringFromClass(AppCell.self))
        tableView.register(PromotionCell.self, forCellReuseIdentifier: NSStringFromClass(PromotionCell.self))
        tableView.register(GratefulCell.self, forCellReuseIdentifier: NSStringFromClass(GratefulCell.self))
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
            case .promotion(let price):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(PromotionCell.self), for: indexPath)
                if let cell = cell as? PromotionCell {
                    cell.update(price: price)
                    cell.purchaseClosure = { [weak self] in
                        self?.lifetimeAction()
                    }
                    cell.restoreClosure = { [weak self] in
                        self?.restorePurchases()
                    }
                }
                return cell
            case .thanks:
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(GratefulCell.self), for: indexPath)
                return cell
            case .settings(let item):
                let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
                cell.accessoryType = .disclosureIndicator
                var content = UIListContentConfiguration.valueCell()
                content.text = identifier.title
                content.textProperties.color = .label
                content.secondaryText = item.value
                cell.contentConfiguration = content
                return cell
            case .calendar(let item):
                let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
                cell.accessoryType = .disclosureIndicator
                var content = UIListContentConfiguration.valueCell()
                content.text = identifier.title
                content.textProperties.color = .label
                content.secondaryText = item.value
                cell.contentConfiguration = content
                return cell
            case .backup, .notification:
                let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
                cell.accessoryType = .disclosureIndicator
                var content = UIListContentConfiguration.valueCell()
                content.text = identifier.title
                content.textProperties.color = .label
                cell.contentConfiguration = content
                return cell
            case .contact(let item):
                let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
                cell.accessoryType = .disclosureIndicator
                var content = UIListContentConfiguration.valueCell()
                content.text = identifier.title
                content.textProperties.color = .label
                content.secondaryText = item.value
                cell.contentConfiguration = content
                return cell
            case .appjun(let item):
                switch item {
                case .otherApps(let app):
                    let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(AppCell.self), for: indexPath)
                    if let cell = cell as? AppCell {
                        cell.update(app)
                    }
                    cell.accessoryType = .disclosureIndicator
                    return cell
                }
            case .about(let item):
                let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
                cell.accessoryType = .disclosureIndicator
                var content = UIListContentConfiguration.valueCell()
                content.text = identifier.title
                content.textProperties.color = .label
                content.secondaryText = item.value
                cell.contentConfiguration = content
                return cell
            }
        }
    }
    
    @objc
    func reloadData() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        
        snapshot.appendSections([.membership])
        switch User.shared.proTier() {
        case .lifetime:
            snapshot.appendItems([.thanks], toSection: .membership)
        case .none:
            snapshot.appendItems([.promotion(Store.shared.membershipDisplayPrice() ?? "?.??")], toSection: .membership)
        }
        
        snapshot.appendSections([.general])
        snapshot.appendItems([.settings(.language), .settings(.dynamicColor(DynamicColorType.getValue()))], toSection: .general)
        
        snapshot.appendSections([.calendar])
        snapshot.appendItems([.calendar(.weekStartType(WeekStartType.getValue())), .calendar(.secondaryCalendar(SecondaryCalendar.getValue()))], toSection: .calendar)
        
        snapshot.appendSections([.advanced])
        snapshot.appendItems([.backup, .notification], toSection: .advanced)
        
        snapshot.appendSections([.contact])
        snapshot.appendItems([.contact(.email), .contact(.xiaohongshu)], toSection: .contact)
        
        snapshot.appendSections([.appjun])
        var appItems: [Item] = [.appjun(.otherApps(.offDay)), .appjun(.otherApps(.lemon)), .appjun(.otherApps(.moontake)), .appjun(.otherApps(.coconut)), .appjun(.otherApps(.pigeon))]
        if Language.type() == .zh {
            appItems.append(.appjun(.otherApps(.festivals)))
        }
        appItems.append(.appjun(.otherApps(.one)))
        snapshot.appendItems(appItems, toSection: .appjun)
        
        snapshot.appendSections([.about])
        snapshot.appendItems([.about(.specifications), .about(.share), .about(.review), .about(.eula), .about(.privacyPolicy)], toSection: .about)

        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

extension MoreViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let item = dataSource.itemIdentifier(for: indexPath) {
            switch item {
            case .promotion, .thanks:
                break
            case .settings(let item):
                switch item {
                case .language:
                    jumpToSettings()
                case .dynamicColor:
                    enterSettings(DynamicColorType.self)
                }
            case .calendar(let item):
                switch item {
                case .weekStartType:
                    enterSettings(WeekStartType.self)
                case .secondaryCalendar:
                    enterSettings(SecondaryCalendar.self)
                }
            case .backup:
                enterBackup()
            case .notification:
                enterNotificationEditor()
            case .contact(let item):
                handle(contactItem: item)
            case .appjun(let item):
                switch item {
                case .otherApps(let app):
                    openStorePage(for: app)
                }
            case .about(let item):
                switch item {
                case .specifications:
                    enterSpecifications()
                case .share:
                    shareApp()
                case .review:
                    openAppStoreForReview()
                case .eula:
                    openEULA()
                case .privacyPolicy:
                    openPrivacyPolicy()
                }
            }
        }
    }
}

extension MoreViewController {
    func jumpToSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:])
        }
    }
    
    func enterSettings<T: SettingsOption>(_ type: T.Type) {
        let settingsOptionViewController = SettingOptionsViewController<T>()
        settingsOptionViewController.hidesBottomBarWhenPushed = true
        
        navigationController?.pushViewController(settingsOptionViewController, animated: ConsideringUser.pushAnimated)
    }
    
    func enterSpecifications() {
        let specificationViewController = SpecificationsViewController()
        specificationViewController.hidesBottomBarWhenPushed = true
        
        navigationController?.pushViewController(specificationViewController, animated: ConsideringUser.pushAnimated)
    }
    
    func enterBackup() {
        let backupViewController = BackupViewController()
        backupViewController.hidesBottomBarWhenPushed = true
        
        navigationController?.pushViewController(backupViewController, animated: ConsideringUser.pushAnimated)
    }
    
    func enterNotificationEditor() {
        let notificationEditor = NotificationViewController()
        notificationEditor.hidesBottomBarWhenPushed = true
        
        navigationController?.pushViewController(notificationEditor, animated: ConsideringUser.pushAnimated)
    }
    
    func openEULA() {
        if let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
            openSF(with: url)
        }
    }
    
    func openPrivacyPolicy() {
        if let url = URL(string: "https://zizicici.medium.com/privacy-policy-for-tag-day-app-e284ee9f654c") {
            openSF(with: url)
        }
    }
    
    func openYoutubeWebpage() {
        if let url = URL(string: "https://www.youtube.com/@app_jun") {
            openSF(with: url)
        }
    }
    
    func openStorePage(for app: App) {
        let storeViewController = SKStoreProductViewController()
        storeViewController.delegate = self
        
        let parameters = [SKStoreProductParameterITunesItemIdentifier: app.storeId]
        
        storeViewController.loadProduct(withParameters: parameters) { [weak self] (loaded, error) in
            if loaded {
                // 成功加载，展示视图控制器
                self?.present(storeViewController, animated: ConsideringUser.animated, completion: nil)
            } else if let error = error {
                // 加载失败，可以选择跳转到 App Store 应用作为后备方案
                print("Error loading App Store: \(error.localizedDescription)")
                self?.jumpToAppStorePage(for: app)
            }
        }
    }
    
    func jumpToAppStorePage(for app: App) {
        guard let appStoreURL = URL(string: "itms-apps://itunes.apple.com/app/" + app.storeId) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(appStoreURL) {
            UIApplication.shared.open(appStoreURL, options: [:], completionHandler: nil)
        }
    }
    
    func openAppStoreForReview() {
        guard let appStoreURL = URL(string: "itms-apps://itunes.apple.com/app/id6745145597?action=write-review") else {
            return
        }
        
        if UIApplication.shared.canOpenURL(appStoreURL) {
            UIApplication.shared.open(appStoreURL, options: [:], completionHandler: nil)
        }
    }
    
    func shareApp() {
        if let url = URL(string: "https://apps.apple.com/app/id6745145597") {
            let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            
            present(controller, animated: ConsideringUser.animated)
        }
    }
}

extension MoreViewController: SKStoreProductViewControllerDelegate {
    func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
        viewController.dismiss(animated: ConsideringUser.animated, completion: nil)
    }
}

extension MoreViewController {
    func lifetimeAction() {
        showOverlayViewController()
        Task {
            do {
                if let _ = try await Store.shared.purchaseLifetimeMembership() {
                    reloadData()
                }
            }
            catch {
                showAlert(title: String(localized: "membership.purchases.order.failure", comment: "Order Failure"), message: error.localizedDescription)
            }
            
            hideOverlayViewController()
        }
    }
    
    func manageAction() {
        if Store.shared.needRetry {
            Store.shared.retryRequestProducts()
        } else {
            switch User.shared.proTier() {
            case .lifetime:
                restorePurchases()
            case .none:
                restorePurchases()
            }
        }
    }
    
    func restorePurchases() {
        Task {
            showOverlayViewController()
            await Store.shared.sync()
            hideOverlayViewController()
        }
    }
}

extension UIViewController {
    func handle(contactItem: MoreViewController.Item.ContactItem) {
        switch contactItem {
        case .email:
            sendEmailToCustomerSupport()
        case .xiaohongshu:
            openXiaohongshuWebpage()
        case .bilibili:
            openBilibiliWebpage()
        }
    }
    
    func sendEmailToCustomerSupport() {
        let recipient = MoreViewController.supportEmail
        
        guard let emailUrlString = "mailto:\(recipient)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let emailUrl = URL(string: emailUrlString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(emailUrl) {
            UIApplication.shared.open(emailUrl, options: [:], completionHandler: nil)
        } else {
            // 打开邮件应用失败，进行适当的处理或提醒用户
        }
    }
    
    
    func openBilibiliWebpage() {
        if let url = URL(string: "https://space.bilibili.com/4969209") {
            openSF(with: url)
        }
    }
    
    func openXiaohongshuWebpage() {
        if let url = URL(string: "https://www.xiaohongshu.com/user/profile/63f05fc5000000001001e524") {
            openSF(with: url)
        }
    }
}

struct Language {
    enum LanguageType {
        case zh
        case en
        case ja
    }
    
    static func type() -> LanguageType {
        switch String(localized: "more.item.settings.language.value") {
        case "简体中文", "繁體中文", "繁體中文（香港）":
            return .zh
        case "日本語":
            return .ja
        default:
            return .en
        }
    }
}
