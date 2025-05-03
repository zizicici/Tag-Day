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
    
    var currentBook: Book?
    
    init() {
        currentBook = try? fetchFirstBookInfos(bookType: .active).first?.book
    }
    
    func select(book: Book?) {
        self.currentBook = book
    }
}

// Book
extension DataManager {
    func fetchFirstBookInfos(bookType: BookType) throws -> [BookInfo] {
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
    
    func fetchAllBookInfos(bookType: BookType) throws -> [BookInfo] {
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

// Tag
extension DataManager {
    func fetchAllTags(for bookID: Int64) throws -> [Tag] {
        var result: [Tag] = []
        try AppDatabase.shared.reader?.read { db in
            do {
                let bookIDColumn = Tag.Columns.bookID
                result = try Tag.filter(bookIDColumn == bookID).fetchAll(db)
            }
            catch {
                print(error)
            }
        }
        
        return result
    }
}
