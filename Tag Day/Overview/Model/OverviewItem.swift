//
//  OverviewItem.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/11/28.
//

import Foundation
import UIKit
import ZCCalendar

struct OverviewItem: BlockCellProtocol {
    struct BookCount: Hashable {
        var book: Book
        var count: Int
    }
    
    var index: Int
    var backgroundColor: UIColor
    var foregroundColor: UIColor
    var isToday: Bool
    var bookInfo: [BookCount]
    var secondaryCalendar: String?
    var a11ySecondaryCalendar: String?
    
    var isSymbol: Bool
    
    var day: GregorianDay {
        return GregorianDay(JDN: index)
    }
    
    func getTagData() -> [(tag: Tag, count: Int)] {
        let fakeTagData = bookInfo.map { bookInfo in
            if isSymbol {
                return (Tag(bookID: bookInfo.book.id!, title: bookInfo.book.symbol, subtitle: "", color: UIColor.clear.generateLightDarkString(), titleColor: bookInfo.book.color, order: 0), bookInfo.count)
            } else {
                return (Tag(bookID: bookInfo.book.id!, title: bookInfo.book.title, subtitle: "", color: bookInfo.book.color, order: 0), bookInfo.count)
            }
        }
        
        return fakeTagData
    }
    
    func getDay() -> String {
        return day.dayString()
    }
    
    func getA11yLabel() -> String {
        return ""
    }
    
    func getA11yHint() -> String {
        return ""
    }
    
    func getA11yValue() -> String {
        return ""
    }
}
