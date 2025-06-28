//
//  RecordEntity.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/12.
//

import AppIntents
import ZCCalendar

struct RecordEntity: Identifiable, Hashable, Equatable, AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "intent.record.type")
    typealias DefaultQuery = RecordIntentQuery
    static var defaultQuery = RecordIntentQuery()
    var displayRepresentation: DisplayRepresentation {
        let day = GregorianDay(from: date)
        return DisplayRepresentation(title: "\(tag.title)", subtitle: "\(day.completeFormatString() ?? "")[\(book.title)]")
    }
    
    var id: Int

    @Property(title: "intent.record.dateValue")
    var date: Date
    
    @Property(title: "intent.tag.type")
    var tag: TagEntity
    
    @Property(title: "intent.book.type")
    var book: BookEntity
    
    @Property(title: "intent.record.comment")
    var comment: String?
    
    @Property(title: "intent.record.startTime")
    var startTime: Date?
    
    @Property(title: "intent.record.endTime")
    var endTime: Date?
    
    @Property(title: "intent.record.durationByMinutes")
    var durationByMinutes: Int?
    
    init(id: Int, date: Date, tag: TagEntity, book: BookEntity, comment: String?, startTime: Date?, endTime: Date?, durationByMinutes: Int?) {
        self.id = id
        self.date = date
        self.tag = tag
        self.book = book
        self.comment = comment
        self.startTime = startTime
        self.endTime = endTime
        self.durationByMinutes = durationByMinutes
    }
    
    static func == (lhs: RecordEntity, rhs: RecordEntity) -> Bool {
        return lhs.id == rhs.id && lhs.date == rhs.date && lhs.tag == rhs.tag && lhs.book == rhs.book && lhs.comment == rhs.comment && lhs.startTime == rhs.startTime && lhs.endTime == rhs.endTime && lhs.durationByMinutes == rhs.durationByMinutes
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(date)
        hasher.combine(tag)
        hasher.combine(book)
        hasher.combine(comment)
        hasher.combine(startTime)
        hasher.combine(endTime)
        hasher.combine(durationByMinutes)
    }
    
    init?(tag: TagEntity, book: BookEntity, record: DayRecord) {
        if let recordID = record.id, let date = GregorianDay(JDN: Int(record.day)).generateDate(secondsFromGMT: Calendar.current.timeZone.secondsFromGMT()) {
            var startTime: Date?
            if let recordStartTime = record.startTime {
                startTime = Date(nanoSecondSince1970: recordStartTime)
            }
            var endTime: Date?
            if let recordEndTime = record.endTime {
                endTime = Date(nanoSecondSince1970: recordEndTime)
            }
            var durationByMinutes: Int?
            if let duration = record.duration {
                durationByMinutes = Int(Double(duration) / 60000)
            }
            self.init(id: Int(recordID), date: date, tag: tag, book: book, comment: record.comment, startTime: startTime, endTime: endTime, durationByMinutes: durationByMinutes)
        } else {
            return nil
        }
    }
}

struct RecordIntentQuery: EntityQuery {
    func entities(for identifiers: [RecordEntity.ID]) async throws -> [RecordEntity] {
        let records = try DataManager.shared.fetchAllDayRecords(recordIDs: identifiers.map{ Int64($0) })
        let allBooks = try DataManager.shared.fetchAllBooks()
        let allTags = try DataManager.shared.fetchAllTags()
        
        var tagEntities: [TagEntity] = []
        for tag in allTags {
            if let tagID = tag.id, let book = allBooks.first(where: { $0.id == tag.bookID }), let bookEntity = BookEntity(book: book) {
                tagEntities.append(TagEntity(id: Int(tagID), title: tag.title, subtitle: tag.subtitle ?? "", book: bookEntity, color: tag.color))
            }
        }
        
        var bookEntities: [BookEntity] = []
        for book in allBooks {
            if let bookID = book.id {
                bookEntities.append(BookEntity(id: Int(bookID), title: book.title, symbol: book.symbol ?? ""))
            }
        }
        
        var result: [RecordEntity] = []
        for record in records {
            if let tag = tagEntities.first(where: { $0.id == record.tagID }), let book = bookEntities.first(where: { $0.id == record.bookID }) {
                if let recordEntity = RecordEntity(tag: tag, book: book, record: record) {
                    result.append(recordEntity)
                }
            }
        }
        return result
    }
    
    func suggestedEntities() async throws -> [RecordEntity] {
        return []
    }
}
