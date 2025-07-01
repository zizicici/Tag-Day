//
//  EntryView.swift
//  Tag Widget
//
//  Created by Ci Zi on 2025/7/1.
//

import WidgetKit
import SwiftUI

struct TodayRecordsWidgetEntryView : View {
    var entry: TodayRecordsWidgetProvider.Entry

    var body: some View {
        HStack {
            VStack() {
                Image(systemName: entry.book.symbol)
                    .font(.system(size: 35, weight: .light))
                    .foregroundStyle(entry.color)
                    .frame(width: 50.0, height: 50.0)
//                    .border(.black, width: 1.0)
                Spacer()
                
                Button(intent: TodayRecordsConfigurationAppIntent.food) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .medium))
                }
                .buttonStyle(.bordered)
                .tint(entry.color)
//                .buttonBorderShape(.circle)
            }
            .padding(.vertical, 4.0)
            Spacer()
            RecordContainerView(date: entry.date, weekday: entry.weekDay, secondaryString: entry.secondaryCalendarString, displayData: entry.tagDisplayData, policy: entry.configuration.tagSortPolicy ?? .countFirst)
        }
        .widgetURL(URL(string: "tagday://book/\(entry.book.id)"))
    }
}
