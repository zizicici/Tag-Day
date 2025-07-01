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
        return (entry.tags.count + 2) / 3
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
    //                    .border(.black, width: 1.0)
                    
                    Spacer()
                    
                    Button(intent: WidgetAddButtonActionIntent(bookID: entry.book.id, kind: kind, family: family.rawValue)) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .tint(entry.color)
                    .widgetAccentable()
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
                    
                    Spacer()
                    
                    Button(intent: WidgetExitButtonActionIntent(bookID: entry.book.id, kind: kind, family: family.rawValue)) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .widgetAccentable()
                    
                    Spacer()
                    
                    Button(intent: WidgetTagsNavigationActionIntent(bookID: entry.book.id, kind: kind, family: family.rawValue, toNext: true)) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 20, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .tint(entry.color)
                    .widgetAccentable()
                    .disabled(pageIndex ?? 0 >= pageCount - 1)
                }
            }
            .padding(.vertical, 4.0)
            .frame(width: 48.0)
            Spacer()
            
            if isIdle {
                RecordContainerView(date: entry.date, weekday: entry.weekDay, secondaryString: entry.secondaryCalendarString, displayData: entry.tagDisplayData, policy: entry.configuration.tagSortPolicy ?? .countFirst)
            } else {
                if let pageIndex = pageIndex {
                    TagButtonView(tags: entry.tags, pageIndex: pageIndex, bookID: entry.book.id, kind: kind, familyRawValue: family.rawValue, day: GregorianDay(from: entry.date).julianDay)
                }
            }
        }
        .widgetURL(URL(string: "tagday://book/\(entry.book.id)"))
    }
}

struct TagButtonView: View {
    let tags: [Tag]
    let pageIndex: Int
    let tagsPerPage = 3
    let bookID: Int
    let kind: String
    let familyRawValue: Int
    let day: Int
    
    @Environment(\.widgetRenderingMode) var widgetRenderingMode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            let startIndex = pageIndex * tagsPerPage
            let endIndex = min(startIndex + tagsPerPage, tags.count)
            
            if startIndex < tags.count {
                ForEach(startIndex..<endIndex, id: \.self) { index in
                    Button(intent: WidgetSelectTagActionIntent(bookID: bookID, kind: kind, family: familyRawValue, tagID: Int(tags[index].id!), day: day)) {
                        Spacer(minLength: 0.0)
                        Text(tags[index].title)
                            .lineLimit(1)
                            .font(.system(size: 16, weight: .medium))
                            .minimumScaleFactor(0.75)
                            .foregroundStyle(tags[index].widgetTitleColor)
                            .widgetAccentable()
                        Spacer(minLength: 0.0)
                    }
                    .buttonStyle(widgetRenderingMode == .fullColor ? AnyPrimitiveButtonStyle(.borderedProminent) : AnyPrimitiveButtonStyle(.bordered))
                    .tint(tags[index].widgetColor)
                    .buttonBorderShape(.roundedRectangle(radius: 8.0))
                }
            } else {
                HStack {
                    Spacer(minLength: 0.0)
                    Text("widget.hint.noTags")
                        .lineLimit(1)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0.0)
                }
            }
        }
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
