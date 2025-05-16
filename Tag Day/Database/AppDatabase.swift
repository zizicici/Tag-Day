//
//  AppDatabase.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/4/29.
//

import Foundation
import GRDB
import UIKit
import ZCCalendar

extension Notification.Name {
    static let DatabaseUpdated = Notification.Name(rawValue: "com.zizicici.common.database.updated")
}

final class AppDatabase {
    init(_ dbWriter: any DatabaseWriter) throws {
        self.dbWriter = dbWriter
        try migrator.migrate(dbWriter)
    }
    
    private var dbWriter: (any DatabaseWriter)?

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
#if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
#endif
        migrator.registerMigration("book___tag___record") { db in
            try db.create(table: "book") { table in
                table.autoIncrementedPrimaryKey("id")
                
                table.column("title", .text).notNull()
                table.column("comment", .text)
                table.column("book_type", .integer).notNull()
                table.column("order", .integer).notNull()
            }
            try db.create(table: "tag") { table in
                table.autoIncrementedPrimaryKey("id")
                
                table.column("book_id", .integer).notNull()
                    .indexed()
                
                table.column("title", .text).notNull()
                table.column("subtitle", .text)
                table.column("color").notNull()
                table.column("order", .integer).notNull()
            }
            try db.create(table: "day_record") { table in
                table.autoIncrementedPrimaryKey("id")
                
                table.column("book_id", .integer).notNull()
                    .indexed()
                
                table.column("tag_id", .integer).notNull()
                    .indexed()
                
                table.column("day", .integer).notNull()
                table.column("comment", .text)
                
                table.column("start_time", .integer)
                table.column("end_time", .integer)
                table.column("duration", .integer)
                table.column("order", .integer).notNull()
            }
            
            if true {
                var firstBook = Book(title: String(localized: "database.firstBook"), comment: String(localized: "database.firstBook.comment"), order: 0)
                try? firstBook.save(db)
                
                if let bookID = firstBook.id {
                    var firstTag = Tag(bookID: bookID, title: String(localized: "database.firstTag.name"), subtitle: String(localized: "database.firstTag.comment"), color: UIColor.systemMint.generateLightDarkString(), order: 0)
                    try? firstTag.save(db)
                    
                    if let bookId = firstBook.id, let tagId = firstTag.id {
                        var day1 = DayRecord(bookID: bookId, tagID: tagId, day: Int64(ZCCalendar.manager.today.julianDay), comment: String(localized: "database.firstDayRecord.comment"), order: 0)
                        try? day1.save(db)
                        var day2 = DayRecord(bookID: bookId, tagID: tagId, day: Int64(ZCCalendar.manager.today.julianDay + 1), comment: String(localized: "database.firstDayRecord.comment"), order: 0)
                        try? day2.save(db)
                        var day3 = DayRecord(bookID: bookId, tagID: tagId, day: Int64(ZCCalendar.manager.today.julianDay + 2), comment: String(localized: "database.firstDayRecord.comment"), order: 0)
                        try? day3.save(db)
                    }
                    
                    var secondTag = Tag(bookID: bookID, title: String(localized: "database.secondTag.name"), subtitle: nil, color: UIColor.systemPurple.generateLightDarkString(), order: 1)
                    try? secondTag.save(db)
                    if let bookId = firstBook.id, let tagId = secondTag.id {
                        var day4 = DayRecord(bookID: bookId, tagID: tagId, day: Int64(ZCCalendar.manager.today.julianDay + 3), order: 0)
                        try? day4.save(db)
                    }
                    
                    var thirdTag = Tag(bookID: bookID, title: String(localized: "database.thirdTag.name"), subtitle: nil, color: UIColor.systemCyan.generateLightDarkString(), order: 2)
                    try? thirdTag.save(db)
                    if let bookId = firstBook.id, let tagId = thirdTag.id {
                        var day5 = DayRecord(bookID: bookId, tagID: tagId, day: Int64(ZCCalendar.manager.today.julianDay + 4), order: 0)
                        try? day5.save(db)
                    }
                }
                var secondBook = Book(title: String(localized: "database.secondBook"), order: 1)
                try? secondBook.save(db)
            }
        }
        
        return migrator
    }
    
    public func disconnect() {
        self.dbWriter = nil
    }
    
    public func reconnect() {
        do {
            let databasePool = try AppDatabase.generateDatabasePool()
            try migrator.migrate(databasePool)
            self.dbWriter = databasePool
        } catch {
            print(error)
        }
    }
}

// Book
extension AppDatabase {
    func update(book: Book) -> Bool {
        guard book.id != nil else {
            // No ID
            return false
        }
        do {
            _ = try dbWriter?.write{ db in
                try book.update(db)
            }
        }
        catch {
            print(error)
            return false
        }
        NotificationCenter.default.post(Notification(name: Notification.Name.DatabaseUpdated))
        return true
    }
    
    func update(books: [Book]) -> Bool {
        guard !books.contains(where: { $0.id == nil }) else {
            // No ID
            return false
        }
        do {
            _ = try dbWriter?.write{ db in
                for book in books {
                    try book.update(db)
                }
            }
        }
        catch {
            print(error)
            return false
        }
        NotificationCenter.default.post(Notification(name: Notification.Name.DatabaseUpdated))
        return true
    }
    
    func add(book: Book) -> Bool {
        guard book.id == nil else {
            // Should no ID
            return false
        }
        var saveBook: Book = book
        do {
            _ = try dbWriter?.write{ db in
                try saveBook.save(db)
            }
        }
        catch {
            print(error)
            return false
        }
        NotificationCenter.default.post(Notification(name: Notification.Name.DatabaseUpdated))
        return true
    }
    
    func delete(book: Book) -> Bool {
        guard let bookID = book.id else {
            return false
        }
        do {
            _ = try dbWriter?.write{ db in
                try Book.deleteAll(db, ids: [bookID])
                // Delete Day Records
                let bookIDColumnInDayRecord = DayRecord.Columns.bookID
                let dayRecordRequest = DayRecord.filter(bookIDColumnInDayRecord == bookID)
                try dayRecordRequest.deleteAll(db)
                // Delete Tags
                let bookIDColumnInTag = Tag.Columns.bookID
                let tagRequest = Tag.filter(bookIDColumnInTag == bookID)
                try tagRequest.deleteAll(db)
            }
        }
        catch {
            print(error)
            return false
        }
        NotificationCenter.default.post(Notification(name: Notification.Name.DatabaseUpdated))
        return true
    }
}

// Tag
extension AppDatabase {
    func update(tag: Tag) -> Bool {
        guard tag.id != nil else {
            // No ID
            return false
        }
        do {
            _ = try dbWriter?.write{ db in
                try tag.update(db)
            }
        }
        catch {
            print(error)
            return false
        }
        NotificationCenter.default.post(Notification(name: Notification.Name.DatabaseUpdated))
        return true
    }
    
    func update(tags: [Tag]) -> Bool {
        guard !tags.contains(where: { $0.id == nil }) else {
            // No ID
            return false
        }
        do {
            _ = try dbWriter?.write{ db in
                for tag in tags {
                    try tag.update(db)
                }
            }
        }
        catch {
            print(error)
            return false
        }
        NotificationCenter.default.post(Notification(name: Notification.Name.DatabaseUpdated))
        return true
    }
    
    func add(tag: Tag) -> Bool {
        guard tag.id == nil else {
            // Should no ID
            return false
        }
        var saveTag: Tag = tag
        do {
            _ = try dbWriter?.write{ db in
                try saveTag.save(db)
            }
        }
        catch {
            print(error)
            return false
        }
        NotificationCenter.default.post(Notification(name: Notification.Name.DatabaseUpdated))
        return true
    }
    
    func delete(tag: Tag) -> Bool {
        guard let tagID = tag.id else {
            return false
        }
        do {
            _ = try dbWriter?.write{ db in
                try Tag.deleteAll(db, ids: [tagID])
                // Delete Day Records
                let tagIDColumnInDayRecord = DayRecord.Columns.tagID
                let dayRecordRequest = DayRecord.filter(tagIDColumnInDayRecord == tagID)
                try dayRecordRequest.deleteAll(db)
            }
        }
        catch {
            print(error)
            return false
        }
        NotificationCenter.default.post(Notification(name: Notification.Name.DatabaseUpdated))
        return true
    }
}

// Day Records
extension AppDatabase {
    func update(dayRecord: DayRecord) -> Bool {
        guard dayRecord.id != nil else {
            // No ID
            return false
        }
        do {
            _ = try dbWriter?.write{ db in
                try dayRecord.update(db)
            }
        }
        catch {
            print(error)
            return false
        }
        NotificationCenter.default.post(Notification(name: Notification.Name.DatabaseUpdated))
        return true
    }
    
    func add(dayRecord: DayRecord) -> Bool {
        guard dayRecord.id == nil else {
            // Should no ID
            return false
        }
        var saveRecord: DayRecord = dayRecord
        do {
            _ = try dbWriter?.write{ db in
                try saveRecord.save(db)
            }
        }
        catch {
            print(error)
            return false
        }
        NotificationCenter.default.post(Notification(name: Notification.Name.DatabaseUpdated))
        return true
    }
    
    func delete(dayRecord: DayRecord) -> Bool {
        guard let recordID = dayRecord.id else {
            return false
        }
        do {
            _ = try dbWriter?.write{ db in
                try DayRecord.deleteAll(db, ids: [recordID])
            }
        }
        catch {
            print(error)
            return false
        }
        NotificationCenter.default.post(Notification(name: Notification.Name.DatabaseUpdated))
        return true
    }
    
    func resetDayRecord(bookID: Int64, day: Int64) -> Bool {
        do {
            _ = try dbWriter?.write{ db in
                let bookIDColumn = DayRecord.Columns.bookID
                let dayColumn = DayRecord.Columns.day
                try DayRecord.filter(bookIDColumn == bookID && dayColumn == day).deleteAll(db)
            }
        }
        catch {
            print(error)
            return false
        }
        NotificationCenter.default.post(Notification(name: Notification.Name.DatabaseUpdated))
        return true
    }
}

extension AppDatabase {
    /// Provides a read-only access to the database
    var reader: DatabaseReader? {
        dbWriter
    }
}
