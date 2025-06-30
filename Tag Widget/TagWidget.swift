//
//  Widget.swift
//  Widget
//
//  Created by Ci Zi on 2025/6/29.
//

import WidgetKit
import SwiftUI
import AppIntents
import ZCCalendar
import Collections

struct TagWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> TodayRecordEntry {
        TodayRecordEntry.placeholder
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> TodayRecordEntry {
        
        TodayRecordEntry(date: Date(), configuration: configuration, tags: [], records: [])
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<TodayRecordEntry> {
        var entries: [TodayRecordEntry] = []
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
                
                return TodayRecordEntry(date: entryDate, configuration: configuration, tags: tags, records: records.filter({ $0.day == day.julianDay }))
            }
            return Timeline(entries: fallbackEntries, policy: .atEnd)
        }
        
        let day = GregorianDay(from: Date())
        let filterdRecords = records.filter({ $0.day == day.julianDay })
        let entry = TodayRecordEntry(date: Date(), configuration: configuration, tags: tags, records: filterdRecords)
        entries.append(entry)
        
        for dayOffset in 0 ..< 4 {
            if let entryDate = calendar.date(byAdding: .day, value: dayOffset, to: nextMidnight) {
                let day = GregorianDay(from: entryDate)
                
                let filterdRecords = records.filter({ $0.day == day.julianDay })
                
                let entry = TodayRecordEntry(date: entryDate, configuration: configuration, tags: tags, records: filterdRecords)
                entries.append(entry)
            }
        }
        
        return Timeline(entries: entries, policy: .after(entries.last?.date ?? currentDate))
    }

//    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}

struct TodayRecordEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let tags: [Tag]
    let records: [DayRecord]
    
    static let placeholder: Self = TodayRecordEntry.init(date: Date(), configuration: ConfigurationAppIntent(), tags: [], records: [])
}

struct TagWidgetEntryView : View {
    var entry: TagWidgetProvider.Entry
    
    var book: BookEntity? {
        return entry.configuration.book
    }
    
    var color: Color? {
        if let book = book {
            return Color(uiColor: UIColor(string: book.color) ?? UIColor.green)
        } else {
            return nil
        }
    }
    
    var orderedCounts: OrderedDictionary<Int64, Int> {
        var counts = OrderedDictionary<Int64, Int>()
        entry.records.forEach { record in
            counts[record.tagID, default: 0] += 1
        }
        return counts
    }
    
    var tagDisplayData: [TagDisplayData] {
        switch entry.configuration.tagSortPolicy {
        case .none, .some(.countFirst):
            orderedCounts.compactMap { key, value in
                entry.tags.first(where: { $0.id == key }).map { tag in
                    TagDisplayData(tag: tag, count: value)
                }
            }
        case .some(.orderFirst), .some(.orderLast):
            entry.records.compactMap { record in
                entry.tags.first(where: { $0.id == record.tagID }).map { tag in
                    TagDisplayData(tag: tag, count: 1)
                }
            }
        }
    }

    var body: some View {
        if let book = book, let color = color {
            HStack {
                VStack() {
                    Image(systemName: book.symbol)
                        .font(.system(size: 35, weight: .light))
                        .foregroundStyle(color)
                        .frame(width: 50.0, height: 50.0)
//                        .border(.black, width: 1.0)
                    Spacer()

                    Button(intent: ConfigurationAppIntent.food) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .tint(color)
//                    .buttonBorderShape(.circle)
                }
                .padding(.vertical, 4.0)
                Spacer()
                RecordContainerView(tags: tagDisplayData, policy: entry.configuration.tagSortPolicy ?? .countFirst)
            }
            .widgetURL(URL(string: "tagday://book/\(book.id)"))
        } else {
            Text("widget.empty.hint")
        }
    }
}

struct TagWidget: Widget {
    let kind: String = "TagWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: TagWidgetProvider()) { entry in
            TagWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

extension ConfigurationAppIntent {
    static var food: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.book = BookEntity(id: -1, title: "均衡饮食", symbol: "fork.knife", color: "FF9500FF,FF9F0AFF")
        return intent
    }
    
    fileprivate static var bird: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.book = BookEntity(id: -2, title: "三小只", symbol: "bird", color: "34C759FF,30D158FF")
        return intent
    }
}

#Preview(as: .systemSmall) {
    TagWidget()
} timeline: {
    TodayRecordEntry(date: .now, configuration: .food, tags: [], records: [])
    TodayRecordEntry(date: .now, configuration: .bird, tags: [], records: [])
}
