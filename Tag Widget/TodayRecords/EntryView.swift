//
//  EntryView.swift
//  Tag Widget
//
//  Created by Ci Zi on 2025/7/1.
//

import WidgetKit
import SwiftUI
import ZCCalendar

struct TodayRecordsWidgetEntryView : View {
    var entry: TodayRecordsWidgetProvider.Entry
    var kind: String
    @Environment(\.widgetFamily) private var family
    
    var state: WidgetState {
        return entry.state
    }
    
    var isIdle: Bool {
        if entry.book.id == -1 {
            return true
        }
        return state == WidgetState.idle
    }
    
    var pageIndex: Int? {
        switch state {
        case .idle:
            return nil
        case .showTags(let index):
            return index
        }
    }
    
    var pageCount: Int {
        let countPerPage = family == .systemSmall ? 3 : 6
        return (entry.tags.count + 2) / countPerPage
    }

    var body: some View {
        HStack {
            VStack() {
                if isIdle {
                    Image(systemName: entry.book.symbol)
                        .font(.system(size: 35, weight: .light))
                        .foregroundStyle(entry.color)
                        .frame(width: 50.0, height: 50.0)
                        .widgetAccentable()
                        .accessibilityLabel(entry.book.title)
                        .accessibilitySortPriority(102)
    //                    .border(.black, width: 1.0)
                    
                    Spacer()
                    
                    Button(intent: WidgetAddButtonActionIntent(bookID: entry.book.id, kind: kind, family: family.rawValue)) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .tint(entry.color)
                    .widgetAccentable()
                    .accessibilitySortPriority(101)
    //                .buttonBorderShape(.circle)
                } else {
                    Button(intent: WidgetTagsNavigationActionIntent(bookID: entry.book.id, kind: kind, family: family.rawValue, toNext: false)) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 20, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .tint(entry.color)
                    .widgetAccentable()
                    .disabled(pageIndex == 0)
                    .accessibilitySortPriority(102)
                    
                    Spacer()
                    
                    Button(intent: WidgetExitButtonActionIntent(bookID: entry.book.id, kind: kind, family: family.rawValue)) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .widgetAccentable()
                    .accessibilitySortPriority(101)
                    
                    Spacer()
                    
                    Button(intent: WidgetTagsNavigationActionIntent(bookID: entry.book.id, kind: kind, family: family.rawValue, toNext: true)) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 20, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .tint(entry.color)
                    .widgetAccentable()
                    .disabled(pageIndex ?? 0 >= pageCount - 1)
                    .accessibilitySortPriority(102)
                }
            }
            .padding(.vertical, 4.0)
            .frame(width: 48.0)
            Spacer()
            
            if isIdle {
                if family == .systemSmall {
                    RecordContainerView(date: entry.date, weekday: entry.weekDay, secondaryString: entry.secondaryCalendarString, displayData: entry.tagDisplayData, policy: entry.configuration.tagSortPolicy ?? .countFirst, columnCount: 1)
                        .privacySensitive()
                } else {
                    RecordContainerView(date: entry.date, weekday: entry.weekDay, secondaryString: entry.secondaryCalendarString, displayData: entry.tagDisplayData, policy: entry.configuration.tagSortPolicy ?? .countFirst, columnCount: entry.configuration.columnCount?.numberOfColumns ?? 1)
                        .privacySensitive()
                }
            } else {
                if User.shared.proTier() == .none {
                    HStack {
                        Spacer(minLength: 0)
                        Text("pro.needed")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 0)
                    }
                } else {
                    if let pageIndex = pageIndex {
                        TagButtonView(tags: entry.tags, pageIndex: pageIndex, columns: family == .systemSmall ? 1 : 2, bookID: entry.book.id, kind: kind, familyRawValue: family.rawValue, day: GregorianDay(from: entry.date).julianDay)
                            .privacySensitive()
                    }
                }
            }
        }
        .widgetURL(URL(string: "tagday://book/\(entry.book.id)"))
    }
}

struct TagButtonView: View {
    let tags: [Tag]
    let pageIndex: Int
    let columns: Int
    let bookID: Int
    let kind: String
    let familyRawValue: Int
    let day: Int
    
    @Environment(\.widgetRenderingMode) var widgetRenderingMode
    
    // 计算属性
    private var tagsPerPage: Int {
        columns * 3 // 每页显示列数×3行
    }
    
    private var tagsPerColumn: Int {
        3 // 每列固定显示3个按钮
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            if tags.count == 0 {
                Spacer(minLength: 0)
                emptyTagView
                Spacer(minLength: 0)
            } else {
                ForEach(0..<columns, id: \.self) { column in
                    columnView(for: column)
                }
            }
        }
        .padding(4)
    }
    
    // 单列视图
    private func columnView(for column: Int) -> some View {
        VStack(alignment: .center, spacing: 2) {
            Spacer(minLength: 0)
            let startIndex = pageIndex * tagsPerPage + column * tagsPerColumn
            let endIndex = min(startIndex + tagsPerColumn, tags.count)
            
            if startIndex < tags.count {
                ForEach(startIndex..<endIndex, id: \.self) { index in
                    tagButton(for: tags[index])
                        .accessibilitySortPriority(Double((columns - column) * 10 - index))
                }
            }
            
            // 补充不足的按钮以保持高度一致
            if endIndex - startIndex < tagsPerColumn {
                ForEach(0..<(tagsPerColumn - (endIndex - startIndex)), id: \.self) { _ in
                    Color.clear.frame(height: 40) // 保持高度一致
                }
            }
            Spacer(minLength: 0)
        }
    }
    
    // 单个标签按钮
    private func tagButton(for tag: Tag) -> some View {
        Button(intent: WidgetSelectTagActionIntent(
            bookID: bookID,
            kind: kind,
            family: familyRawValue,
            tagID: Int(tag.id!),
            day: day
        )) {
            Text(tag.title)
                .lineLimit(1)
                .font(.system(size: 16, weight: .medium))
                .minimumScaleFactor(0.75)
                .foregroundStyle(tag.widgetTitleColor)
                .widgetAccentable()
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(widgetRenderingMode == .fullColor ?
                    AnyPrimitiveButtonStyle(.borderedProminent) :
                    AnyPrimitiveButtonStyle(.bordered))
        .tint(tag.widgetColor)
        .buttonBorderShape(.roundedRectangle(radius: 8))
        .frame(height: 40)
    }
    
    // 无标签时的提示视图
    private var emptyTagView: some View {
        Text("widget.hint.noTags")
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(.secondary)
    }
}

struct AnyPrimitiveButtonStyle: PrimitiveButtonStyle {
    private let _makeBody: (Configuration) -> AnyView

    init<S: PrimitiveButtonStyle>(_ style: S) {
        _makeBody = { configuration in
            AnyView(style.makeBody(configuration: configuration))
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        _makeBody(configuration)
    }
}
