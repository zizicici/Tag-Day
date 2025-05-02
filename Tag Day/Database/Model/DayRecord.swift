//
//  DayRecord.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/2.
//

import Foundation
import GRDB

enum AmountType: Int, Codable {
    case none = 0
    case duration = 1
    case currency
}

struct DayRecord: Identifiable, Hashable {
    var id: Int64?
    
    var creationTime: Int64?
    var modificationTime: Int64?
    
    var bookID: Int64
    var tagID: Int64
    var day: Int64
    var comment: String
    
    var amountType: AmountType = .none
    var amountValue: Int?
}

extension DayRecord: TableRecord {
    static var databaseTableName: String = "day_record"
}

extension DayRecord: Codable, FetchableRecord, TimestampedRecord {
    enum Columns: String, ColumnExpression {
        case id
        case day
        case comment
        
        static let bookID = Column(CodingKeys.bookID)
        static let tagID = Column(CodingKeys.tagID)
        static let creationTime = Column(CodingKeys.creationTime)
        static let modificationTime = Column(CodingKeys.modificationTime)
        static let amountType = Column(CodingKeys.amountType)
        static let amountValue = Column(CodingKeys.amountValue)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, creationTime = "creation_time", modificationTime = "modification_time", bookID = "book_id", tagID = "tag_id", day, comment, amountType = "amount_type", amountValue = "amount_value"
    }
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
