//
//  WidgetState.swift
//  Tag Widget
//
//  Created by Ci Zi on 2025/6/30.
//

import Foundation
import WidgetKit

enum WidgetState: Codable, Equatable {
    case idle
    case showTags(index: Int)
}

extension WidgetFamily: Codable {
    
}

struct WidgetStateInfo: Codable {
    let kind: String          // Widget种类标识符
    let family: Int  // Widget尺寸,rawValue
    let bookID: Int        // 关联的书籍ID
    let state: WidgetState
    let lastUpdate: Date      // 状态更新时间戳
}

extension WidgetStateInfo {
    var uniqueIdentifier: String {
        return Self.generateUID(kind: kind, family: family, bookID: bookID)
    }
    
    static func generateUID(kind: String, family: Int, bookID: Int) -> String {
        return "\(kind)_\(family)_\(bookID)"
    }
}

struct WidgetStateKeys {
    static let groupContainer = "group.com.zizicici.tag"
    static let statesKey = "widgetStateStorage"
}
