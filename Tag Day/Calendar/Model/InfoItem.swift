//
//  InfoItem.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/7/4.
//

import Foundation
import ZCCalendar

enum InfoTimeRange: Hashable {
    case month(GregorianMonth)
    case year(Int)
}

struct InfoItem: Hashable {
    var tag: Tag
    var count: Int
    var range: InfoTimeRange!
    
    var displayRange: (start: GregorianDay, end: GregorianDay)? {
        switch range {
        case .month(let gregorianMonth):
            let start = ZCCalendar.manager.firstDay(at: gregorianMonth.month, year: gregorianMonth.year)
            let end = ZCCalendar.manager.lastDay(at: gregorianMonth.month, year: gregorianMonth.year)
            return (start, end)
        case .year(let year):
            let start = GregorianDay(year: year, month: .jan, day: 1)
            let end = GregorianDay(year: year, month: .dec, day: 31)
            return (start, end)
        case .none:
            return nil
        }
    }
}
