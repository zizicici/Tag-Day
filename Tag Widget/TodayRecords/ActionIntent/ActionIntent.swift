//
//  ActionIntent.swift
//  Tag Widget
//
//  Created by Ci Zi on 2025/7/1.
//

import AppIntents
import WidgetKit

struct WidgetAddButtonActionIntent: AppIntent {
    init() {}
    
    init(bookID: Int, kind: String, family: Int?) {
        self.bookID = bookID
        self.kind = kind
        self.familyRawValue = family
    }
    
    static var title: LocalizedStringResource = "widget.intent.add.title"

    static var description: IntentDescription = IntentDescription("widget.intent.add.description")
    
    static var isDiscoverable: Bool = false
    
    @Parameter(title: "")
    var bookID: Int?
    
    @Parameter(title: "")
    var kind: String?
    
    @Parameter(title: "")
    var familyRawValue: Int?
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        guard let bookID = bookID, let kind = kind, let family = familyRawValue else {
            return .result(value: false)
        }
        
        guard let sharedData = try SharedDataManager.read(SharedData.self) else {
            return .result(value: false)
        }
        
        let tags = sharedData.tags.filter{ $0.bookID == bookID }
        
        let stateManager = WidgetStateManager.shared
        let currentState = stateManager.getState(kind: kind, family: family, bookID: bookID)
        let nextState: WidgetState
        switch currentState {
        case .idle:
            nextState = .showTags(index: 0)
        case .showTags(let index):
            let countPerPage = WidgetFamily(rawValue: family) == .systemSmall ? 3 : 6
            if index < ((tags.count + 2) / countPerPage) {
                nextState = .showTags(index: index + 1)
            } else {
                nextState = .idle
            }
        }
        stateManager.saveState(kind: kind, family: family, bookID: bookID, state: nextState)
        
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
        
        return .result(value: true)
    }
    
    static var openAppWhenRun: Bool = false
}

struct WidgetTagsNavigationActionIntent: AppIntent {
    init() {}
    
    init(bookID: Int, kind: String, family: Int?, toNext: Bool) {
        self.bookID = bookID
        self.kind = kind
        self.familyRawValue = family
        self.toNext = toNext
    }
    
    static var title: LocalizedStringResource = "widget.intent.scrollTag.title"

    static var description: IntentDescription = IntentDescription("widget.intent.scrollTag.description")
    
    static var isDiscoverable: Bool = false
    
    @Parameter(title: "")
    var bookID: Int?
    
    @Parameter(title: "")
    var kind: String?
    
    @Parameter(title: "")
    var familyRawValue: Int?
    
    @Parameter(title: "")
    var toNext: Bool?
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        guard let bookID = bookID, let kind = kind, let family = familyRawValue, let toNext = toNext else {
            return .result(value: false)
        }
        
        guard let sharedData = try SharedDataManager.read(SharedData.self) else {
            return .result(value: false)
        }
        
        let tags = sharedData.tags.filter{ $0.bookID == bookID }
        
        let stateManager = WidgetStateManager.shared
        let currentState = stateManager.getState(kind: kind, family: family, bookID: bookID)
        let nextState: WidgetState
        switch currentState {
        case .idle:
            nextState = .idle
        case .showTags(let index):
            let countPerPage = WidgetFamily(rawValue: family) == .systemSmall ? 3 : 6
            if toNext == true {
                if (index + 1) < ((tags.count + 2) / countPerPage) {
                    nextState = .showTags(index: index + 1)
                } else {
                    nextState = .idle
                }
            } else {
                if index - 1 >= 0 {
                    nextState = .showTags(index: index - 1)
                } else {
                    nextState = .idle
                }
            }
        }
        stateManager.saveState(kind: kind, family: family, bookID: bookID, state: nextState)
        
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
        
        return .result(value: true)
    }
    
    static var openAppWhenRun: Bool = false
}

struct WidgetExitButtonActionIntent: AppIntent {
    init() {}
    
    init(bookID: Int, kind: String, family: Int?) {
        self.bookID = bookID
        self.kind = kind
        self.familyRawValue = family
    }
    
    static var title: LocalizedStringResource = "widget.intent.closeTag.title"

    static var description: IntentDescription = IntentDescription("widget.intent.closeTag.description")
    
    static var isDiscoverable: Bool = false
    
    @Parameter(title: "")
    var bookID: Int?
    
    @Parameter(title: "")
    var kind: String?
    
    @Parameter(title: "")
    var familyRawValue: Int?
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        guard let bookID = bookID, let kind = kind, let family = familyRawValue else {
            return .result(value: false)
        }
        
        let stateManager = WidgetStateManager.shared
        stateManager.saveState(kind: kind, family: family, bookID: bookID, state: .idle)
        
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
        
        return .result(value: true)
    }
    
    static var openAppWhenRun: Bool = false
}

struct WidgetSelectTagActionIntent: AppIntent {
    init() {}
    
    init(bookID: Int, kind: String, family: Int?, tagID: Int, day: Int) {
        self.bookID = bookID
        self.kind = kind
        self.familyRawValue = family
        self.tagID = tagID
        self.day = day
    }
    
    static var title: LocalizedStringResource = "widget.intent.selectTag.title"

    static var description: IntentDescription = IntentDescription("widget.intent.selectTag.description")
    
    static var isDiscoverable: Bool = false
    
    @Parameter(title: "")
    var bookID: Int?
    
    @Parameter(title: "")
    var kind: String?
    
    @Parameter(title: "")
    var familyRawValue: Int?
    
    @Parameter(title: "")
    var tagID: Int?
    
    @Parameter(title: "")
    var day: Int?
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        guard let bookID = bookID, let kind = kind, let family = familyRawValue, let tagID = tagID, let day = day else {
            return .result(value: false)
        }
        
        guard var data = try? SharedDataManager.read(SharedData.self) else {
            return .result(value: false)
        }
        
        var maxOrder = data.dayRecord.filter({ $0.bookID == bookID && $0.day == day }).sorted(by: { $0.order > $1.order }).first?.order ?? 0
        if let otherWidgetRecord = data.widgetAddDayRecords.filter({ $0.bookID == bookID && $0.day == day }).sorted(by: { $0.order > $1.order }).first {
            maxOrder = Int64(otherWidgetRecord.order)
        }
        
        let newRecord = WidgetAddDayRecord(tagID: tagID, bookID: bookID, day: day, date: Int(Date().nanoSecondSince1970), order: Int(maxOrder) + 1)
        data.widgetAddDayRecords = data.widgetAddDayRecords + [newRecord]
        try? SharedDataManager.write(data)
        
        let stateManager = WidgetStateManager.shared
        stateManager.saveState(kind: kind, family: family, bookID: bookID, state: .idle)
        
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
        
        return .result(value: true)
    }
    
    static var openAppWhenRun: Bool = false
}
