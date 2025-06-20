//
//  BlockItem.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/4/29.
//

import Foundation
import ZCCalendar
import UIKit

struct BlockItem: Hashable {
    var index: Int
    var backgroundColor: UIColor
    var foregroundColor: UIColor
    var isToday: Bool
    var tags: [Tag]
    var records: [DayRecord]
    var tagDisplayType: TagDisplayType
    var secondaryCalendar: String?
}

extension BlockItem {
    var day: GregorianDay {
        return GregorianDay(JDN: index)
    }
}

extension BlockItem {
    var calendarString: String {
        return (day.completeFormatString() ?? "")
    }
}

struct InfoItem: Hashable {
    var month: GregorianMonth
    var tag: Tag
    var count: Int
    var duration: Int64?
    var durationRecordCount: Int
    var dayCount: Int
    var monthlyStateType: MonthlyStatsType
}
