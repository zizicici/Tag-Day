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

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "" }
    static var description: IntentDescription { "" }

    @Parameter(title: "intent.book.type")
    var book: BookEntity?
    
    @Parameter(title: "widget.config.tagSortPolicy", default: WidgetTagSortPolicy.countFirst)
    var tagSortPolicy: WidgetTagSortPolicy?
}
