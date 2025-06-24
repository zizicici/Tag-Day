//
//  Tag.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/2.
//

import Foundation
import GRDB

struct Tag: Identifiable, Hashable {
    var id: Int64?
    
    var bookID: Int64

    var title: String
    var subtitle: String?
    var color: String
    var titleColor: String?
    var order: Int
}

extension Tag: TableRecord {
    static var databaseTableName: String = "tag"
}


extension Tag: Codable, FetchableRecord, MutablePersistableRecord {
    enum Columns: String, ColumnExpression {
        case id
        case title
        case subtitle
        case color
        case titleColor
        case order
        static let bookID = Column(CodingKeys.bookID)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, bookID = "book_id", title, subtitle, color, titleColor = "title_color", order
    }
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

extension Tag {
    func getColor(isDark: Bool) -> String {
        if isDark {
            return color.components(separatedBy: ",").last ?? ""
        } else {
            return color.components(separatedBy: ",").first ?? ""
        }
    }
    
    func getTextColor(isDark: Bool) -> String {
        let colorString = getColor(isDark: isDark)
        guard colorString.count >= 6 else { return "" }
        let redPart = String(colorString.prefix(2))         // "58"
        let greenPart = String(colorString.dropFirst(2).prefix(2))  // "56"
        let bluePart = String(colorString.dropFirst(4).prefix(2))   // "D6"
        
        // 十六进制转十进制（0-255）
        func hexToValue(_ hex: String) -> CGFloat {
            return CGFloat(Int(hex, radix: 16) ?? 0)
        }
        
        let red = hexToValue(redPart) / 255.0      // 88 → 0.345 (归一化)
        let green = hexToValue(greenPart) / 255.0   // 86 → 0.337
        let blue = hexToValue(bluePart) / 255.0     // 214 → 0.839
        
        let gray = YtoLstar(Y: rgbToY(r: red, g: green, b: blue))
        if gray > 75.0 {
            return "000000CC"
        } else {
            return "FFFFFFF2"
        }
    }
    
    func sRGBtoLin(_ colorChannel: CGFloat) -> CGFloat {
        if colorChannel <= 0.04045 {
            return colorChannel / 12.92
        }
        return pow((colorChannel + 0.055) / 1.055, 2.4)
    }

    func rgbToY(r: CGFloat, g: CGFloat, b: CGFloat) -> CGFloat {
        return 0.2126 * sRGBtoLin(r) + 0.7152 * sRGBtoLin(g) + 0.0722 * sRGBtoLin(b)
    }

    func YtoLstar(Y: CGFloat) -> CGFloat {
        if Y <= (216 / 24389) {
            return Y * (24389 / 27)
        }
        return pow(Y, (1 / 3)) * 116 - 16
    }
}
