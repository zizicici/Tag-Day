//
//  Book.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/2.
//

import Foundation
import GRDB

struct Book: Identifiable, Hashable {
    var id: Int64?
    
    var creationTime: Int64?
    var modificationTime: Int64?
    
    var name: String
    var comment: String?
    var iconID: Int64?
    var order: Int
}

extension Book: TableRecord {
    static var databaseTableName: String = "book"
}


extension Book: Codable, FetchableRecord, TimestampedRecord {
    enum Columns: String, ColumnExpression {
        case id
        case name
        case comment
        case order
        
        static let creationTime = Column(CodingKeys.creationTime)
        static let modificationTime = Column(CodingKeys.modificationTime)
        static let iconID = Column(CodingKeys.iconID)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, creationTime = "creation_time", modificationTime = "modification_time", name, comment, iconID = "icon_id", order
    }
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

extension Book {
    static let icon = belongsTo(Icon.self)

    var icon: QueryInterfaceRequest<Icon> {
        request(for: Book.icon)
    }
}

struct BookInfo: Decodable, FetchableRecord, Equatable, Hashable {
    var book: Book
    var icon: Icon?
}
