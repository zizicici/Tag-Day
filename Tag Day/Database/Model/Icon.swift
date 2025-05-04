//
//  Icon.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/2.
//

import Foundation
import GRDB

enum IconSource: Int, Codable {
    case apple = 0
    case noto = 1
    case fluent = 2
    case custom = 3
    
    var name: String {
        switch self {
        case .apple:
            return "Emoji"
        case .noto:
            return "Noto"
        case .fluent:
            return "Fluent"
        case .custom:
            return "Custom"
        }
    }
}

extension IconSource: DatabaseValueConvertible {
    //
}

struct Icon: Identifiable, Hashable {
    var id: Int64?
    
    var name: String
    var source: IconSource
    var content: String
}

extension Icon: TableRecord {
    static var databaseTableName: String = "icon"
}

extension Icon {
    static func new(source: IconSource, content: String) -> Self {
        let name = source.name + "-" + content
        return Icon(name: name, source: source, content: content)
    }
}

extension Icon: Codable, FetchableRecord, MutablePersistableRecord {
    enum Columns: String, ColumnExpression {
        case id
        case name
        case source
        case content
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, source, content
    }
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
