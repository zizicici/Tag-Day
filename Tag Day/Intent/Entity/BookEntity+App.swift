//
//  BookEntity+App.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/6/30.
//

import AppIntents
import ZCCalendar

struct BookIntentQuery: EntityQuery {
    func entities(for identifiers: [BookEntity.ID]) async throws -> [BookEntity] {
        let books = try DataManager.shared.fetchBooks(ids: identifiers.map{ Int64($0) })
        
        var result: [BookEntity] = []
        for book in books {
            if let bookEntity = BookEntity(book: book) {
                result.append(bookEntity)
            }
        }
        return result
    }
    
    func suggestedEntities() async throws -> [BookEntity] {
        let books = try DataManager.shared.fetchAllBooks()
        
        var result: [BookEntity] = []
        for book in books {
            if let bookEntity = BookEntity(book: book) {
                result.append(bookEntity)
            }
        }
        return result
    }
}
