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
                
                table.column("name", .text).notNull()
                table.column("comment", .text)
                    .indexed()
//                    .references("icon", onDelete: .setNull)
                table.column("book_type", .integer).notNull()
                table.column("order", .integer).notNull()
            }
            try db.create(table: "tag") { table in
                table.autoIncrementedPrimaryKey("id")
                
                table.column("book_id", .integer).notNull()
                    .indexed()
//                    .references("book", onDelete: .cascade)
                
                table.column("name", .text).notNull()
                table.column("comment", .text)
                table.column("color")
            }
            try db.create(table: "day_record") { table in
                table.autoIncrementedPrimaryKey("id")
                
                table.column("book_id", .integer).notNull()
                    .indexed()
//                    .references("book", onDelete: .cascade)
                table.column("tag_id", .integer).notNull()
                    .indexed()
//                    .references("tag", onDelete: .cascade)
                
                table.column("day", .integer).notNull()
                table.column("comment", .text).notNull()
                table.column("amount_type", .integer).notNull()
                table.column("amount_value", .integer)
            }
            
            if true {
                var firstBook = Book(name: String(localized: "database.firstBook"), comment: String(localized: "database.firstBook.comment"), order: 0)
                try? firstBook.save(db)
                
                if let bookID = firstBook.id {
                    var firstTag = Tag(bookID: bookID, name: String(localized: "database.firstTag.name"), comment: String(localized: "database.firstTag.comment"), color: UIColor.orange.generateLightDarkString())
                    try? firstTag.save(db)
                    
                    if let bookId = firstBook.id, let tagId = firstTag.id {
                        var firstDayRecord = DayRecord(bookID: bookId, tagID: tagId, day: Int64(ZCCalendar.manager.today.julianDay), comment: String(localized: "database.firstDayRecord.comment"))
                        try? firstDayRecord.save(db)
                    }
                }
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

extension AppDatabase {
    func update(book: Book, postNotification: Bool = true) -> Bool {
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
        if postNotification {
            NotificationCenter.default.post(Notification(name: Notification.Name.DatabaseUpdated))
        }
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
