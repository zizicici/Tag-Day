//
//  SharedData.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/6/30.
//

import Foundation

struct WidgetAddDayRecord: Codable {
    var tagID: Int
    var bookID: Int
    var day: Int
    var date: Int
    var order: Int
}

struct SharedData: Codable {
    var version: Int
    var books: [Book]
    var tags: [Tag]
    var dayRecord: [DayRecord]
    var widgetAddDayRecords: [WidgetAddDayRecord]
}
