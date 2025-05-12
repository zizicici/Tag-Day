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
        return DisplayRepresentation(title: "\(title)", subtitle: "\(comment)")
    }
    
    var id: Int
    
    @Property(title: "intent.book.title")
    var title: String
    
    @Property(title: "intent.book.comment")
    var comment: String
    
    init(id: Int, title: String, comment: String) {
        self.id = id
        self.title = title
        self.comment = comment
    }
    
    static func == (lhs: BookEntity, rhs: BookEntity) -> Bool {
        return lhs.id == rhs.id && lhs.title == rhs.title && lhs.comment == rhs.comment
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
        hasher.combine(comment)
    }
    
    init?(book: Book) {
        guard let bookID = book.id else { return nil }
        self.init(id: Int(bookID), title: book.title, comment: book.comment ?? "")
    }
}

struct BookIntentQuery: EntityQuery {
    func entities(for identifiers: [BookEntity.ID]) async throws -> [BookEntity] {
        let books = try DataManager.shared.fetchBooks(ids: identifiers.map{ Int64($0) })
        
        var result: [BookEntity] = []
        for book in books {
            if let bookID = book.id {
                result.append(BookEntity(id: Int(bookID), title: book.title, comment: book.comment ?? ""))
            }
        }
        return result
    }
    
    func suggestedEntities() async throws -> [BookEntity] {
        let books = try DataManager.shared.fetchAllBooks()
        
        var result: [BookEntity] = []
        for book in books {
            if let bookID = book.id {
                result.append(BookEntity(id: Int(bookID), title: book.title, comment: book.comment ?? ""))
            }
        }
        return result
    }
}
