//
//  GetAllRecordsByDateIntent.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/12.
//

import AppIntents
import ZCCalendar

struct GetAllRecordsByDateIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.record.get.title"
    
    static var description: IntentDescription = IntentDescription("intent.record.get.description", categoryName: "intent.record.get.category")
    
    @Parameter(title: "intent.record.dateValue", description: "intent.record.dateValue", kind: .date, requestValueDialog: IntentDialog("intent.record.dialog"))
    var date: Date
    
    @Parameter(title: "intent.book.type")
    var book: BookEntity
    
    static var parameterSummary: some ParameterSummary {
        Summary("intent.record.get.summary\(\.$book)\(\.$date)")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[RecordEntity]> {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        if let year = components.year, let month = components.month, let day = components.day, let month = Month(rawValue: month) {
            let target = GregorianDay(year: year, month: month, day: day)
            let bookID = book.id
            let records = try DataManager.shared.fetchAllDayRecords(bookID: Int64(bookID), day: Int64(target.julianDay))
            let tags = try DataManager.shared.fetchAllTags(bookID: Int64(bookID))
            
            var tagEntities: [TagEntity] = []
            for tag in tags {
                if let tagID = tag.id {
                    tagEntities.append(TagEntity(id: Int(tagID), title: tag.title, subtitle: tag.subtitle ?? "", book: book, color: tag.color))
                }
            }
            
            var result: [RecordEntity] = []
            for record in records {
                if let tag = tagEntities.first(where: { $0.id == record.tagID }), let recordEntity = RecordEntity(tag: tag, book: book, record: record) {
                    result.append(recordEntity)
                }
            }
            return .result(value: result)
        } else {
            throw FetchError.notFound
        }
    }

    static var openAppWhenRun: Bool = false
}
