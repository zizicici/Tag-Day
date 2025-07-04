//
//  BlockItem.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/4/29.
//

import Foundation
import ZCCalendar
import UIKit

struct BlockItem: Hashable {
    private static let dateFormatterCache = NSCache<NSNumber, NSString>()
    
    var index: Int
    var backgroundColor: UIColor
    var foregroundColor: UIColor
    var isToday: Bool
    var tags: [Tag]
    var records: [DayRecord]
    var tagDisplayType: TagDisplayType
    var secondaryCalendar: String?
}

extension BlockItem {
    var day: GregorianDay {
        return GregorianDay(JDN: index)
    }
}

extension BlockItem {
    var calendarString: String {
        let nsIndex = NSNumber(value: index)
        
        if let cachedString = BlockItem.dateFormatterCache.object(forKey: nsIndex) {
            return cachedString as String
        }
        
        let dateString = day.completeFormatString() ?? ""
        
        BlockItem.dateFormatterCache.setObject(dateString as NSString, forKey: nsIndex)
        
        return dateString
    }
}
