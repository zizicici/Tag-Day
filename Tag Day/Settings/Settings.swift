//
//  Settings.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/4/29.
//

import Foundation
import ZCCalendar

extension UserDefaults {
    enum Settings: String {
        case AutoBackup = "com.zizicici.tag.settings.AutoBackup"
        case BackupFolder = "com.zizicici.tag.settings.BackupFolder"
        case SecondaryCalendar = "com.zizicici.tag.settings.SecondaryCalendar"
        case WeekStartType = "com.zizicici.tag.settings.WeekStartType"
        case TodayIndicator = "com.zizicici.tag.settings.TodayIndicator"
        case TagDisplayType = "com.zizicici.tag.settings.TagDisplayType"
        case MonthlyStatsType = "com.zizicici.tag.settings.MonthlyStatsType"
        case DynamicColor = "com.zizicici.tag.settings.DynamicColor"
    }
}

extension Notification.Name {
    static let SettingsUpdate = Notification.Name(rawValue: "com.zizicici.common.settings.updated")
}

protocol SettingsOption: Hashable, Equatable {
    func getName() -> String
    static func getHeader() -> String?
    static func getFooter() -> String?
    static func getTitle() -> String
    static func getOptions() -> [Self]
    static var current: Self { get set}
}

extension SettingsOption {
    static func getHeader() -> String? {
        return nil
    }
    
    static func getFooter() -> String? {
        return nil
    }
}

extension SettingsOption {
    static func == (lhs: Self, rhs: Self) -> Bool {
        if type(of: lhs) != type(of: rhs) {
            return false
        } else {
            return lhs.getName() == rhs.getName()
        }
    }
}

protocol UserDefaultSettable: SettingsOption {
    static func getKey() -> UserDefaults.Settings
    static var defaultOption: Self { get }
}

extension UserDefaultSettable where Self: RawRepresentable, Self.RawValue == Int {
    static func getValue() -> Self {
        if let intValue = UserDefaults.standard.getInt(forKey: getKey().rawValue), let value = Self(rawValue: intValue) {
            return value
        } else {
            return defaultOption
        }
    }
    
    static func setValue(_ value: Self) {
        UserDefaults.standard.set(value.rawValue, forKey: getKey().rawValue)
        NotificationCenter.default.post(name: NSNotification.Name.SettingsUpdate, object: nil)
    }
    
    static func getOptions<T: CaseIterable>() -> [T] {
        return Array(T.allCases)
    }
    
    static var current: Self {
        get {
            return getValue()
        }
        set {
            setValue(newValue)
        }
    }
}

extension UserDefaults {
    func getInt(forKey key: String) -> Int? {
        if value(forKey: key) == nil {
            return nil
        } else {
            return integer(forKey: key)
        }
    }
    
    func getString(forKey key: String) -> String? {
        if value(forKey: key) == nil {
            return nil
        } else {
            return string(forKey: key)
        }
    }
}

enum AutoBackup: Int, CaseIterable, Codable {
    case enable
    case disable
}

extension AutoBackup: UserDefaultSettable {
    static func getKey() -> UserDefaults.Settings {
        return .AutoBackup
    }
    
    static var defaultOption: AutoBackup {
        return .disable
    }
    
    func getName() -> String {
        return ""
    }
    
    static func getTitle() -> String {
        return ""
    }
}

enum TodayIndicator: Int, CaseIterable, Codable {
    case enable
    case disable
}

extension TodayIndicator: UserDefaultSettable {
    static func getKey() -> UserDefaults.Settings {
        return .TodayIndicator
    }
    
    static var defaultOption: TodayIndicator {
        return .enable
    }
    
    func getName() -> String {
        switch self {
        case .enable:
            return String(localized: "settings.todayIndicator.enable")
        case .disable:
            return String(localized: "settings.todayIndicator.disable")
        }
    }
    
    static func getTitle() -> String {
        return String(localized: "settings.todayIndicator.title")
    }
}

enum SecondaryCalendar: Int, CaseIterable, Codable {
    case none
    case chineseCalendar
    case rokuyo
}

extension SecondaryCalendar: UserDefaultSettable {
    static func getKey() -> UserDefaults.Settings {
        return .SecondaryCalendar
    }
    
    static var defaultOption: SecondaryCalendar {
        return .none
    }
    
    func getName() -> String {
        switch self {
        case .none:
            return String(localized: "settings.secondaryCalendar.none")
        case .chineseCalendar:
            return String(localized: "settings.secondaryCalendar.chineseCalendar")
        case .rokuyo:
            return String(localized: "settings.secondaryCalendar.rokuyo")
        }
    }
    
    static func getTitle() -> String {
        return String(localized: "settings.secondaryCalendar.title")
    }
}

enum TagDisplayType: Int, CaseIterable, Codable {
    case normal
    case aggregation
}

extension TagDisplayType: UserDefaultSettable {
    static func getKey() -> UserDefaults.Settings {
        return .TagDisplayType
    }
    
    static var defaultOption: TagDisplayType {
        return .normal
    }
    
    func getName() -> String {
        switch self {
        case .normal:
            return String(localized: "settings.tagDisplayType.normal")
        case .aggregation:
            return String(localized: "settings.tagDisplayType.aggregation")
        }
    }
    
    static func getTitle() -> String {
        return String(localized: "settings.tagDisplayType.title")
    }
    
    static func getHeader() -> String? {
        return nil
    }
    
    static func getFooter() -> String? {
        return nil
    }
}

enum MonthlyStatsType: Int, CaseIterable, Codable {
    case hidden
    case loggedCount
    case dayCount
}

extension MonthlyStatsType: UserDefaultSettable {
    static func getKey() -> UserDefaults.Settings {
        return .MonthlyStatsType
    }
    
    static var defaultOption: MonthlyStatsType {
        return .loggedCount
    }
    
    func getName() -> String {
        switch self {
        case .hidden:
            return String(localized: "settings.monthlyStatsType.hidden")
        case .loggedCount:
            return String(localized: "settings.monthlyStatsType.loggedCount")
        case .dayCount:
            return String(localized: "settings.monthlyStatsType.dayCount")
        }
    }
    
    static func getTitle() -> String {
        return String(localized: "settings.monthlyStatsType.title")
    }
    
    static func getHeader() -> String? {
        return nil
    }
    
    static func getFooter() -> String? {
        return nil
    }
}

enum WeekStartType: Int, CaseIterable, Codable {
    case followSystem = 0
    case mon = 1
    case tue
    case wed
    case thu
    case fri
    case sat
    case sun
}

extension WeekStartType: UserDefaultSettable {
    static func getKey() -> UserDefaults.Settings {
        return .WeekStartType
    }
    
    static var defaultOption: WeekStartType {
        return .followSystem
    }
    
    func getName() -> String {
        switch self {
        case .followSystem:
            return String(localized: "settings.weekStartType.followSystem")
        default:
            return (WeekdayOrder(rawValue: rawValue) ?? .mon).getShortSymbol()
        }
    }
    
    static func getTitle() -> String {
        return String(localized: "settings.weekStartType.title")
    }
    
    static func getHeader() -> String? {
        return nil
    }
    
    static func getFooter() -> String? {
        return nil
    }
}

enum DynamicColorType: Int, CaseIterable, Codable {
    case disable = 0
    case enable = 1
}

extension DynamicColorType: UserDefaultSettable {
    static func getKey() -> UserDefaults.Settings {
        return .DynamicColor
    }
    
    static var defaultOption: DynamicColorType {
        return .disable
    }
    
    func getName() -> String {
        switch self {
        case .disable:
            return String(localized: "settings.dynamicColor.disable")
        case .enable:
            return String(localized: "settings.dynamicColor.enable")
        }
    }
    
    static func getTitle() -> String {
        return String(localized: "settings.dynamicColor.title")
    }
    
    static func getFooter() -> String? {
        return String(localized: "settings.dynamicColor.hint")
    }
}
