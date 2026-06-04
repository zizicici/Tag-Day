//
//  MoreViewController.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/4/29.
//

import UIKit
import MoreKit
import AppInfo

// MARK: - Custom Item IDs

enum MoreSectionID: String {
    case general
    case calendar
    case editing
    case advanced
}

enum MoreItemID: String {
    case language
    case dynamicColor
    case weekStartType
    case secondaryCalendar
    case autoDismissInterval
    case backup
    case notification
}

// MARK: - Factory

extension MoreViewController {
    static func makeTagDay() -> MoreViewController {
        let config = MoreViewControllerConfiguration(
            title: String(localized: "controller.more.title"),
            tabBarImage: UIImage(systemName: "ellipsis"),
            promotionConfig: PromotionCellConfiguration(
                title: String(localized: "promotion.title"),
                titleHighlight: "Pro",
                features: [
                    String(localized: "promotion.first"),
                    String(localized: "promotion.second"),
                    String(localized: "promotion.future"),
                ],
                buttonTextColor: AppColor.main
            ),
            gratefulConfig: GratefulCellConfiguration(
                title: String(localized: "grateful.title"),
                titleHighlight: "Pro",
                content: String(localized: "grateful.content")
            ),
            email: "tagday@zi.ci",
            appStoreId: "6745145597",
            privacyPolicyURL: "https://zizicici.medium.com/privacy-policy-for-tag-day-app-e284ee9f654c",
            specificationsConfig: SpecificationsConfiguration(
                summaryItems: [
                    .init(type: .name, value: SpecificationsViewController.getAppName() ?? ""),
                    .init(type: .version, value: SpecificationsViewController.getAppVersion() ?? ""),
                    .init(type: .manufacturer, value: "@App君"),
                    .init(type: .publisher, value: "ZIZICICI LIMITED"),
                    .init(type: .dateOfProduction, value: "2026/06/06"),
                    .init(type: .license, value: "\u{7ca4}ICP\u{5907}2025448771\u{53f7}-1A"),
                ],
                thirdPartyLibraries: [
                    .init(name: "SnapKit", version: "5.7.1", urlString: "https://github.com/SnapKit/SnapKit"),
                    .init(name: "GRDB", version: "7.8.0", urlString: "https://github.com/groue/GRDB.swift"),
                    .init(name: "Toast", version: "5.1.1", urlString: "https://github.com/scalessec/Toast-Swift"),
                    .init(name: "DurationPicker", version: "1.0.2", urlString: "https://github.com/mac-gallagher/DurationPicker"),
                    .init(name: "SymbolPicker", version: "1.6.2", urlString: "https://github.com/xnth97/SymbolPicker"),
                    .init(name: "ZipArchive", version: "2.6.0", urlString: "https://github.com/ZipArchive/ZipArchive"),
                ]
            ),
            otherApps: [.moontake, .lemon, .offDay, .one, .pigeon, .pin, .coconut],
            otherAppsDisplayCount: 3
        )

        return MoreViewController(configuration: config, dataSource: TagDayMoreDataSource())
    }
}

// MARK: - DataSource

class TagDayMoreDataSource: MoreViewControllerDataSource {

    func sections(for controller: MoreViewController) -> [MoreSectionType] {
        [
            .membership,
            .custom(MoreCustomSection(
                id: MoreSectionID.general.rawValue,
                header: String(localized: "more.section.general"),
                items: [
                    MoreCustomItem(id: MoreItemID.language.rawValue, title: String(localized: "more.item.settings.language"), value: String(localized: "more.item.settings.language.value")),
                    MoreCustomItem(id: MoreItemID.dynamicColor.rawValue, title: DynamicColorType.getTitle(), value: DynamicColorType.getValue().getName()),
                ]
            )),
            .custom(MoreCustomSection(
                id: MoreSectionID.calendar.rawValue,
                header: String(localized: "more.section.calendar"),
                items: [
                    MoreCustomItem(id: MoreItemID.weekStartType.rawValue, title: WeekStartType.getTitle(), value: WeekStartType.getValue().getName()),
                    MoreCustomItem(id: MoreItemID.secondaryCalendar.rawValue, title: SecondaryCalendar.getTitle(), value: SecondaryCalendar.getValue().getName()),
                ]
            )),
            .custom(MoreCustomSection(
                id: MoreSectionID.editing.rawValue,
                header: String(localized: "more.section.editing"),
                items: [
                    MoreCustomItem(id: MoreItemID.autoDismissInterval.rawValue, title: AutoDismissInterval.getTitle(), value: AutoDismissInterval.getValue().getName()),
                ]
            )),
            .custom(MoreCustomSection(
                id: MoreSectionID.advanced.rawValue,
                header: String(localized: "more.section.advanced"),
                items: [
                    MoreCustomItem(id: MoreItemID.backup.rawValue, title: String(localized: "backup.title")),
                    MoreCustomItem(id: MoreItemID.notification.rawValue, title: String(localized: "notificationEditor.title")),
                ]
            )),
            .contact,
            .appjun,
            .about,
        ]
    }

    func moreViewController(_ controller: MoreViewController, didSelectCustomItem item: MoreCustomItem) {
        guard let itemID = MoreItemID(rawValue: item.id) else { return }
        switch itemID {
        case .language:
            controller.jumpToSettings()
        case .dynamicColor:
            controller.enterSettings(DynamicColorType.self)
        case .weekStartType:
            controller.enterSettings(WeekStartType.self)
        case .secondaryCalendar:
            controller.enterSettings(SecondaryCalendar.self)
        case .autoDismissInterval:
            controller.enterSettings(AutoDismissInterval.self)
        case .backup:
            controller.pushViewController(BackupViewController())
        case .notification:
            controller.pushViewController(NotificationViewController())
        }
    }

    func additionalReloadNotifications() -> [Notification.Name] {
        [.DatabaseUpdated]
    }
}
