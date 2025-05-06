//
//  DataManager.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/3.
//

import Foundation
import GRDB

class DataManager {
    static let shared = DataManager()
    
    var currentBook: Book? {
        didSet {
            if oldValue != currentBook {
                // Update DayRecords and Tags
                updateTags()
                updateDayRecords()
            }
        }
    }
    var tags: [Tag] = []
    var dayRecords: [DayRecord] = []
    
    init() {
        currentBook = try? fetchAllBooks(bookType: .active).first
        updateTags()
        updateDayRecords()
    }
    
    public func select(book: Book?) {
        self.currentBook = book
    }
    
    private func updateTags() {
        if let currentBookID = currentBook?.id, let result = try? fetchAllTags(for: currentBookID) {
            tags = result
        }
    }
    
    private func updateDayRecords() {
        if let currentBookID = currentBook?.id, let result = try? fetchAllDayRecords(for: currentBookID) {
            dayRecords = result
        }
    }
}

// Book
extension DataManager {
    func fetchAllBooks(bookType: BookType) throws -> [Book] {
        var result: [Book] = []
        try AppDatabase.shared.reader?.read{ db in
            do {
                let orderColumn = Book.Columns.order
                let bookTypeColumn = Book.Columns.bookType
                result = try Book
                    .order(orderColumn.asc)
                    .filter(bookTypeColumn == bookType.rawValue)
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
    
    func add(book: Book) -> Bool {
        return AppDatabase.shared.add(book: book)
    }
    
    func delete(book: Book) -> Bool {
        return AppDatabase.shared.delete(book: book)
    }
}

// Tag
extension DataManager {
    func fetchAllTags(for bookID: Int64) throws -> [Tag] {
        var result: [Tag] = []
        try AppDatabase.shared.reader?.read { db in
            do {
                let bookIDColumn = Tag.Columns.bookID
                let orderColumn = Tag.Columns.order
                result = try Tag
                    .filter(bookIDColumn == bookID)
                    .order(orderColumn.asc)
                    .fetchAll(db)
            }
            catch {
                print(error)
            }
        }
        
        return result
    }
}

// Day Records
extension DataManager {
    func fetchAllDayRecords(for bookID: Int64) throws -> [DayRecord] {
        var result: [DayRecord] = []
        try AppDatabase.shared.reader?.read { db in
            do {
                let bookIDColumn = DayRecord.Columns.bookID
                let dayColumn = DayRecord.Columns.day
                result = try DayRecord
                    .filter(bookIDColumn == bookID)
                    .order(dayColumn.asc)
                    .fetchAll(db)
            }
            catch {
                print(error)
            }
        }
        
        return result
    }
}
