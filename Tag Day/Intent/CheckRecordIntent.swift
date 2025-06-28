//
//  CheckRecordIntent.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/12.
//

import AppIntents
import ZCCalendar

struct CheckRecordIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.record.check.title"
    
    static var description: IntentDescription = IntentDescription("intent.record.check.description", categoryName: "intent.record.check.category")
    
    @Parameter(title: "intent.record.dateValue", description: "intent.record.dateValue", kind: .date, requestValueDialog: IntentDialog("intent.record.dialog"))
    var date: Date
    
    @Parameter(title: "intent.book.type")
    var book: BookEntity
    
    @Parameter(title: "intent.tag.type", optionsProvider: TagsOptionsProvider())
    var targetTag: TagEntity
    
    static var parameterSummary: some ParameterSummary {
        Summary("intent.record.check.summary\(\.$book)\(\.$date)\(\.$targetTag)")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        if let year = components.year, let month = components.month, let day = components.day, let month = Month(rawValue: month) {
            let day = GregorianDay(year: year, month: month, day: day)
            let bookID = book.id
            let records = try DataManager.shared.fetchAllDayRecords(bookID: Int64(bookID), day: Int64(day.julianDay))
            let containTargetTag: Bool = records.first(where: { $0.tagID == targetTag.id }) != nil
            return .result(value: containTargetTag)
        } else {
            throw FetchError.notFound
        }
    }

    static var openAppWhenRun: Bool = false
}

struct CheckTomorrowRecordIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.record.check.tomorrow.title"
    
    static var description: IntentDescription = IntentDescription("intent.record.check.description", categoryName: "intent.record.check.category")
    
    @Parameter(title: "intent.book.type")
    var book: BookEntity
    
    @Parameter(title: "intent.tag.type", optionsProvider: TagsOptionsProvider())
    var targetTag: TagEntity
    
    static var parameterSummary: some ParameterSummary {
        Summary("intent.record.check.tomorrow.summary\(\.$book)\(\.$targetTag)")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let components = Calendar.current.dateComponents([.year, .month, .day], from: tomorrow)
        if let year = components.year, let month = components.month, let day = components.day, let month = Month(rawValue: month) {
            let day = GregorianDay(year: year, month: month, day: day)
            let bookID = book.id
            let records = try DataManager.shared.fetchAllDayRecords(bookID: Int64(bookID), day: Int64(day.julianDay))
            let containTargetTag: Bool = records.first(where: { $0.tagID == targetTag.id }) != nil
            return .result(value: containTargetTag)
        } else {
            throw FetchError.notFound
        }
    }

    static var openAppWhenRun: Bool = false
}
