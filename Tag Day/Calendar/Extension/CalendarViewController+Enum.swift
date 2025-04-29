//
//  CalendarViewController+Enum.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/4/29.
//

import Foundation
import ZCCalendar

enum Section: Hashable {
    case month(GregorianMonth)
    case row(GregorianMonth)
}

enum Item: Hashable {
    case month(MonthItem)
    case block(BlockItem)
    case invisible(String)
}
