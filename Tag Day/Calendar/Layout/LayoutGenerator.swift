//
//  LayoutGenerator.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/4/29.
//

import UIKit
import ZCCalendar

struct LayoutGenerater {
    static func dayLayout(for snapshot: inout NSDiffableDataSourceSnapshot<Section, Item>, year: Int, tags: [Tag], records: [DayRecord]) {
        let firstDayOfWeek: WeekdayOrder = WeekdayOrder(rawValue: WeekStartType.current.rawValue) ?? WeekdayOrder.firstDayOfWeek
        
        for month in Month.allCases {
            let firstDay = GregorianDay(year: year, month: month, day: 1)
            let firstWeekOrder = firstDay.weekdayOrder()
            
            let firstOffset = (firstWeekOrder.rawValue - (firstDayOfWeek.rawValue % 7) + 7) % 7

            let gregorianMonth = GregorianMonth(year: year, month: month)
            
            snapshot.appendSections([.row(gregorianMonth)])
            if firstOffset >= 1 {
                snapshot.appendItems(Array(1...firstOffset).map({ index in
                    let uuid = "\(month)-\(index)"
                    return Item.invisible(uuid)
                }))
            }
            
            let items: [BlockItem] = Array(1...ZCCalendar.manager.dayCount(at: month, year: year)).map({ day in
                let gregorianDay = GregorianDay(year: year, month: month, day: day)
                let julianDay = gregorianDay.julianDay
                
                let backgroundColor: UIColor = AppColor.paper
                let foregroundColor: UIColor = AppColor.text
                
                return BlockItem(index: julianDay, backgroundColor: backgroundColor, foregroundColor: foregroundColor, isToday: ZCCalendar.manager.isToday(gregorianDay: gregorianDay), tags: tags, records: records.filter{ $0.day == gregorianDay.julianDay }, tagDisplayType: TagDisplayType.getValue())
            })
            
            snapshot.appendItems(items.map{ Item.block($0) }, toSection: .row(gregorianMonth))
            
            snapshot.appendSections([.info(gregorianMonth)])
            
            let tagStatics = getTagStatistics(in: items, matching: tags)
            
            snapshot.appendItems(tagStatics.map{ Item.info(InfoItem(month: gregorianMonth, tag: $0.tag, count: $0.totalCount, duration: $0.totalDuration, durationRecordCount: $0.durationRecordCount)) }, toSection: .info(gregorianMonth))
        }
    }
    
    static func getSortedTagCounts(in blockItems: [BlockItem], matching tags: [Tag]) -> [(tag: Tag, count: Int)] {
        // 1. 统计所有tagID的出现次数
        var tagIDCounts = [Int64: Int]()
        
        for blockItem in blockItems {
            for record in blockItem.records {
                tagIDCounts[record.tagID, default: 0] += 1
            }
        }
        
        // 2. 创建tagID到Tag对象的映射
        let tagDictionary = Dictionary(uniqueKeysWithValues: tags.map { ($0.id, $0) })
        
        // 3. 过滤并匹配结果
        let matchedResults = tagIDCounts.compactMap { (tagID, count) -> (Tag, Int)? in
            guard let matchingTag = tagDictionary[tagID] else { return nil }
            return (matchingTag, count)
        }
        
        // 4. 按count降序排序，count相同则按tagID升序
        let sortedResults = matchedResults.sorted {
            if $0.1 != $1.1 {
                return $0.1 > $1.1
            }
            return $0.0.id! < $1.0.id!
        }
        
        return sortedResults
    }
    
    struct TagStatistics {
        let tag: Tag
        let totalCount: Int          // 出现的总次数
        let totalDuration: Int64?    // duration总长度
        let durationRecordCount: Int // 有duration信息的总次数
    }

    static func getTagStatistics(in blockItems: [BlockItem], matching tags: [Tag]) -> [TagStatistics] {
        // 1. 统计所有tagID的数据
        var tagIDStats = [Int64: (totalCount: Int, totalDuration: Int64?, durationRecordCount: Int)]()
        
        for blockItem in blockItems {
            for record in blockItem.records {
                let currentStats = tagIDStats[record.tagID] ?? (0, 0, 0)
                
                var newTotalDuration = currentStats.totalDuration
                var newDurationRecordCount = currentStats.durationRecordCount
                
                if let recordDuration = record.duration {
                    newTotalDuration = (newTotalDuration ?? 0) + recordDuration
                    newDurationRecordCount += 1
                }
                
                tagIDStats[record.tagID] = (
                    totalCount: currentStats.totalCount + 1,
                    totalDuration: newTotalDuration,
                    durationRecordCount: newDurationRecordCount
                )
            }
        }
        
        // 2. 创建tagID到Tag对象的映射
        let tagDictionary = Dictionary(uniqueKeysWithValues: tags.map { ($0.id, $0) })
        
        // 3. 过滤并匹配结果，转换为TagStatistics
        let matchedResults = tagIDStats.compactMap { (tagID, stats) -> TagStatistics? in
            guard let matchingTag = tagDictionary[tagID] else { return nil }
            return TagStatistics(
                tag: matchingTag,
                totalCount: stats.totalCount,
                totalDuration: stats.totalDuration,
                durationRecordCount: stats.durationRecordCount
            )
        }
        
        // 4. 按totalCount降序排序，相同则按durationRecordCount降序
        let sortedResults = matchedResults.sorted {
            if $0.totalCount != $1.totalCount {
                return $0.totalCount > $1.totalCount
            }
            if $0.durationRecordCount != $1.durationRecordCount {
                return $0.durationRecordCount > $1.durationRecordCount
            }
            return $0.tag.id! < $1.tag.id!
        }
        
        return sortedResults
    }
}

extension LayoutGenerater {
    static func rearrangeArray(startingFrom value: WeekdayOrder, in array: [WeekdayOrder]) -> [WeekdayOrder] {
        guard let index = array.firstIndex(of: value) else {
            return array
        }
        let firstPart = array.suffix(from: index)
        let secondPart = array.prefix(index)
        return Array(firstPart + secondPart)
    }
}
