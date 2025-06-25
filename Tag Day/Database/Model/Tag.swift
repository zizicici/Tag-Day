//
//  Tag.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/2.
//

import Foundation
import GRDB
import UIKit

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
    func getColorString(isDark: Bool) -> String {
        if isDark {
            return color.components(separatedBy: ",").last ?? ""
        } else {
            return color.components(separatedBy: ",").first ?? ""
        }
    }
    
    func getTitleColorString(isDark: Bool) -> String {
        var result = ""
        
        if let compoents = titleColor?.components(separatedBy: ",") {
            if isDark {
                result = compoents.last ?? ""
            } else {
                result = compoents.first ?? ""
            }
        }
        
        if result.count == 0 {
            let colorString = getColorString(isDark: isDark)
            guard colorString.count >= 6 else { return "" }
            let redPart = String(colorString.prefix(2))
            let greenPart = String(colorString.dropFirst(2).prefix(2))
            let bluePart = String(colorString.dropFirst(4).prefix(2))
            
            // 十六进制转十进制（0-255）
            func hexToValue(_ hex: String) -> CGFloat {
                return CGFloat(Int(hex, radix: 16) ?? 0)
            }
            
            let red = hexToValue(redPart) / 255.0
            let green = hexToValue(greenPart) / 255.0
            let blue = hexToValue(bluePart) / 255.0
            
            let gray = ColorCalculator.YtoLstar(Y: ColorCalculator.rgbToY(r: red, g: green, b: blue))
            if gray > 75.0 {
                result = "000000CC"
            } else {
                result = "FFFFFFF2"
            }
        }
        
        return result
    }
}

extension Tag {
    var dynamicColor: UIColor {
        return UIColor(string: color) ?? AppColor.background
    }
    
    var dynamicTitleColor: UIColor {
        if let titleColor = titleColor {
            return UIColor(string: titleColor) ?? AppColor.text
        } else {
            return UIColor { traitCollection in
                if dynamicColor.resolvedColor(with: traitCollection).isLight {
                    return .black.withAlphaComponent(0.8)
                } else {
                    return .white.withAlphaComponent(0.95)
                }
            }
        }
    }
}
