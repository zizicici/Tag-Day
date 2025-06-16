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
        case WeekStartType = "com.zizicici.tagday.settings.WeekStartType"
        case TagDisplayType = "com.zizicici.tagday.settings.TagDisplayType"
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
