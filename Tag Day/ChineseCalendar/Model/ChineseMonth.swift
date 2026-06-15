//
//  ChineseMonth.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/25.
//

import Foundation

enum ChineseCalendarText {
    static var usesTraditionalChinese: Bool {
        Locale.preferredLanguages.contains { identifier in
            let normalizedIdentifier = identifier.replacingOccurrences(of: "_", with: "-")
            return normalizedIdentifier.hasPrefix("zh-Hant")
                || normalizedIdentifier.hasPrefix("zh-HK")
                || normalizedIdentifier.hasPrefix("zh-TW")
                || normalizedIdentifier.hasPrefix("zh-MO")
        }
    }

    static var lunarPrefix: String {
        usesTraditionalChinese ? "農曆" : "农历"
    }

    static var twelfthMonthShortName: String {
        usesTraditionalChinese ? "臘" : "腊"
    }

    static func zodiacName(for zodiac: ChineseZodiac) -> String {
        switch zodiac {
        case .shu:
            return "鼠"
        case .niu:
            return "牛"
        case .hu:
            return "虎"
        case .tu:
            return "兔"
        case .long:
            return usesTraditionalChinese ? "龍" : "龙"
        case .she:
            return "蛇"
        case .ma:
            return usesTraditionalChinese ? "馬" : "马"
        case .yang:
            return "羊"
        case .hou:
            return "猴"
        case .ji:
            return usesTraditionalChinese ? "雞" : "鸡"
        case .gou:
            return "狗"
        case .zhu:
            return usesTraditionalChinese ? "豬" : "猪"
        }
    }
}

enum ChineseMonth: Int {
    case yi = 1
    case er = 2
    case san = 3
    case si = 4
    case wu = 5
    case liu = 6
    case qi = 7
    case ba = 8
    case jiu = 9
    case shi = 10
    case dong = 11
    case la = 12
    case laPlus = 13

    func displayString(_ showShort: Bool = true, showMonth: Bool = true) -> String {
        var result = ""
        switch self {
        case .yi:
            result = "正"
        case .er:
            result = "二"
        case .san:
            result = "三"
        case .si:
            result = "四"
        case .wu:
            result = "五"
        case .liu:
            result = "六"
        case .qi:
            result = "七"
        case .ba:
            result = "八"
        case .jiu:
            result = "九"
        case .shi:
            result = "十"
        case .dong:
            result = showShort ? "冬" : "十一"
        case .la:
            result = showShort ? ChineseCalendarText.twelfthMonthShortName : "十二"
        case .laPlus:
            result = showShort ? ChineseCalendarText.twelfthMonthShortName + "*" : "十二*"
        }
        if showMonth {
            result += "月"
        }
        return result
    }
}

enum RepeatableChineseMonth: RawRepresentable {
    case normal(ChineseMonth)
    case interCalary(ChineseMonth)

    init?(rawValue: String) {
        return nil
    }

    var rawValue: String {
        switch self {
        case let .normal(chineseMonth):
            return chineseMonth.displayString()
        case let .interCalary(chineseMonth):
            return String(localized: "chinese.calendar.leap") + chineseMonth.displayString()
        }
    }

    var encodeInt: Int {
        switch self {
        case let .normal(chineseMonth):
            return chineseMonth.rawValue
        case let .interCalary(chineseMonth):
            return -chineseMonth.rawValue
        }
    }

    var timelineDisplay: String {
        switch self {
        case let .normal(chineseMonth):
            return chineseMonth.displayString(false, showMonth: false)
        case let .interCalary(chineseMonth):
            return String(localized: "chinese.calendar.leap") + chineseMonth.displayString(false, showMonth: false)
        }
    }
    
    func displayString() -> String {
        switch self {
        case let .normal(chineseMonth):
            return chineseMonth.displayString(false, showMonth: false)
        case let .interCalary(chineseMonth):
            return String(localized: "chinese.calendar.leap") + chineseMonth.displayString(false, showMonth: false)
        }
    }
}
