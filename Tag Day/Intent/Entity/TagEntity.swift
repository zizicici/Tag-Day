//
//  TagEntity.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/12.
//

import AppIntents
import ZCCalendar
import UIKit

struct TagEntity: Identifiable, Hashable, Equatable, AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "intent.tag.type")
    typealias DefaultQuery = TagIntentQuery
    static var defaultQuery = TagIntentQuery()
    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(
            title: "\(title)",
            subtitle: "\(subtitle)",
            image: .init(systemName: "square.fill", tintColor: UIColor(string: color), symbolConfiguration: UIImage.SymbolConfiguration.preferringMulticolor()))
    }
    
    var id: Int
    
    @Property(title: "intent.tag.title")
    var title: String
    
    @Property(title: "intent.tag.subtitle")
    var subtitle: String
    
    @Property(title: "intent.book.type")
    var book: BookEntity
    
    private var color: String = ""
    
    init(id: Int, title: String, subtitle: String, book: BookEntity, color: String) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.book = book
        self.color = color
    }
    
    static func == (lhs: TagEntity, rhs: TagEntity) -> Bool {
        return lhs.id == rhs.id && lhs.title == rhs.title && lhs.subtitle == rhs.subtitle && lhs.book == rhs.book && lhs.color == rhs.color
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
        hasher.combine(subtitle)
        hasher.combine(book)
        hasher.combine(color)
    }
}

struct TagIntentQuery: EntityQuery {
    func entities(for identifiers: [TagEntity.ID]) async throws -> [TagEntity] {
        let tags = try DataManager.shared.fetchTags(ids: identifiers.map{ Int64($0) })
        let allBooks = try DataManager.shared.fetchAllBooks()
        
        var result: [TagEntity] = []
        for tag in tags {
            if let tagID = tag.id, let book = allBooks.first(where: { $0.id == tag.bookID }), let bookEntity = BookEntity(book: book) {
                result.append(TagEntity(id: Int(tagID), title: tag.title, subtitle: tag.subtitle, book: bookEntity, color: tag.color))
            }
        }
        return result
    }
    
    func suggestedEntities() async throws -> [TagEntity] {
        let tags = try DataManager.shared.fetchAllTags()
        let allBooks = try DataManager.shared.fetchAllBooks()
        
        var result: [TagEntity] = []
        for tag in tags {
            if let tagID = tag.id, let book = allBooks.first(where: { $0.id == tag.bookID }), let bookEntity = BookEntity(book: book) {
                result.append(TagEntity(id: Int(tagID), title: tag.title, subtitle: tag.subtitle, book: bookEntity, color: tag.color))
            }
        }
        return result
    }
}

struct TagsOptionsProvider: DynamicOptionsProvider {
    @ParameterDependency(\CheckRecordIntent.$book) var book1
    @ParameterDependency(\CheckTomorrowRecordIntent.$book) var book2
    @ParameterDependency(\AddRecordIntent.$book) var book3

    func results() async throws -> ItemCollection<TagEntity> {
        guard let book = book1?.book ?? book2?.book ?? book3?.book else {
            throw FetchError.bookFirst
        }
        
        let tags = try DataManager.shared.fetchAllTags(bookID: Int64(book.id))
        
        var sections: [IntentItemSection<TagEntity>] = .init()
        
        sections.append(ItemSection(
            items: tags.map { tag in
                IntentItem<TagEntity>(
                    TagEntity(
                        id: Int(tag.id!),
                        title: tag.title,
                        subtitle: tag.subtitle,
                        book: BookEntity(id: Int(tag.bookID), title: book.title, symbol: book.symbol, color: book.color),
                        color: tag.color
                    ),
                    title: LocalizedStringResource(stringLiteral: tag.title),
                    subtitle: LocalizedStringResource(stringLiteral: tag.subtitle),
                    image: .init(
                        systemName: "square.fill",
                        tintColor: UIColor(string: tag.color),
                        symbolConfiguration: .preferringMulticolor()
                    )
                )
            }
        ))
        
        return ItemCollection(sections: sections)
    }
}
