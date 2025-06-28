//
//  AddRecordIntent.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/6/28.
//

import AppIntents
import ZCCalendar

struct AddRecordIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.record.add.title"

    static var description: IntentDescription = IntentDescription("intent.record.add.description", categoryName: "intent.record.add.category")

    @Parameter(title: "intent.record.dateValue", description: "intent.record.dateValue", kind: .date, requestValueDialog: IntentDialog("intent.record.dialog"))
    var date: Date

    @Parameter(title: "intent.book.type")
    var book: BookEntity

    @Parameter(title: "intent.tag.type", optionsProvider: TagsOptionsProvider())
    var tag: TagEntity

    static var parameterSummary: some ParameterSummary {
        Summary("intent.record.add.summary\(\.$book)\(\.$date)\(\.$tag)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        if let year = components.year, let month = components.month, let day = components.day, let month = Month(rawValue: month) {
            let day = GregorianDay(year: year, month: month, day: day)
            let lastOrder = DataManager.shared.fetchLastRecordOrder(bookID: Int64(book.id), day: Int64(day.julianDay))
            let record: DayRecord = DayRecord(bookID: Int64(book.id), tagID: Int64(tag.id), day: Int64(day.julianDay), order: lastOrder + 1)
            let result = DataManager.shared.add(dayRecord: record)
            return .result(value: (result != nil))
        } else {
            throw FetchError.notFound
        }
    }

    static var openAppWhenRun: Bool = false
}
