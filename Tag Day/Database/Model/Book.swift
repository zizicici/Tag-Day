//
//  Book.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/2.
//

import Foundation
import GRDB
import UIKit

extension Book: TableRecord {
    static var databaseTableName: String = "book"
}

extension Book: FetchableRecord, MutablePersistableRecord {
    enum Columns: String, ColumnExpression {
        case id
        case title
        case color
        case symbol
        case order
        
        static let bookType = Column(CodingKeys.bookType)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, color, symbol, bookType = "book_type", order
    }
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

struct BookInfo: Hashable {
    var book: Book
    var tagCount: Int
    var dayRecordCount: Int
    
    func subtitle() -> String {
        String(format: String(localized: "bookInfo.subtitle.tag%i"), tagCount) + " / " + String(format: String(localized: "bookInfo.subtitle.dayRecord%i"), dayRecordCount)
    }
}

extension Book {
    var dynamicColor: UIColor {
        return UIColor(string: color) ?? AppColor.background
    }
    
    var image: UIImage? {
        return UIImage(systemName: symbol ?? "book.closed")?.withTintColor(dynamicColor, renderingMode: .alwaysOriginal)
    }
    
    var templateImage: UIImage? {
        return UIImage(systemName: symbol ?? "book.closed")?.withTintColor(dynamicColor, renderingMode: .alwaysTemplate)
    }
}
