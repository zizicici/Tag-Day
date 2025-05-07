//
//  DataManager.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/3.
//

import Foundation
import GRDB

extension Notification.Name {
    static let CurrentBookChanged = Notification.Name(rawValue: "com.zizicici.data.currentBook.changed")
    static let BooksUpdated = Notification.Name(rawValue: "com.zizicici.data.books.updated")
    static let TagsUpdated = Notification.Name(rawValue: "com.zizicici.data.tags.updated")
    static let ActiveTagsUpdated = Notification.Name(rawValue: "com.zizicici.data.activeTags.updated")
    static let DayRecordsUpdated = Notification.Name(rawValue: "com.zizicici.data.dayRecords.updated")
}

class DataManager {
    static let shared = DataManager()
    
    var currentBook: Book? {
        didSet {
            if oldValue != currentBook {
                // Update DayRecords and Tags
                updateTags()
                updateDayRecords()
                NotificationCenter.default.post(Notification(name: Notification.Name.CurrentBookChanged))
            }
        }
    }
    
    var books: [Book] = [] {
        didSet {
            if oldValue != books {
                NotificationCenter.default.post(Notification(name: Notification.Name.BooksUpdated))
            }
        }
    }
    
    var tags: [Tag] = [] {
        didSet {
            if oldValue != tags {
                activeTags = tags
                NotificationCenter.default.post(Notification(name: Notification.Name.TagsUpdated))
            }
        }
    }
    
    var activeTags: [Tag] = [] {
        didSet {
            NotificationCenter.default.post(Notification(name: Notification.Name.ActiveTagsUpdated))
        }
    }
    
    var dayRecords: [DayRecord] = [] {
        didSet {
            if oldValue != dayRecords {
                NotificationCenter.default.post(Notification(name: Notification.Name.DayRecordsUpdated))
            }
        }
    }
    
    init() {
        currentBook = try? fetchAllBooks(for: .active).first
        self.updateDataWithCurrentBook()
        NotificationCenter.default.post(Notification(name: Notification.Name.CurrentBookChanged))
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateDataWithCurrentBook), name: .DatabaseUpdated, object: nil)
    }
    
    @objc
    func updateDataWithCurrentBook() {
        updateBooks()
        updateTags()
        updateDayRecords()
    }
    
    public func select(book: Book?) {
        self.currentBook = book
    }
    
    private func updateBooks() {
        if let result = try? fetchAllBooks() {
            books = result
        }
    }
    
    private func updateTags() {
        if let currentBookID = currentBook?.id, let result = try? fetchAllTags(for: currentBookID) {
            tags = result
        }
    }
    
    private func updateDayRecords() {
        if let currentBookID = currentBook?.id, let result = try? fetchAllDayRecords(bookID: currentBookID) {
            dayRecords = result
        }
    }
    
    public func toggleActiveState(to tag: Tag) {
        guard tags.contains(tag) else { return }
        if activeTags.contains(tag) {
            activeTags.removeAll(where: { $0 == tag })
        } else {
            activeTags.append(tag)
        }
    }
    
    public func resetActiveToggle(blank: Bool) {
        if blank {
            activeTags = []
        } else {
            activeTags = tags
        }
    }
}

// Book
extension DataManager {
    func fetchAllBooks() throws -> [Book] {
        var result: [Book] = []
        try AppDatabase.shared.reader?.read{ db in
            do {
                let orderColumn = Book.Columns.order
                result = try Book
                    .order(orderColumn.asc)
                    .fetchAll(db)
            }
            catch {
                print(error)
            }
        }
        
        return result
    }
    
    func fetchAllBooks(for bookType: BookType) throws -> [Book] {
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
    
    func update(tag: Tag) -> Bool {
        return AppDatabase.shared.update(tag: tag)
    }
    
    func update(tags: [Tag]) -> Bool {
        return AppDatabase.shared.update(tags: tags)
    }
    
    func add(tag: Tag) -> Bool {
        return AppDatabase.shared.add(tag: tag)
    }
    
    func delete(tag: Tag) -> Bool {
        return AppDatabase.shared.delete(tag: tag)
    }
}

// Day Records
extension DataManager {
    func fetchAllDayRecords(bookID: Int64) throws -> [DayRecord] {
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
    
    func fetchAllDayRecords(tagID: Int64) throws -> [DayRecord] {
        var result: [DayRecord] = []
        try AppDatabase.shared.reader?.read { db in
            do {
                let bookIDColumn = DayRecord.Columns.tagID
                let dayColumn = DayRecord.Columns.day
                result = try DayRecord
                    .filter(bookIDColumn == tagID)
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
