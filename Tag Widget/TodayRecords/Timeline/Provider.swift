//
//  Provider.swift
//  Tag Widget
//
//  Created by Ci Zi on 2025/7/1.
//

import WidgetKit
import ZCCalendar

struct TodayRecordsWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> TodayRecordsEntry {
        TodayRecordsEntry.placeholder
    }

    func snapshot(for configuration: TodayRecordsConfigurationAppIntent, in context: Context) async -> TodayRecordsEntry {
        TodayRecordsEntry(date: Date(), configuration: configuration, tags: [], records: [])
    }
    
    func timeline(for configuration: TodayRecordsConfigurationAppIntent, in context: Context) async -> Timeline<TodayRecordsEntry> {
        var entries: [TodayRecordsEntry] = []
        let calendar = Calendar.current
        
        let currentDate = Date()
        let bookID = configuration.book?.id ?? -1
        
        let sharedData = try? SharedDataManager.read(SharedData.self)
        
        let tags: [Tag] = sharedData?.tags.filter{ $0.bookID == bookID } ?? []
        let records: [DayRecord] = sharedData?.dayRecord.filter{ $0.bookID == bookID } ?? []
        
        guard let nextMidnight = calendar.nextDate(
            after: currentDate,
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) else {
            let fallbackEntries = (0..<5).map { hourOffset in
                let entryDate = calendar.date(byAdding: .hour, value: hourOffset, to: currentDate)!
                let day = GregorianDay(from: entryDate)
                
                return TodayRecordsEntry(date: entryDate, configuration: configuration, tags: tags, records: records.filter({ $0.day == day.julianDay }))
            }
            return Timeline(entries: fallbackEntries, policy: .atEnd)
        }
        
        let day = GregorianDay(from: Date())
        let filterdRecords = records.filter({ $0.day == day.julianDay })
        let entry = TodayRecordsEntry(date: Date(), configuration: configuration, tags: tags, records: filterdRecords)
        entries.append(entry)
        
        for dayOffset in 0 ..< 4 {
            if let entryDate = calendar.date(byAdding: .day, value: dayOffset, to: nextMidnight) {
                let day = GregorianDay(from: entryDate)
                
                let filterdRecords = records.filter({ $0.day == day.julianDay })
                
                let entry = TodayRecordsEntry(date: entryDate, configuration: configuration, tags: tags, records: filterdRecords)
                entries.append(entry)
            }
        }
        
        return Timeline(entries: entries, policy: .after(entries.last?.date ?? currentDate))
    }

//    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}
