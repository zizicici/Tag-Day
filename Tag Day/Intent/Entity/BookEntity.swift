//
//  BookEntity.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/12.
//

import AppIntents
import ZCCalendar
import UIKit

struct BookEntity: Identifiable, Hashable, Equatable, AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "intent.book.type")
    typealias DefaultQuery = BookIntentQuery
    static var defaultQuery = BookIntentQuery()
    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(title: "\(title)", image: .init(systemName: symbol, tintColor: UIColor(string: color), symbolConfiguration: UIImage.SymbolConfiguration.preferringMulticolor()))
    }
    
    var id: Int
    
    @Property(title: "intent.book.title")
    var title: String
    
    @Property(title: "intent.book.symbol")
    var symbol: String
    
    @Property(title: "intent.book.color")
    var color: String
    
    init(id: Int, title: String, symbol: String, color: String) {
        self.id = id
        self.title = title
        self.symbol = symbol
        self.color = color
    }
    
    static func == (lhs: BookEntity, rhs: BookEntity) -> Bool {
        return lhs.id == rhs.id && lhs.title == rhs.title && lhs.symbol == rhs.symbol && lhs.color == rhs.color
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
        hasher.combine(symbol)
        hasher.combine(color)
    }
    
    init?(book: Book) {
        guard let bookID = book.id else { return nil }
        self.init(id: Int(bookID), title: book.title, symbol: book.symbol ?? "book.closed", color: book.color)
    }
}
