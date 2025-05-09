//
//  DayRecord.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/2.
//

import Foundation
import GRDB

struct DayRecord: Identifiable, Hashable {
    var id: Int64?
    
    var bookID: Int64
    var tagID: Int64
    var day: Int64
    
    var comment: String?
    
    var currencyType: String?
    var currencyValue: Int64?
    
    var startTime: Int64?
    var endTime: Int64?
    var duration: Int64?
}

extension DayRecord: TableRecord {
    static var databaseTableName: String = "day_record"
}

extension DayRecord: Codable, FetchableRecord, MutablePersistableRecord {
    enum Columns: String, ColumnExpression {
        case id
        case day
        
        case comment
        case duration
        
        static let bookID = Column(CodingKeys.bookID)
        static let tagID = Column(CodingKeys.tagID)
        
        static let currencyCode = Column(CodingKeys.currencyType)
        static let currencyValue = Column(CodingKeys.currencyValue)
        
        static let startTime = Column(CodingKeys.startTime)
        static let endTime = Column(CodingKeys.endTime)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, bookID = "book_id", tagID = "tag_id", day, comment, currencyType = "currency_type", currencyValue = "currency_value", startTime = "start_time", endTime = "end_time", duration
    }
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
