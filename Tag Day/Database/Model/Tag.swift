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
    
    var creationTime: Int64?
    var modificationTime: Int64?
    
    var name: String
    var comment: String?
    var color: String?
}

extension Tag: TableRecord {
    static var databaseTableName: String = "tag"
}


extension Tag: Codable, FetchableRecord, TimestampedRecord {
    enum Columns: String, ColumnExpression {
        case id
        case name
        case comment
        case color
        
        static let creationTime = Column(CodingKeys.creationTime)
        static let modificationTime = Column(CodingKeys.modificationTime)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, creationTime = "creation_time", modificationTime = "modification_time", name, comment, color
    }
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
