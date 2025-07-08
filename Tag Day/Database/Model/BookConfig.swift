//
//  BookConfig.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/7/7.
//

import Foundation
import GRDB

extension BookConfig: TableRecord {
    static var databaseTableName: String = "book_config"
}

extension BookConfig: FetchableRecord, MutablePersistableRecord {
    enum Columns: String, ColumnExpression {
        case id
        
        static let bookID = Column(CodingKeys.bookID)
    }
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
