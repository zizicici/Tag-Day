//
//  OpenBookIntent.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/7/6.
//

import AppIntents
import ZCCalendar
import UIKit

struct OpenBookIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.book.open.title"

    static var description: IntentDescription = IntentDescription("intent.book.open.description", categoryName: "intent.book.category")
    
    @Parameter(title: "intent.book.open.dateValue", description: "intent.book.open.dateValue", kind: .date, requestValueDialog: IntentDialog("intent.book.open.dialog"))
    var date: Date?

    @Parameter(title: "intent.book.type")
    var book: BookEntity
    
    static var parameterSummary: some ParameterSummary {
        Summary("intent.book.open.summary\(\.$book)") {
            \.$date
        }
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        DataManager.shared.select(bookID: Int64(book.id))
        if let date = date {
            let day = GregorianDay(from: date)
            if let topViewController = UIApplication.shared.topViewController() as? MainViewController {
                topViewController.display(to: day)
            }
        }
        
        return .result(value: true)
    }
    
    static var openAppWhenRun: Bool = true
}
