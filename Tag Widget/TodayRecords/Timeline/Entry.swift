//
//  Entry.swift
//  Tag Widget
//
//  Created by Ci Zi on 2025/7/1.
//

import WidgetKit
import ZCCalendar
import Collections
import SwiftUI
import UIKit

struct TodayRecordsEntry: TimelineEntry {
    let date: Date
    let configuration: TodayRecordsConfigurationAppIntent
    let tags: [Tag]
    let records: [DayRecord]
    let state: WidgetState
    
    static let placeholder: Self = TodayRecordsEntry.init(date: Date(), configuration: TodayRecordsConfigurationAppIntent(), tags: [], records: [], state: .idle)
}

extension TodayRecordsEntry {
    var book: BookEntity {
        return configuration.book ?? BookEntity.questionPlaceholder
    }
    
    var color: Color {
        return Color(uiColor: UIColor(string: book.color) ?? UIColor.green)
    }
    
    var orderedCounts: OrderedDictionary<Int64, Int> {
        var counts = OrderedDictionary<Int64, Int>()
        records.forEach { record in
            counts[record.tagID, default: 0] += 1
        }
        return OrderedDictionary(uniqueKeysWithValues: counts.sorted { $0.value > $1.value })
    }
    
    var tagDisplayData: [RecordDisplayData] {
        guard book != BookEntity.questionPlaceholder else {
            return [RecordDisplayData(tag: Tag.placeholder0), RecordDisplayData(tag: Tag.placeholder1), RecordDisplayData(tag: Tag.placeholder2)]
        }
        switch configuration.tagSortPolicy {
        case .none, .some(.countFirst):
            return orderedCounts.compactMap { key, value in
                tags.first(where: { $0.id == key }).map { tag in
                    RecordDisplayData(tag: tag, count: value)
                }
            }
        case .some(.orderFirst), .some(.orderLast):
            return records.compactMap { record in
                tags.first(where: { $0.id == record.tagID }).map { tag in
                    RecordDisplayData(tag: tag, count: 1)
                }
            }
        }
    }
    
    var gregorianDay: GregorianDay {
        return GregorianDay(from: date)
    }
    
    var weekDay: String {
        return gregorianDay.weekdayOrder().getShortSymbol()
    }
    
    var secondaryCalendarString: String? {
        guard let secondaryCalendar = configuration.secondaryCalendar else { return nil }
        switch secondaryCalendar {
        case .none:
            return nil
        case .chineseCalendar:
            if let solarTerm = ChineseCalendarManager.shared.getSolarTerm(for: gregorianDay) {
                return solarTerm.name
            } else {
                return ChineseCalendarManager.shared.findChineseDayInfo(gregorianDay, variant: .chinese)?.shortDisplayString()
            }
        case .rokuyo:
            if let kyureki = ChineseCalendarManager.shared.findChineseDayInfo(gregorianDay, variant: .kyureki) {
                return Rokuyo.get(at: kyureki).name
            } else {
                return nil
            }
        }
    }
}
