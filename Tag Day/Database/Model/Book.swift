//
//  Book.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/2.
//

import Foundation
import GRDB

enum BookType: Int, Codable {
    case active = 0
    case hidden = 1
    case archived = 2
}

struct Book: Identifiable, Hashable {
    var id: Int64?
    
    var name: String
    var comment: String?
    var bookType: BookType = .active
    var order: Int
}

extension Book: TableRecord {
    static var databaseTableName: String = "book"
}


extension Book: Codable, FetchableRecord, MutablePersistableRecord {
    enum Columns: String, ColumnExpression {
        case id
        case name
        case comment
        case order
        
        static let bookType = Column(CodingKeys.bookType)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, comment, bookType = "book_type", order
    }
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
