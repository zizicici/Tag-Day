//
//  BookType.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/6/30.
//

import Foundation

enum BookType: Int, Codable {
    case active = 0
    case hidden = 1
    case archived = 2
}

struct Book: Identifiable, Hashable, Codable {
    var id: Int64?
    
    var title: String
    var color: String
    var symbol: String
    var bookType: BookType = .active
    var order: Int
    
    enum CodingKeys: String, CodingKey {
        case id, title, color, symbol, bookType = "book_type", order
    }
}

struct Tag: Identifiable, Hashable, Codable {
    var id: Int64?
    
    var bookID: Int64

    var title: String
    var subtitle: String
    var color: String
    var titleColor: String?
    var order: Int
    
    enum CodingKeys: String, CodingKey {
        case id, bookID = "book_id", title, subtitle, color, titleColor = "title_color", order
    }
}

struct DayRecord: Identifiable, Hashable, Codable {
    var id: Int64?
    
    var bookID: Int64
    var tagID: Int64
    var day: Int64
    
    var comment: String?
    
    var startTime: Int64?
    var endTime: Int64?
    var duration: Int64?
    var order: Int64
    
    enum CodingKeys: String, CodingKey {
        case id, bookID = "book_id", tagID = "tag_id", day, comment, startTime = "start_time", endTime = "end_time", duration, order
    }
}

struct BookConfig: Identifiable, Hashable, Codable {
    var id: Int64?
    
    var bookID: Int64
    var notificationTime: Int64?
    var notificationText: String?
    var repeatWeekday: String?
    
    enum CodingKeys: String, CodingKey {
        case id, bookID = "book_id", notificationTime = "notification_time", notificationText = "notification_text", repeatWeekday = "repeat_weekday"
    }
}

extension BookConfig {
    var isNotificationOn: Bool {
        return notificationTime != nil
    }
    
    mutating func update(to enable: Bool) {
        if enable {
            notificationTime = Int64(3600 * 1000 * 20)
        } else {
            notificationText = nil
            notificationTime = nil
        }
    }
}
