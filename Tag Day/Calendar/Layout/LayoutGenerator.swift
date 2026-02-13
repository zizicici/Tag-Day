//
//  LayoutGenerator.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/4/29.
//

import UIKit
import ZCCalendar

struct LayoutGenerater {
    static func dayLayout(for snapshot: inout NSDiffableDataSourceSnapshot<Section, Item>, months: [GregorianMonth], tags: [Tag], records: [DayRecord], allRecords: [DayRecord], selectedYear: Int) {
        let firstDayOfWeek: WeekdayOrder = WeekdayOrder(rawValue: WeekStartType.current.rawValue) ?? WeekdayOrder.firstDayOfWeek
        let monthlyStatsType = MonthlyStatsType.getValue()
        let yearlyStatsType = YearlyStatsType.getValue()
        let crossYearEnabled = CrossYearMonthDisplay.getValue() == .enable
        
        for gregorianMonth in months {
            let month = gregorianMonth.month
            let year = gregorianMonth.year
            let firstDay = GregorianDay(year: year, month: month, day: 1)
            let firstWeekOrder = firstDay.weekdayOrder()
            
            let firstOffset = (firstWeekOrder.rawValue - (firstDayOfWeek.rawValue % 7) + 7) % 7

            snapshot.appendSections([.row(gregorianMonth)])
            if firstOffset >= 1 {
                snapshot.appendItems(Array(1...firstOffset).map({ index in
                    let uuid = "\(year)-\(month.rawValue)-\(index)"
                    return Item.invisible(uuid)
                }))
            }
            
            let items: [BlockItem] = Array(1...ZCCalendar.manager.dayCount(at: month, year: year)).map({ day in
                let gregorianDay = GregorianDay(year: year, month: month, day: day)
                let julianDay = gregorianDay.julianDay
                
                let backgroundColor: UIColor = AppColor.paper
                let foregroundColor: UIColor = AppColor.text
                
                let secondaryCalendar: String?
                let a11ySecondaryCallendar: String?
                switch SecondaryCalendar.getValue() {
                case .none:
                    secondaryCalendar = nil
                    a11ySecondaryCallendar = secondaryCalendar
                case .chineseCalendar:
                    let chineseDayInfo = ChineseCalendarManager.shared.findChineseDayInfo(gregorianDay, variant: .chinese)
                    if let solarTerm = ChineseCalendarManager.shared.getSolarTerm(for: gregorianDay) {
                        secondaryCalendar = solarTerm.name
                        a11ySecondaryCallendar = (chineseDayInfo?.pronounceString() ?? "") + solarTerm.name
                    } else {
                        secondaryCalendar = chineseDayInfo?.shortDisplayString()
                        a11ySecondaryCallendar = chineseDayInfo?.pronounceString()
                    }
                case .rokuyo:
                    if let kyureki = ChineseCalendarManager.shared.findChineseDayInfo(gregorianDay, variant: .kyureki) {
                        secondaryCalendar = Rokuyo.get(at: kyureki).name
                    } else {
                        secondaryCalendar = nil
                    }
                    a11ySecondaryCallendar = secondaryCalendar
                }
                
                let isToday: Bool = TodayIndicator.getValue() == .enable ? ZCCalendar.manager.isToday(gregorianDay: gregorianDay) : false
                
                return BlockItem(index: julianDay, backgroundColor: backgroundColor, foregroundColor: foregroundColor, isToday: isToday, tags: tags, records: records.filter{ $0.day == gregorianDay.julianDay }, tagDisplayType: TagDisplayType.getValue(), secondaryCalendar: secondaryCalendar, a11ySecondaryCalendar: a11ySecondaryCallendar)
            })
            
            snapshot.appendItems(items.map{ Item.block($0) }, toSection: .row(gregorianMonth))
            
            if monthlyStatsType != .hidden {
                snapshot.appendSections([.info(gregorianMonth, .monthly)])
                
                let monthStart = Int64(ZCCalendar.manager.firstDay(at: gregorianMonth.month, year: gregorianMonth.year).julianDay)
                let monthEnd = Int64(ZCCalendar.manager.lastDay(at: gregorianMonth.month, year: gregorianMonth.year).julianDay)
                let monthStats = getTagStatistics(in: records, matching: tags, statsType: monthlyStatsType, dayRange: monthStart...monthEnd)
                
                snapshot.appendItems(monthStats.map {
                    Item.info(InfoItem(tag: $0.tag, count: $0.totalCount, range: .month(gregorianMonth)))
                }, toSection: .info(gregorianMonth, .monthly))
            }
            
            if yearlyStatsType != .hidden,
               shouldShowYearlyStats(after: gregorianMonth, selectedYear: selectedYear, crossYearEnabled: crossYearEnabled) {
                let targetYear = gregorianMonth.year
                let yearStart = Int64(GregorianDay(year: targetYear, month: .jan, day: 1).julianDay)
                let yearEnd = Int64(GregorianDay(year: targetYear, month: .dec, day: 31).julianDay)
                let yearStats = getTagStatistics(in: allRecords, matching: tags, statsType: yearlyStatsType.asMonthlyStatsType, dayRange: yearStart...yearEnd)
                
                snapshot.appendSections([.info(gregorianMonth, .yearly)])
                if yearStats.isEmpty {
                    snapshot.appendItems([.empty(String(localized: "calendar.yearlyStats.empty"))], toSection: .info(gregorianMonth, .yearly))
                } else {
                    snapshot.appendItems(yearStats.map {
                        Item.info(InfoItem(tag: $0.tag, count: $0.totalCount, range: .year(targetYear)))
                    }, toSection: .info(gregorianMonth, .yearly))
                }
            }
        }
    }
    
    static func shouldShowYearlyStats(after gregorianMonth: GregorianMonth, selectedYear: Int, crossYearEnabled: Bool) -> Bool {
        if gregorianMonth.month == .dec {
            return true
        }
        if crossYearEnabled, gregorianMonth.month == .jan, gregorianMonth.year == selectedYear + 1 {
            return true
        }
        return false
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

    static func getTagStatistics(in records: [DayRecord], matching tags: [Tag], statsType: MonthlyStatsType, dayRange: ClosedRange<Int64>) -> [TagStatistics] {
        let scopedRecords = records.filter { dayRange.contains($0.day) }
        
        // 1. 统计所有 tagID 的数据（包括 dayCount）
        var tagIDStats = [Int64: (
            totalCount: Int,          // 该 tagID 在所有 records 中出现的总次数
            totalDuration: Int64?,    // 该 tagID 在所有 records 中的总 duration
            durationRecordCount: Int, // 包含 duration 的 records 数量
            dayIDs: Set<Int64>        // 包含该 tagID 的唯一日期（用于计算 dayCount）
        )]()
        
        for record in scopedRecords {
            let tagID = record.tagID
            let currentStats = tagIDStats[tagID] ?? (0, 0, 0, Set<Int64>())
            
            var newTotalDuration = currentStats.totalDuration
            var newDurationRecordCount = currentStats.durationRecordCount
            var newDayIDs = currentStats.dayIDs
            
            if let recordDuration = record.duration {
                newTotalDuration = (newTotalDuration ?? 0) + recordDuration
                newDurationRecordCount += 1
            }
            newDayIDs.insert(record.day)
            
            tagIDStats[tagID] = (
                totalCount: currentStats.totalCount + 1,
                totalDuration: newTotalDuration,
                durationRecordCount: newDurationRecordCount,
                dayIDs: newDayIDs
            )
        }
        
        // 2. 创建 tagID 到 Tag 对象的映射
        let tagDictionary = Dictionary(uniqueKeysWithValues: tags.compactMap { tag -> (Int64, Tag)? in
            guard let tagID = tag.id else { return nil }
            return (tagID, tag)
        })
        
        // 3. 过滤并匹配结果，转换为 TagStatistics（增加 dayCount）
        let matchedResults = tagIDStats.compactMap { (tagID, stats) -> TagStatistics? in
            guard let matchingTag = tagDictionary[tagID] else { return nil }
            let totalCount: Int
            switch statsType {
            case .hidden:
                totalCount = 0
            case .loggedCount:
                totalCount = stats.totalCount
            case .dayCount:
                totalCount = stats.dayIDs.count
            }
            return TagStatistics(
                tag: matchingTag,
                totalCount: totalCount,
                totalDuration: stats.totalDuration,
                durationRecordCount: stats.durationRecordCount
            )
        }
        
        // 4. 按 totalCount 降序排序，相同则按 order 升序排序
        let sortedResults = matchedResults.sorted {
            if $0.totalCount != $1.totalCount {
                return $0.totalCount > $1.totalCount
            }
            return $0.tag.order < $1.tag.order
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
