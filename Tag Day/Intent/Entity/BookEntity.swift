//
//  BookEntity.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/12.
//

import AppIntents
import ZCCalendar

struct BookEntity: Identifiable, Hashable, Equatable, AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "intent.book.type")
    typealias DefaultQuery = BookIntentQuery
    static var defaultQuery = BookIntentQuery()
    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(title: "\(title)")
    }
    
    var id: Int
    
    @Property(title: "intent.book.title")
    var title: String
    
    @Property(title: "intent.book.symbol")
    var symbol: String
    
    init(id: Int, title: String, symbol: String) {
        self.id = id
        self.title = title
        self.symbol = symbol
    }
    
    static func == (lhs: BookEntity, rhs: BookEntity) -> Bool {
        return lhs.id == rhs.id && lhs.title == rhs.title && lhs.symbol == rhs.symbol
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
        hasher.combine(symbol)
    }
    
    init?(book: Book) {
        guard let bookID = book.id else { return nil }
        self.init(id: Int(bookID), title: book.title, symbol: book.symbol ?? "")
    }
}

struct BookIntentQuery: EntityQuery {
    func entities(for identifiers: [BookEntity.ID]) async throws -> [BookEntity] {
        let books = try DataManager.shared.fetchBooks(ids: identifiers.map{ Int64($0) })
        
        var result: [BookEntity] = []
        for book in books {
            if let bookID = book.id {
                result.append(BookEntity(id: Int(bookID), title: book.title, symbol: book.symbol ?? ""))
            }
        }
        return result
    }
    
    func suggestedEntities() async throws -> [BookEntity] {
        let books = try DataManager.shared.fetchAllBooks()
        
        var result: [BookEntity] = []
        for book in books {
            if let bookID = book.id {
                result.append(BookEntity(id: Int(bookID), title: book.title, symbol: book.symbol ?? ""))
            }
        }
        return result
    }
}
