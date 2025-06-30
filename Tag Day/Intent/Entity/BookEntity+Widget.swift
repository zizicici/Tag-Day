//
//  BookEntity+Widget.swift
//  Tag Widget
//
//  Created by Ci Zi on 2025/6/30.
//

import AppIntents
import ZCCalendar

struct BookIntentQuery: EntityQuery {
    func entities(for identifiers: [BookEntity.ID]) async throws -> [BookEntity] {
        guard let books = try SharedDataManager.read(SharedData.self)?.books else { return [] }
        
        var result: [BookEntity] = []
        for book in books {
            if let bookEntity = BookEntity(book: book) {
                result.append(bookEntity)
            }
        }
        return result
    }
    
    func suggestedEntities() async throws -> [BookEntity] {
        guard let books = try SharedDataManager.read(SharedData.self)?.books else { return [] }

        var result: [BookEntity] = []
        for book in books {
            if let bookEntity = BookEntity(book: book) {
                result.append(bookEntity)
            }
        }
        return result
    }
}
