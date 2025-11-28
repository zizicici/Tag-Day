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

protocol BlockCellProtocol: Hashable {
    var index: Int { get set }
    var backgroundColor: UIColor { get set }
    var foregroundColor: UIColor { get set }
    var isToday: Bool { get set }
    var secondaryCalendar: String? { get set }
    var a11ySecondaryCalendar: String? { get set }
    
    func getTagData() -> [(tag: Tag, count: Int)]
    func getDay() -> String
    func getA11yLabel() -> String
    func getA11yHint() -> String
    func getA11yValue() -> String
}

struct BlockItem: BlockCellProtocol {
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
    
    func getTagData() -> [(tag: Tag, count: Int)] {
        let tagData: [(tag: Tag, count: Int)]
        switch tagDisplayType {
        case .normal:
            tagData = records.compactMap { record in
                tags.first(where: { $0.id == record.tagID }).map { (tag: $0, count: 1) }
            }
        case .aggregation:
            var orderedCounts = OrderedDictionary<Int64, Int>()
            for record in records {
                orderedCounts[record.tagID, default: 0] += 1
            }
            tagData = orderedCounts.compactMap { key, value in
                tags.first(where: { $0.id == key }).map { (tag: $0, count: value) }
            }
        }
        return tagData
    }
    
    func getDay() -> String {
        return day.dayString()
    }
    
    func getA11yLabel() -> String {
        if isToday {
            return String(localized: "weekCalendar.today") + "," + calendarString + "," + (a11ySecondaryCalendar ?? "")
        } else {
            return calendarString + "," + (a11ySecondaryCalendar ?? "")
        }
    }
    
    func getA11yHint() -> String {
        return records.count == 0 ? String(localized: "a11y.block.hint.add") : String(localized: "a11y.block.hint.review")
    }
    
    func getA11yValue() -> String {
        return recordString
    }
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
