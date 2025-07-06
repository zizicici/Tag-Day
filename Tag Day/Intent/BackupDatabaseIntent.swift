//
//  BackupDatabaseIntent.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/7/6.
//

import AppIntents

struct BackupDatabaseIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.backup.database.title"

    static var description: IntentDescription = IntentDescription("intent.backup.database.description", categoryName: "intent.backup.database.category")
    
    @Parameter(title: "intent.backup.database.overwrite", description: "intent.backup.database.overwrite.description", default: true)
    var overwrite: Bool
    
    static var parameterSummary: some ParameterSummary {
        Summary("intent.backup.database.summary") {
            \.$overwrite
        }
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        guard BackupManager.shared.iCloudDocumentIsAccessable else {
            throw BackupError.noAccess
        }
        let result = BackupManager.shared.backup(overwrite: overwrite)
        return .result(value: result)
    }
    
    static var openAppWhenRun: Bool = false
}
