//
//  Widget.swift
//  Widget
//
//  Created by Ci Zi on 2025/6/29.
//

import WidgetKit
import SwiftUI

let TodayRecordsWidgetKindString: String = "TodayRecordsWidget"

struct TodayRecordsWidget: Widget {
    
    let kind: String = TodayRecordsWidgetKindString

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: TodayRecordsConfigurationAppIntent.self, provider: TodayRecordsWidgetProvider()) { entry in
            TodayRecordsWidgetEntryView(entry: entry, kind: kind)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    TodayRecordsWidget()
} timeline: {
    TodayRecordsEntry(date: .now, configuration: .food, tags: [], records: [], state: .idle)
    TodayRecordsEntry(date: .now, configuration: .bird, tags: [], records: [], state: .idle)
}
