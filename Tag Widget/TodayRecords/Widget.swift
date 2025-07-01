//
//  Widget.swift
//  Widget
//
//  Created by Ci Zi on 2025/6/29.
//

import WidgetKit
import SwiftUI

struct TodayRecordsWidget: Widget {
    let kind: String = "TodayRecordsWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: TodayRecordsConfigurationAppIntent.self, provider: TodayRecordsWidgetProvider()) { entry in
            TodayRecordsWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    TodayRecordsWidget()
} timeline: {
    TodayRecordsEntry(date: .now, configuration: .food, tags: [], records: [])
    TodayRecordsEntry(date: .now, configuration: .bird, tags: [], records: [])
}
