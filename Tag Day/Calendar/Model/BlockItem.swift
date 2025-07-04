//
//  BlockItem.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/4/29.
//

import Foundation
import ZCCalendar
import UIKit
import Collections

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
    var a11ySecondaryCalendar: String?
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
    
    var recordString: String {
        let tagData: [(tag: Tag, count: Int)]

        var orderedCounts = OrderedDictionary<Int64, Int>()
        for record in records {
            orderedCounts[record.tagID, default: 0] += 1
        }
        
        tagData = orderedCounts.sorted(by: { $0.value > $1.value }).compactMap { key, value in
            tags.first(where: { $0.id == key }).map { (tag: $0, count: value) }
        }
        
        if tagData.count > 0 {
            return String(format: String(localized: "a11y.record%itag%i"), records.count, orderedCounts.count) + "\n" + String(localized: "a11y.including") + tagData.map( { String(format: String(localized: "a11y.%@record%i"), $0.tag.title, $0.count)} ).joined(separator: ",")
        } else {
            return String(localized: "a11y.no.records")
        }
    }
}
