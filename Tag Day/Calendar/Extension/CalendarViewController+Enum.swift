//
//  CalendarViewController+Enum.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/4/29.
//

import Foundation
import ZCCalendar

enum Section: Hashable {
    case row(GregorianMonth)
    case info(GregorianMonth)
}

enum Item: Hashable {
    case block(BlockItem)
    case invisible(String)
    case info(InfoItem)
    
    var records: [DayRecord] {
        switch self {
        case .block(let blockItem):
            return blockItem.records
        case .invisible:
            return []
        case .info:
            return []
        }
    }
}
