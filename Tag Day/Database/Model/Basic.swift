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
    var symbol: String?
    var bookType: BookType = .active
    var order: Int
}

struct Tag: Identifiable, Hashable, Codable {
    var id: Int64?
    
    var bookID: Int64

    var title: String
    var subtitle: String?
    var color: String
    var titleColor: String?
    var order: Int
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
}
