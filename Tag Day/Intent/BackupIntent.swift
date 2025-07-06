//
//  BackupIntent.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/7/6.
//

import AppIntents

struct BackupIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.backup.title"

    static var description: IntentDescription = IntentDescription("intent.backup.description", categoryName: "intent.backup.category")
    
    @Parameter(title: "intent.backup.overwrite", description: "intent.backup.overwrite.description", default: true)
    var overwrite: Bool
    
    static var parameterSummary: some ParameterSummary {
        Summary("intent.backup.summary") {
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

