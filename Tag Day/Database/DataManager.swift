//
//  DataManager.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/3.
//

import Foundation
import GRDB

struct DataManager {
    static let shared = DataManager()
}

// Book
extension DataManager {
    func fetchAllBookInfos(bookType: BookType, includingStatistics: Bool = false) throws -> [BookInfo] {
        var result: [BookInfo] = []
        try AppDatabase.shared.reader?.read{ db in
            do {
                let orderColumn = Book.Columns.order
                let bookTypeColumn = Book.Columns.bookType
                result = try Book
                    .order(orderColumn.asc)
                    .filter(bookTypeColumn == bookType.rawValue)
                    .asRequest(of: BookInfo.self)
                    .fetchAll(db)
            }
            catch {
                print(error)
            }
        }
        
        return result
    }
    
    func update(book: Book, postNotification: Bool = true) -> Bool {
        return AppDatabase.shared.update(book: book, postNotification: postNotification)
    }
    
    func add(book: Book) -> Book? {
        return AppDatabase.shared.add(book: book)
    }
    
    func delete(book: Book) -> Bool {
        return AppDatabase.shared.delete(book: book)
    }
}
