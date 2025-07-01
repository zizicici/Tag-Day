//
//  EntryView.swift
//  Tag Widget
//
//  Created by Ci Zi on 2025/7/1.
//

import WidgetKit
import SwiftUI
import Collections

struct TodayRecordsWidgetEntryView : View {
    var entry: TodayRecordsWidgetProvider.Entry
    
    var book: BookEntity {
        return entry.configuration.book ?? BookEntity.questionPlaceholder
    }
    
    var color: Color {
        return Color(uiColor: UIColor(string: book.color) ?? UIColor.green)
    }
    
    var orderedCounts: OrderedDictionary<Int64, Int> {
        var counts = OrderedDictionary<Int64, Int>()
        entry.records.forEach { record in
            counts[record.tagID, default: 0] += 1
        }
        return counts
    }
    
    var tagDisplayData: [RecordDisplayData] {
        guard book != BookEntity.questionPlaceholder else {
            return [RecordDisplayData(tag: Tag.placeholder0), RecordDisplayData(tag: Tag.placeholder1), RecordDisplayData(tag: Tag.placeholder2)]
        }
        switch entry.configuration.tagSortPolicy {
        case .none, .some(.countFirst):
            return orderedCounts.compactMap { key, value in
                entry.tags.first(where: { $0.id == key }).map { tag in
                    RecordDisplayData(tag: tag, count: value)
                }
            }
        case .some(.orderFirst), .some(.orderLast):
            return entry.records.compactMap { record in
                entry.tags.first(where: { $0.id == record.tagID }).map { tag in
                    RecordDisplayData(tag: tag, count: 1)
                }
            }
        }
    }

    var body: some View {
        HStack {
            VStack() {
                Image(systemName: book.symbol)
                    .font(.system(size: 35, weight: .light))
                    .foregroundStyle(color)
                    .frame(width: 50.0, height: 50.0)
//                    .border(.black, width: 1.0)
                Spacer()
                
                Button(intent: TodayRecordsConfigurationAppIntent.food) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .medium))
                }
                .buttonStyle(.bordered)
                .tint(color)
//                .buttonBorderShape(.circle)
            }
            .padding(.vertical, 4.0)
            Spacer()
            RecordContainerView(displayData: tagDisplayData, policy: entry.configuration.tagSortPolicy ?? .countFirst)
        }
        .widgetURL(URL(string: "tagday://book/\(book.id)"))
    }
}
