//
//  CalendarViewController+Enum.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/4/29.
//

import Foundation
import ZCCalendar

enum InfoSectionType: Hashable {
    case monthly
    case yearly
}

enum Section: Hashable {
    case row(GregorianMonth)
    case info(GregorianMonth, InfoSectionType)
}

enum Item: Hashable {
    case block(BlockItem)
    case invisible(String)
    case info(InfoItem)
    case empty(String)
    
    var records: [DayRecord] {
        switch self {
        case .block(let blockItem):
            return blockItem.records
        case .invisible:
            return []
        case .info:
            return []
        case .empty:
            return []
        }
    }
}
