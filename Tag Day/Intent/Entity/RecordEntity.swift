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
    
    init(id: Int, date: Date, tag: TagEntity, book: BookEntity) {
        self.id = id
        self.date = date
        self.tag = tag
        self.book = book
    }
    
    static func == (lhs: RecordEntity, rhs: RecordEntity) -> Bool {
        return lhs.id == rhs.id && lhs.date == rhs.date && lhs.tag == rhs.tag && lhs.book == rhs.book
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(date)
        hasher.combine(tag)
        hasher.combine(book)
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
                bookEntities.append(BookEntity(id: Int(bookID), title: book.title, comment: book.comment ?? ""))
            }
        }
        
        var result: [RecordEntity] = []
        for record in records {
            if let recordID = record.id, let tag = tagEntities.first(where: { $0.id == record.tagID }), let book = bookEntities.first(where: { $0.id == record.bookID }), let date = GregorianDay(JDN: Int(record.day)).generateDate(secondsFromGMT: Calendar.current.timeZone.secondsFromGMT()) {
                result.append(RecordEntity(id: Int(recordID), date: date, tag: tag, book: book))
            }
        }
        return result
    }
    
    func suggestedEntities() async throws -> [RecordEntity] {
        return []
    }
}
