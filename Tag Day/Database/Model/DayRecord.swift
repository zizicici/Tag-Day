//
//  DayRecord.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/2.
//

import Foundation
import GRDB

extension DayRecord: TableRecord {
    static var databaseTableName: String = "day_record"
}

extension DayRecord: FetchableRecord, MutablePersistableRecord {
    enum Columns: String, ColumnExpression {
        case id
        case day
        
        case comment
        case duration
        case order
        
        static let bookID = Column(CodingKeys.bookID)
        static let tagID = Column(CodingKeys.tagID)
        
        static let startTime = Column(CodingKeys.startTime)
        static let endTime = Column(CodingKeys.endTime)
    }
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

extension DayRecord {
    func getTime() -> String? {
        var result: String?
        if let startTime = startTime {
            if let endTime = endTime {
                // Start And End
                result = Date(nanoSecondSince1970: startTime).formatted(date: .omitted, time: .shortened) + "~" + Date(nanoSecondSince1970: endTime).formatted(date: .omitted, time: .shortened)
            } else {
                // Start Only
                result = Date(nanoSecondSince1970: startTime).formatted(date: .omitted, time: .shortened)
            }
        } else {
            if let endTime = endTime {
                // End Only
                result = "~" + Date(nanoSecondSince1970: endTime).formatted(date: .omitted, time: .shortened)
            } else {
                // None
                result = nil
            }
        }
        
        if let duration = duration {
            let durationText = humanReadableTime(Double(duration) / 1000)
            if let startEnd = result {
                result = startEnd + "   (" + durationText + ")"
            } else {
                result = durationText
            }
        }
        
        return result
    }
    
    func humanReadableTime(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .short
        formatter.maximumUnitCount = 2  // 只显示最大的两个单位
        return formatter.string(from: interval)?.replacingOccurrences(of: " ", with: "") ?? ""
    }
}
