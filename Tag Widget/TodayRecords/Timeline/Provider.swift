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
        TodayRecordsEntry(date: Date(), configuration: configuration, tags: [], records: [], state: .idle)
    }
    
    func timeline(for configuration: TodayRecordsConfigurationAppIntent, in context: Context) async -> Timeline<TodayRecordsEntry> {
        let calendar = Calendar.current
        
        let currentDate = Date()
        let bookID = configuration.book?.id ?? -1
        
        let stateManager = WidgetStateManager.shared
        let state = stateManager.getState(kind: TodayRecordsWidgetKindString, family: context.family.rawValue, bookID: bookID)
        
        let sharedData = try? SharedDataManager.read(SharedData.self)
        
        let tags: [Tag] = sharedData?.tags.filter{ $0.bookID == bookID } ?? []
        var records: [DayRecord] = sharedData?.dayRecord.filter{ $0.bookID == bookID } ?? []
        
        if let widgetAddDayRecords = sharedData?.widgetAddDayRecords, widgetAddDayRecords.count > 0 {
            let fakeRecords: [DayRecord] = widgetAddDayRecords.filter{ $0.bookID == bookID }.map({ widgetRecord in
                return .init(bookID: Int64(widgetRecord.bookID), tagID: Int64(widgetRecord.tagID), day: Int64(widgetRecord.day), order: Int64(widgetRecord.order))
            })
            records.append(contentsOf: fakeRecords)
        }
        
        var timePoints = [currentDate]

        if let nextMidnight = calendar.nextDate(
            after: currentDate,
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) {
            timePoints += (0..<4).compactMap {
                calendar.date(byAdding: .day, value: $0, to: nextMidnight)
            }
        } else {
            timePoints += (1..<5).compactMap {
                calendar.date(byAdding: .hour, value: $0, to: currentDate)
            }
        }
        
        let entries = timePoints.map { date in
            let day = GregorianDay(from: date)
            let filteredRecords = records.filter { $0.day == day.julianDay }.sorted(by: { $0.order < $1.order })
            return TodayRecordsEntry(
                date: date,
                configuration: configuration,
                tags: tags.sorted(by: { $0.order < $1.order }),
                records: filteredRecords,
                state: state
            )
        }
        
        return Timeline(entries: entries, policy: .after(entries.last?.date ?? currentDate))
    }

//    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}
