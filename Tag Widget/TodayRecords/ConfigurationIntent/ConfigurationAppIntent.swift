//
//  AppIntent.swift
//  Widget
//
//  Created by Ci Zi on 2025/6/29.
//

import WidgetKit
import AppIntents

enum WidgetTagSortPolicy: Int, AppEnum {
    case countFirst
    case orderFirst
    case orderLast
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        return "widget.config.tagSortPolicy"
    }
    
    static var caseDisplayRepresentations: [WidgetTagSortPolicy : DisplayRepresentation] {
        return [
            .countFirst: DisplayRepresentation(title: "widget.config.tagSortPolicy.countFirst"),
            .orderFirst: DisplayRepresentation(title: "widget.config.tagSortPolicy.orderFirst"),
            .orderLast: DisplayRepresentation(title: "widget.config.tagSortPolicy.orderLast")
        ]
    }
}

enum SecondaryCalendar: Int, AppEnum {
    case none
    case chineseCalendar
    case rokuyo
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        return "settings.secondaryCalendar.title"
    }
    
    static var caseDisplayRepresentations: [SecondaryCalendar : DisplayRepresentation] {
        return [
            .none: DisplayRepresentation(title: "settings.secondaryCalendar.none"),
            .chineseCalendar: DisplayRepresentation(title: "settings.secondaryCalendar.chineseCalendar"),
            .rokuyo: DisplayRepresentation(title: "settings.secondaryCalendar.rokuyo")
        ]
    }
}

struct TodayRecordsConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "" }
    static var description: IntentDescription { "" }
    
    @Parameter(title: "intent.book.type")
    var book: BookEntity?
    
    @Parameter(title: "widget.config.tagSortPolicy", default: WidgetTagSortPolicy.countFirst)
    var tagSortPolicy: WidgetTagSortPolicy?
    
    @Parameter(title: "settings.secondaryCalendar.title", default: SecondaryCalendar.none)
    var secondaryCalendar: SecondaryCalendar?
}

// For Preview
extension TodayRecordsConfigurationAppIntent {
    static var food: TodayRecordsConfigurationAppIntent {
        let intent = TodayRecordsConfigurationAppIntent()
        intent.book = BookEntity(id: -1, title: "均衡饮食", symbol: "fork.knife", color: "FF9500FF,FF9F0AFF")
        return intent
    }
    
    static var bird: TodayRecordsConfigurationAppIntent {
        let intent = TodayRecordsConfigurationAppIntent()
        intent.book = BookEntity(id: -2, title: "三小只", symbol: "bird", color: "34C759FF,30D158FF")
        return intent
    }
}

extension BookEntity {
    static let questionPlaceholder = BookEntity(id: -1, title: "", symbol: "questionmark.square.dashed", color: "FF9500FF,FF9F0AFF")
}

extension Tag {
    static let placeholder0 = Tag(bookID: -1, title: String(localized: "tag.placeholder.0"), color: "FF9500FF,FF9F0AFF", order: 0)
    static let placeholder1 = Tag(bookID: -1, title: String(localized: "tag.placeholder.1"), color: "FF9500BB,FF9F0ABB", order: 1)
    static let placeholder2 = Tag(bookID: -1, title: String(localized: "tag.placeholder.2"), color: "FF950099,FF9F0A99", order: 2)
}
