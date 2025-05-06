//
//  Tag.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/2.
//

import Foundation
import GRDB

struct Tag: Identifiable, Hashable {
    var id: Int64?
    
    var bookID: Int64

    var name: String
    var comment: String?
    var color: String
    var order: Int
}

extension Tag: TableRecord {
    static var databaseTableName: String = "tag"
}


extension Tag: Codable, FetchableRecord, MutablePersistableRecord {
    enum Columns: String, ColumnExpression {
        case id
        case name
        case comment
        case color
        case order
        static let bookID = Column(CodingKeys.bookID)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, bookID = "book_id", name, comment, color, order
    }
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
