//
//  Entry.swift
//  Tag Widget
//
//  Created by Ci Zi on 2025/7/1.
//

import WidgetKit

struct TodayRecordsEntry: TimelineEntry {
    let date: Date
    let configuration: TodayRecordsConfigurationAppIntent
    let tags: [Tag]
    let records: [DayRecord]
    
    static let placeholder: Self = TodayRecordsEntry.init(date: Date(), configuration: TodayRecordsConfigurationAppIntent(), tags: [], records: [])
}
