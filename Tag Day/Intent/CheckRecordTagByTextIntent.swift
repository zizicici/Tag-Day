//
//  CheckRecordTagByTextIntent.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/7/30.
//

import AppIntents
import ZCCalendar

enum TextMatchPolicy: Int, AppEnum {
    case equal
    case prefix
    case suffix
    case contain
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        return "intent.text.matchPolicy"
    }
    
    static var caseDisplayRepresentations: [TextMatchPolicy : DisplayRepresentation] {
        return [
            .equal: DisplayRepresentation(title: "intent.text.matchPolicy.equal"),
            .prefix: DisplayRepresentation(title: "intent.text.matchPolicy.prefix"),
            .suffix: DisplayRepresentation(title: "intent.text.matchPolicy.suffix"),
            .contain: DisplayRepresentation(title: "intent.text.matchPolicy.constain")
        ]
    }
}

struct CheckRecordTagByTextIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.record.check.tag.by.text.title"
    
    static var description: IntentDescription = IntentDescription("intent.record.check.tag.by.text.description", categoryName: "intent.record.check.category")
    
    @Parameter(title: "intent.record.dateValue", description: "intent.record.dateValue", kind: .date, requestValueDialog: IntentDialog("intent.record.dialog"))
    var date: Date
    
    @Parameter(title: "intent.book.type")
    var book: BookEntity
    
    @Parameter(title: "intent.text")
    var targetString: String
    
    @Parameter(title: "intent.text.matchPolicy", default: TextMatchPolicy.equal)
    var textMatchPolicy: TextMatchPolicy
    
    static var parameterSummary: some ParameterSummary {
        Summary("intent.record.check.tag.by.text.summary\(\.$book)\(\.$date)\(\.$targetString)") {
            \.$textMatchPolicy
        }
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        try? DataManager.shared.syncSharedDataToDatabase()
        
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        if let year = components.year, let month = components.month, let day = components.day, let month = Month(rawValue: month) {
            let day = GregorianDay(year: year, month: month, day: day)
            let bookID = book.id
            let records = try DataManager.shared.fetchAllDayRecords(bookID: Int64(bookID), day: Int64(day.julianDay))
            let tags = try DataManager.shared.fetchAllTags(bookID: Int64(bookID))
            let targetTag: DayRecord? = records.first { record in
                if let tag = tags.first(where: { $0.id == record.tagID }) {
                    switch textMatchPolicy {
                    case .equal:
                        return tag.title == targetString
                    case .prefix:
                        return tag.title.hasPrefix(targetString)
                    case .suffix:
                        return tag.title.hasSuffix(targetString)
                    case .contain:
                        return tag.title.contains(targetString)
                    }
                } else {
                    return false
                }
            }
            return .result(value: targetTag != nil)
        } else {
            throw FetchError.notFound
        }
    }
}
