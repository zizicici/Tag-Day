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
import MoreKit

extension Notification.Name {
    static let DatabaseUpdated = Notification.Name(rawValue: "com.zizicici.common.database.updated")
}

final class AppDatabase {
    init(_ dbWriter: any DatabaseWriter) throws {
        self.dbWriter = dbWriter
        try migrator.migrate(dbWriter)
    }
    
    private(set) var dbWriter: (any DatabaseWriter)?

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
#if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
#endif
        migrator.registerMigration("book___tag___record") { db in
            try db.create(table: "book") { table in
                table.autoIncrementedPrimaryKey("id")
                
                table.column("title", .text).notNull()
                table.column("color", .text).notNull()
                table.column("symbol", .text).notNull()
                table.column("book_type", .integer).notNull()
                table.column("order", .integer).notNull()
            }
            try db.create(table: "tag") { table in
                table.autoIncrementedPrimaryKey("id")
                
                table.column("book_id", .integer).notNull()
                    .indexed()
                
                table.column("title", .text).notNull()
                table.column("subtitle", .text).notNull()
                table.column("color", .text).notNull()
                table.column("title_color", .text)
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
            
            try db.create(table: "book_config") { table in
                table.autoIncrementedPrimaryKey("id")
                
                table.column("book_id", .integer).notNull()
                table.column("notification_time", .integer)
                table.column("notification_text", .text)
                table.column("repeat_weekday", .text)
            }
            
            if true {
                var firstBook = Book(title: String(localized: "database.firstBook"), color: AppColor.main.generateLightDarkString(), symbol: "latch.2.case", order: 0)
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
                    
                    var secondTag = Tag(bookID: bookID, title: String(localized: "database.secondTag.name"), subtitle: "", color: UIColor.systemPurple.generateLightDarkString(), order: 1)
                    try? secondTag.save(db)
                    if let bookId = firstBook.id, let tagId = secondTag.id {
                        var day4 = DayRecord(bookID: bookId, tagID: tagId, day: Int64(ZCCalendar.manager.today.julianDay + 3), order: 0)
                        try? day4.save(db)
                    }
                    
                    var thirdTag = Tag(bookID: bookID, title: String(localized: "database.thirdTag.name"), subtitle: "", color: UIColor.systemCyan.generateLightDarkString(), order: 2)
                    try? thirdTag.save(db)
                    if let bookId = firstBook.id, let tagId = thirdTag.id {
                        var day5 = DayRecord(bookID: bookId, tagID: tagId, day: Int64(ZCCalendar.manager.today.julianDay + 4), order: 0)
                        try? day5.save(db)
                    }
                }
                var secondBook = Book(title: String(localized: "database.secondBook"), color: UIColor.systemMint.generateLightDarkString(), symbol: "figure.run", order: 1)
                try? secondBook.save(db)
            }
        }
        
        return migrator
    }
    
    public func disconnect() {
        self.dbWriter = nil
    }
    
    @discardableResult
    public func reconnect() -> Bool {
        do {
            let databasePool = try AppDatabase.generateDatabasePool()
            try migrator.migrate(databasePool)
            self.dbWriter = databasePool
            return true
        } catch {
            print(error)
            return false
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
        guard let dbWriter = dbWriter else { return false }
        do {
            _ = try dbWriter.write{ db in
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
        guard let dbWriter = dbWriter else { return false }
        do {
            _ = try dbWriter.write{ db in
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
        guard let dbWriter = dbWriter else { return false }
        var saveBook: Book = book
        do {
            _ = try dbWriter.write{ db in
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
        guard let dbWriter = dbWriter else { return false }
        do {
            _ = try dbWriter.write{ db in
                try Book.deleteAll(db, ids: [bookID])
                // Delete Day Records
                let bookIDColumnInDayRecord = DayRecord.Columns.bookID
                let dayRecordRequest = DayRecord.filter(bookIDColumnInDayRecord == bookID)
                try dayRecordRequest.deleteAll(db)
                // Delete Tags
                let bookIDColumnInTag = Tag.Columns.bookID
                let tagRequest = Tag.filter(bookIDColumnInTag == bookID)
                try tagRequest.deleteAll(db)
                // Delete Book Configs
                let bookIDColumnInBookConfig = BookConfig.Columns.bookID
                let bookConfigRequest = BookConfig.filter(bookIDColumnInBookConfig == bookID)
                try bookConfigRequest.deleteAll(db)
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
    private enum MoveTagError: Error {
        case invalidRequest
    }

    private func move(tagID: Int64, toBookID targetBookID: Int64, in db: Database) throws -> Bool {
        guard var tag = try Tag.fetchOne(db, id: tagID) else { return false }
        guard try Book.fetchOne(db, id: targetBookID) != nil else { return false }
        guard tag.bookID != targetBookID else { return false }
        let sourceBookID = tag.bookID
        let maxTagOrder = try Int.fetchOne(db, sql: "SELECT MAX(\"order\") FROM \"tag\" WHERE \"book_id\" = ?", arguments: [targetBookID]) ?? -1
        tag.bookID = targetBookID
        tag.order = maxTagOrder + 1
        try tag.update(db)
        let movingRecords = try DayRecord
            .filter(DayRecord.Columns.bookID == sourceBookID)
            .filter(DayRecord.Columns.tagID == tagID)
            .order(DayRecord.Columns.day.asc)
            .order(DayRecord.Columns.order.asc)
            .fetchAll(db)
        var seenDays = Set<Int64>()
        let movingDays = movingRecords.compactMap { record in
            seenDays.insert(record.day).inserted ? record.day : nil
        }
        var nextOrders: [Int64: Int64] = [:]
        if !movingDays.isEmpty {
            let placeholders = Array(repeating: "?", count: movingDays.count).joined(separator: ", ")
            let arguments = [targetBookID] + movingDays
            let rows = try Row.fetchAll(db, sql: "SELECT \"day\", MAX(\"order\") AS \"max_order\" FROM \"day_record\" WHERE \"book_id\" = ? AND \"day\" IN (\(placeholders)) GROUP BY \"day\"", arguments: StatementArguments(arguments))
            nextOrders = Dictionary(uniqueKeysWithValues: movingDays.map { ($0, Int64(0)) })
            for row in rows {
                let day: Int64 = row["day"]
                let maxOrder: Int64? = row["max_order"]
                nextOrders[day] = (maxOrder ?? -1) + 1
            }
        }
        for record in movingRecords {
            var movingRecord = record
            movingRecord.bookID = targetBookID
            movingRecord.order = nextOrders[record.day] ?? 0
            nextOrders[record.day] = movingRecord.order + 1
            try movingRecord.update(db)
        }
        return true
    }

    func update(tag: Tag) -> Bool {
        guard tag.id != nil else {
            // No ID
            return false
        }
        guard let dbWriter = dbWriter else { return false }
        do {
            _ = try dbWriter.write{ db in
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
        guard let dbWriter = dbWriter else { return false }
        do {
            _ = try dbWriter.write{ db in
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
        guard let dbWriter = dbWriter else { return false }
        var saveTag: Tag = tag
        do {
            _ = try dbWriter.write{ db in
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
        guard let dbWriter = dbWriter else { return false }
        do {
            _ = try dbWriter.write{ db in
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

    func move(tagID: Int64, toBookID targetBookID: Int64) -> Bool {
        guard let dbWriter = dbWriter else { return false }
        do {
            let moved = try dbWriter.write { db in
                try move(tagID: tagID, toBookID: targetBookID, in: db)
            }
            guard moved else { return false }
        }
        catch {
            print(error)
            return false
        }
        NotificationCenter.default.post(Notification(name: Notification.Name.DatabaseUpdated))
        return true
    }

    func move(tagID: Int64, toNewBook book: Book) -> Bool {
        guard book.id == nil else { return false }
        guard let dbWriter = dbWriter else { return false }
        var saveBook = book
        do {
            try dbWriter.write { db in
                try saveBook.save(db)
                guard let bookID = saveBook.id else { throw MoveTagError.invalidRequest }
                guard try move(tagID: tagID, toBookID: bookID, in: db) else { throw MoveTagError.invalidRequest }
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
        guard let dbWriter = dbWriter else { return false }
        do {
            _ = try dbWriter.write{ db in
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
    
    func update(dayRecords: [DayRecord]) -> Bool {
        guard !dayRecords.contains(where: { $0.id == nil }) else {
            // No ID
            return false
        }
        guard let dbWriter = dbWriter else { return false }
        do {
            _ = try dbWriter.write{ db in
                for dayRecord in dayRecords {
                    try dayRecord.update(db)
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
    
    func add(dayRecord: DayRecord) -> DayRecord? {
        guard dayRecord.id == nil else {
            // Should no ID
            return nil
        }
        guard let dbWriter = dbWriter else { return nil }
        var saveRecord: DayRecord = dayRecord
        do {
            _ = try dbWriter.write{ db in
                try saveRecord.save(db)
            }
        }
        catch {
            print(error)
            return nil
        }
        NotificationCenter.default.post(Notification(name: Notification.Name.DatabaseUpdated))
        return saveRecord
    }
    
    func add(dayRecords: [DayRecord]) -> Bool {
        guard !dayRecords.contains(where: { $0.id != nil }) else {
            // Should No ID
            return false
        }
        guard let dbWriter = dbWriter else { return false }
        do {
            _ = try dbWriter.write{ db in
                for dayRecord in dayRecords {
                    var saveRecord = dayRecord
                    try saveRecord.save(db)
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
    
    func delete(dayRecord: DayRecord) -> Bool {
        guard let recordID = dayRecord.id else {
            return false
        }
        guard let dbWriter = dbWriter else { return false }
        do {
            _ = try dbWriter.write{ db in
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
    
    func delete(dayRecords: [DayRecord]) -> Bool {
        guard !dayRecords.contains(where: { $0.id == nil }) else {
            // No ID
            return false
        }
        guard let dbWriter = dbWriter else { return false }
        do {
            _ = try dbWriter.write{ db in
                try DayRecord.deleteAll(db, ids: dayRecords.map{ $0.id })
            }
        }
        catch {
            print(error)
            return false
        }
        NotificationCenter.default.post(Notification(name: Notification.Name.DatabaseUpdated))
        return true
    }
    
    func replaceDayRecords(delete deleteRecords: [DayRecord], add addRecords: [DayRecord]) -> Bool {
        guard !deleteRecords.contains(where: { $0.id == nil }) else {
            return false
        }
        guard !addRecords.contains(where: { $0.id != nil }) else {
            return false
        }
        guard let dbWriter = dbWriter else { return false }
        do {
            _ = try dbWriter.write { db in
                try DayRecord.deleteAll(db, ids: deleteRecords.map(\.id))
                for dayRecord in addRecords {
                    var saveRecord = dayRecord
                    try saveRecord.save(db)
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

    func resetDayRecord(bookID: Int64, day: Int64) -> Bool {
        guard let dbWriter = dbWriter else { return false }
        do {
            _ = try dbWriter.write{ db in
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

// Book Configs
extension AppDatabase {
    func update(bookConfig: BookConfig) -> Bool {
        guard bookConfig.id != nil else {
            // No ID
            return false
        }
        guard let dbWriter = dbWriter else { return false }
        do {
            _ = try dbWriter.write{ db in
                try bookConfig.update(db)
            }
        }
        catch {
            print(error)
            return false
        }
        NotificationCenter.default.post(Notification(name: Notification.Name.DatabaseUpdated))
        return true
    }
    
    func update(bookConfigs: [BookConfig]) -> Bool {
        guard !bookConfigs.contains(where: { $0.id == nil }) else {
            // No ID
            return false
        }
        guard let dbWriter = dbWriter else { return false }
        do {
            _ = try dbWriter.write{ db in
                for book in bookConfigs {
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
    
    func add(bookConfig: BookConfig) -> Bool {
        guard bookConfig.id == nil else {
            // Should no ID
            return false
        }
        guard let dbWriter = dbWriter else { return false }
        var saveBookConfig: BookConfig = bookConfig
        do {
            _ = try dbWriter.write{ db in
                try saveBookConfig.save(db)
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
