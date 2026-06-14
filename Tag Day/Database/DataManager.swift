//
//  DataManager.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/3.
//

import Foundation
import GRDB
import ZCCalendar

extension Notification.Name {
    static let CurrentBookChanged = Notification.Name(rawValue: "com.zizicici.data.currentBook.changed")
    static let BooksUpdated = Notification.Name(rawValue: "com.zizicici.data.books.updated")
    static let TagsUpdated = Notification.Name(rawValue: "com.zizicici.data.tags.updated")
    static let ActiveTagsUpdated = Notification.Name(rawValue: "com.zizicici.data.activeTags.updated")
    static let DayRecordsUpdated = Notification.Name(rawValue: "com.zizicici.data.dayRecords.updated")
}

class DataManager {
    static let shared = DataManager()
    
    var currentBook: Book? {
        didSet {
            // Update DayRecords and Tags
            updateTags()
            updateDayRecords()
            if oldValue != currentBook {
                NotificationCenter.default.post(Notification(name: Notification.Name.CurrentBookChanged))
            }
        }
    }
    
    var books: [Book] = [] {
        didSet {
            if oldValue != books {
                updateCurrentBookIfNeeded()
                NotificationCenter.default.post(Notification(name: Notification.Name.BooksUpdated))
            }
        }
    }
    
    var tags: [Tag] = [] {
        didSet {
            if oldValue != tags {
                activeTags = tags
                NotificationCenter.default.post(Notification(name: Notification.Name.TagsUpdated))
            }
        }
    }
    
    var activeTags: [Tag] = [] {
        didSet {
            if oldValue != activeTags {
                NotificationCenter.default.post(Notification(name: Notification.Name.ActiveTagsUpdated))
            }
        }
    }
    
    var dayRecords: [DayRecord] = [] {
        didSet {
            if oldValue != dayRecords {
                NotificationCenter.default.post(Notification(name: Notification.Name.DayRecordsUpdated))
            }
        }
    }
    
    init() {
        reloadData()
        
        NotificationCenter.default.post(Notification(name: Notification.Name.CurrentBookChanged))
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .DatabaseUpdated, object: nil)
    }
    
    func updateCurrentBookIfNeeded() {
        let activeBooks = books.filter({ $0.bookType == .active }).sorted(by: { $0.order < $1.order })
        if activeBooks.count == 0 {
            currentBook = nil
        } else {
            if let selectedBook = currentBook {
                // Check in activeBooks
                if let matchedBook = activeBooks.first(where: { $0.id == selectedBook.id }) {
                    currentBook = matchedBook
                } else {
                    currentBook = activeBooks.first
                }
            } else {
                currentBook = activeBooks.first
            }
        }
    }
    
    @objc
    func reloadData() {
        updateBooks()
        updateCurrentBookIfNeeded()
    }
    
    public func select(bookID: Int64) {
        if let targetBook = books.first(where: { $0.id == bookID }) {
            select(book: targetBook)
        }
    }
    
    public func select(book: Book?) {
        self.currentBook = book
    }
    
    private func updateBooks() {
        if let result = try? fetchAllBooks() {
            books = result
        } else {
            books = []
        }
    }
    
    private func updateTags() {
        if let currentBookID = currentBook?.id, let result = try? fetchAllTags(bookID: currentBookID) {
            tags = result
        } else {
            tags = []
        }
    }
    
    private func updateDayRecords() {
        if let currentBookID = currentBook?.id, let result = try? fetchAllDayRecords(bookID: currentBookID) {
            dayRecords = result
        } else {
            dayRecords = []
        }
    }
    
    public func toggleActiveState(to tag: Tag) {
        guard tags.contains(tag) else { return }
        if activeTags.contains(tag) {
            activeTags.removeAll(where: { $0 == tag })
        } else {
            activeTags.append(tag)
        }
    }
    
    public func toggleActive(only tag: Tag) {
        guard tags.contains(tag) else { return }
        activeTags = [tag]
    }
    
    public func resetActiveToggle(blank: Bool) {
        if blank {
            activeTags = []
        } else {
            activeTags = tags
        }
    }
}

fileprivate extension DataManager {
    func hasBook(id: Int64) -> Bool {
        return (try? fetchBook(id: id)) != nil
    }

    func validate(tag: Tag, shouldExist: Bool) -> Bool {
        if shouldExist {
            guard let tagID = tag.id, let storedTag = try? fetchTag(id: tagID) else { return false }
            guard storedTag.bookID == tag.bookID else { return false }
        } else {
            guard tag.id == nil else { return false }
        }

        return hasBook(id: tag.bookID)
    }

    func validate(tags: [Tag], shouldExist: Bool) -> Bool {
        return !tags.contains { !validate(tag: $0, shouldExist: shouldExist) }
    }

    func validate(dayRecord: DayRecord, shouldExist: Bool) -> Bool {
        return validate(dayRecords: [dayRecord], shouldExist: shouldExist)
    }

    func validate(dayRecords: [DayRecord], shouldExist: Bool) -> Bool {
        if shouldExist {
            guard !dayRecords.contains(where: { $0.id == nil }) else { return false }
        } else {
            guard !dayRecords.contains(where: { $0.id != nil }) else { return false }
        }

        let tagIDs = Set(dayRecords.map(\.tagID))
        let storedTags = (try? fetchTags(ids: Array(tagIDs))) ?? []
        guard Set(storedTags.compactMap(\.id)) == tagIDs else { return false }

        let tagBookIDs = Dictionary(uniqueKeysWithValues: storedTags.compactMap { tag in
            tag.id.map { ($0, tag.bookID) }
        })

        return !dayRecords.contains { record in
            tagBookIDs[record.tagID] != record.bookID
        }
    }

    func validate(bookConfig: BookConfig, shouldExist: Bool) -> Bool {
        if shouldExist {
            guard bookConfig.id != nil else { return false }
        } else {
            guard bookConfig.id == nil else { return false }
        }

        return hasBook(id: bookConfig.bookID)
    }
}

// Book
extension DataManager {
    func fetchBook(id: Int64) throws -> Book? {
        var result: Book?
        try AppDatabase.shared.reader?.read{ db in
            do {
                result = try Book.fetchOne(db, id: id)
            }
            catch {
                print(error)
            }
        }
        
        return result
    }
    
    func fetchBooks(ids: [Int64]) throws -> [Book] {
        var result: [Book] = []
        try AppDatabase.shared.reader?.read{ db in
            do {
                result = try Book.fetchAll(db, ids: ids)
            }
            catch {
                print(error)
            }
        }
        
        return result
    }
    
    func fetchAllBooks() throws -> [Book] {
        var result: [Book] = []
        try AppDatabase.shared.reader?.read{ db in
            do {
                let orderColumn = Book.Columns.order
                result = try Book
                    .order(orderColumn.asc)
                    .fetchAll(db)
            }
            catch {
                print(error)
            }
        }
        
        return result
    }
    
    func fetchAllBookInfos() throws -> [BookInfo] {
        var result: [BookInfo] = []
        
        try AppDatabase.shared.reader?.read{ db in
            do {
                let bookTypeColumn = Book.Columns.bookType
                let orderColumn = Book.Columns.order
                let books = try Book
                    .order(bookTypeColumn.asc)
                    .order(orderColumn.asc)
                    .fetchAll(db)
                result = books.compactMap({ book in
                    if let bookID = book.id {
                        let dayRecordBookColumn = DayRecord.Columns.bookID
                        let dayRecordCount = try? DayRecord.filter(dayRecordBookColumn == bookID).fetchCount(db)
                        let tagBookColumn = Tag.Columns.bookID
                        let tagCount = try? Tag.filter(tagBookColumn == bookID).fetchCount(db)
                        return BookInfo(book: book, tagCount: tagCount ?? 0, dayRecordCount: dayRecordCount ?? 0)
                    } else {
                        return nil
                    }
                })
            }
            catch {
                print(error)
            }
        }
        
        return result
    }
    
    func fetchAllBooks(for bookType: BookType) throws -> [Book] {
        var result: [Book] = []
        try AppDatabase.shared.reader?.read{ db in
            do {
                let bookTypeColumn = Book.Columns.bookType
                let orderColumn = Book.Columns.order
                result = try Book
                    .filter(bookTypeColumn == bookType.rawValue)
                    .order(orderColumn.asc)
                    .fetchAll(db)
            }
            catch {
                print(error)
            }
        }
        
        return result
    }
    
    func fetchAllBookInfos(for bookType: BookType) throws -> [BookInfo] {
        var result: [BookInfo] = []
        
        try AppDatabase.shared.reader?.read{ db in
            do {
                let bookTypeColumn = Book.Columns.bookType
                let orderColumn = Book.Columns.order
                let books = try Book
                    .filter(bookTypeColumn == bookType.rawValue)
                    .order(orderColumn.asc)
                    .fetchAll(db)
                result = books.compactMap({ book in
                    if let bookID = book.id {
                        let dayRecordBookColumn = DayRecord.Columns.bookID
                        let dayRecordCount = try? DayRecord.filter(dayRecordBookColumn == bookID).fetchCount(db)
                        let tagBookColumn = Tag.Columns.bookID
                        let tagCount = try? Tag.filter(tagBookColumn == bookID).fetchCount(db)
                        return BookInfo(book: book, tagCount: tagCount ?? 0, dayRecordCount: dayRecordCount ?? 0)
                    } else {
                        return nil
                    }
                })
            }
            catch {
                print(error)
            }
        }
        
        return result
    }
    
    func update(book: Book) -> Bool {
        return AppDatabase.shared.update(book: book)
    }
    
    func update(books: [Book]) -> Bool {
        return AppDatabase.shared.update(books: books)
    }
    
    func add(book: Book) -> Bool {
        return AppDatabase.shared.add(book: book)
    }
    
    func delete(book: Book) -> Bool {
        return AppDatabase.shared.delete(book: book)
    }
}

// Tag
extension DataManager {
    func fetchTag(id: Int64) throws -> Tag? {
        var result: Tag?
        try AppDatabase.shared.reader?.read{ db in
            do {
                result = try Tag.fetchOne(db, id: id)
            }
            catch {
                print(error)
            }
        }
        
        return result
    }
    
    func fetchAllTags() throws -> [Tag] {
        var result: [Tag] = []
        try AppDatabase.shared.reader?.read{ db in
            do {
                result = try Tag.fetchAll(db)
            }
            catch {
                print(error)
            }
        }
        
        return result
    }
    
    func fetchTags(ids: [Int64]) throws -> [Tag] {
        var result: [Tag] = []
        try AppDatabase.shared.reader?.read{ db in
            do {
                result = try Tag.fetchAll(db, ids: ids)
            }
            catch {
                print(error)
            }
        }
        
        return result
    }
    
    func fetchAllTags(bookID: Int64) throws -> [Tag] {
        var result: [Tag] = []
        try AppDatabase.shared.reader?.read { db in
            do {
                let bookIDColumn = Tag.Columns.bookID
                let orderColumn = Tag.Columns.order
                result = try Tag
                    .filter(bookIDColumn == bookID)
                    .order(orderColumn.asc)
                    .fetchAll(db)
            }
            catch {
                print(error)
            }
        }
        
        return result
    }
    
    func update(tag: Tag) -> Bool {
        guard validate(tag: tag, shouldExist: true) else { return false }
        return AppDatabase.shared.update(tag: tag)
    }
    
    func update(tags: [Tag]) -> Bool {
        guard validate(tags: tags, shouldExist: true) else { return false }
        return AppDatabase.shared.update(tags: tags)
    }
    
    func add(tag: Tag) -> Bool {
        guard validate(tag: tag, shouldExist: false) else { return false }
        return AppDatabase.shared.add(tag: tag)
    }
    
    func delete(tag: Tag) -> Bool {
        return AppDatabase.shared.delete(tag: tag)
    }

    func move(tag: Tag, to book: Book) -> Bool {
        guard let tagID = tag.id, let bookID = book.id else { return false }
        guard tag.bookID != bookID else { return false }
        return AppDatabase.shared.move(tagID: tagID, toBookID: bookID)
    }

    func move(tag: Tag, toNewBook book: Book) -> Bool {
        guard let tagID = tag.id else { return false }
        guard book.id == nil else { return false }
        return AppDatabase.shared.move(tagID: tagID, toNewBook: book)
    }
}

// Day Records
extension DataManager {
    func fetchLastRecordOrder(bookID: Int64, day: Int64) -> Int64 {
        let lastOrder = (try? fetchAllDayRecords(bookID: bookID, day: day).last?.order) ?? 0
        
        return lastOrder
    }
    
    func fetchAllDayRecords(bookID: Int64) throws -> [DayRecord] {
        var result: [DayRecord] = []
        try AppDatabase.shared.reader?.read { db in
            do {
                let bookIDColumn = DayRecord.Columns.bookID
                let dayColumn = DayRecord.Columns.day
                let orderColumn = DayRecord.Columns.order
                result = try DayRecord
                    .filter(bookIDColumn == bookID)
                    .order(dayColumn.asc)
                    .order(orderColumn.asc)
                    .fetchAll(db)
            }
            catch {
                print(error)
            }
        }
        
        return result
    }
    
    func fetchAllDayRecords(after day: Int64) throws -> [DayRecord] {
        var result: [DayRecord] = []
        try AppDatabase.shared.reader?.read { db in
            do {
                let dayColumn = DayRecord.Columns.day
                let orderColumn = DayRecord.Columns.order
                result = try DayRecord
                    .filter(dayColumn >= day)
                    .order(orderColumn.asc)
                    .fetchAll(db)
            }
            catch {
                print(error)
            }
        }
        
        return result
    }
    
    func fetchAllDayRecords(at day: Int64) throws -> [DayRecord] {
        var result: [DayRecord] = []
        try AppDatabase.shared.reader?.read { db in
            do {
                let dayColumn = DayRecord.Columns.day
                let orderColumn = DayRecord.Columns.order
                result = try DayRecord
                    .filter(dayColumn == day)
                    .order(orderColumn.asc)
                    .fetchAll(db)
            }
            catch {
                print(error)
            }
        }
        
        return result
    }
    
    func fetchAllDayRecords(bookID: Int64, day: Int64) throws -> [DayRecord] {
        var result: [DayRecord] = []
        try AppDatabase.shared.reader?.read { db in
            do {
                let bookIDColumn = DayRecord.Columns.bookID
                let dayColumn = DayRecord.Columns.day
                let orderColumn = DayRecord.Columns.order
                result = try DayRecord
                    .filter(bookIDColumn == bookID)
                    .filter(dayColumn == day)
                    .order(orderColumn.asc)
                    .fetchAll(db)
            }
            catch {
                print(error)
            }
        }
        
        return result
    }
    
    func fetchAllDayRecords(recordIDs: [Int64]) throws -> [DayRecord] {
        var result: [DayRecord] = []
        try AppDatabase.shared.reader?.read { db in
            do {
                result = try DayRecord.fetchAll(db, ids: recordIDs)
            }
            catch {
                print(error)
            }
        }
        
        return result
    }
    
    func fetchAllDayRecords(tagID: Int64) throws -> [DayRecord] {
        var result: [DayRecord] = []
        try AppDatabase.shared.reader?.read { db in
            do {
                let tagIDColumn = DayRecord.Columns.tagID
                let dayColumn = DayRecord.Columns.day
                result = try DayRecord
                    .filter(tagIDColumn == tagID)
                    .order(dayColumn.asc)
                    .fetchAll(db)
            }
            catch {
                print(error)
            }
        }
        
        return result
    }
    
    func fetchAllDayRecords(tagID: Int64, from: Int64, to: Int64) throws -> [DayRecord] {
        var result: [DayRecord] = []
        try AppDatabase.shared.reader?.read { db in
            do {
                let tagIDColumn = DayRecord.Columns.tagID
                let dayColumn = DayRecord.Columns.day
                result = try DayRecord
                    .filter(tagIDColumn == tagID)
                    .filter(dayColumn <= to && dayColumn >= from)
                    .order(dayColumn.asc)
                    .fetchAll(db)
            }
            catch {
                print(error)
            }
        }
        
        return result
    }
    
    func update(dayRecord: DayRecord) -> Bool {
        guard validate(dayRecord: dayRecord, shouldExist: true) else { return false }
        return AppDatabase.shared.update(dayRecord: dayRecord)
    }
    
    func update(dayRecords: [DayRecord]) -> Bool {
        guard validate(dayRecords: dayRecords, shouldExist: true) else { return false }
        return AppDatabase.shared.update(dayRecords: dayRecords)
    }
    
    func add(dayRecord: DayRecord) -> DayRecord? {
        guard validate(dayRecord: dayRecord, shouldExist: false) else { return nil }
        return AppDatabase.shared.add(dayRecord: dayRecord)
    }
    
    func add(dayRecords: [DayRecord]) -> Bool {
        guard validate(dayRecords: dayRecords, shouldExist: false) else { return false }
        return AppDatabase.shared.add(dayRecords: dayRecords)
    }
    
    func delete(dayRecord: DayRecord) -> Bool {
        return AppDatabase.shared.delete(dayRecord: dayRecord)
    }
    
    func delete(dayRecords: [DayRecord]) -> Bool {
        return AppDatabase.shared.delete(dayRecords: dayRecords)
    }
    
    func replaceDayRecords(delete deleteRecords: [DayRecord], add addRecords: [DayRecord]) -> Bool {
        guard validate(dayRecords: addRecords, shouldExist: false) else { return false }
        return AppDatabase.shared.replaceDayRecords(delete: deleteRecords, add: addRecords)
    }

    func resetDayRecord(bookID: Int64, day: Int64) -> Bool {
        return AppDatabase.shared.resetDayRecord(bookID: bookID, day: day)
    }
    
    func add(dayRecord: WidgetAddDayRecord) -> DayRecord? {
        let bookID = dayRecord.bookID
        let tagID = dayRecord.tagID
        let day = dayRecord.day
        let lastOrder = fetchLastRecordOrder(bookID: Int64(bookID), day: Int64(day))
        let newRecord = DayRecord(bookID: Int64(bookID), tagID: Int64(tagID), day: Int64(day), startTime: Int64(dayRecord.date), order: lastOrder + 1)
        return add(dayRecord: newRecord)
    }
}

// Book Config
extension DataManager {
    func fetchAllBookConfigs() throws -> [BookConfig] {
        var result: [BookConfig] = []
        try AppDatabase.shared.reader?.read { db in
            do {
                result = try BookConfig
                    .fetchAll(db)
            }
            catch {
                print(error)
            }
        }
        
        return result
    }
    
    func fetchBookConfig(bookID: Int64) throws -> BookConfig? {
        var result: BookConfig? = nil
        try AppDatabase.shared.reader?.read { db in
            do {
                let bookIDColumn = BookConfig.Columns.bookID
                result = try BookConfig
                    .filter(bookIDColumn == bookID)
                    .fetchOne(db)
            }
            catch {
                print(error)
            }
        }
        return result
    }
    
    func add(bookConfig: BookConfig) -> Bool {
        guard validate(bookConfig: bookConfig, shouldExist: false) else { return false }
        return AppDatabase.shared.add(bookConfig: bookConfig)
    }
    
    func update(bookConfig: BookConfig) -> Bool {
        guard validate(bookConfig: bookConfig, shouldExist: true) else { return false }
        return AppDatabase.shared.update(bookConfig: bookConfig)
    }
}

extension DataManager {
    func syncSharedData() {
        do {
            try syncSharedDataToDatabase()
        }
        catch {
            print(error)
        }
        do {
            try syncDatabaseToSharedData()
        }
        catch {
            print(error)
        }
    }
    
    func syncSharedDataToDatabase() throws {
        // SharedData -> Database
        if let widgetAddDayRecords = try SharedDataManager.read(SharedData.self)?.widgetAddDayRecords, widgetAddDayRecords.count > 0 {
            widgetAddDayRecords.forEach{ _ = add(dayRecord: $0) }
        }
    }
    
    func syncDatabaseToSharedData() throws {
        // Database -> SharedData
        let books = try fetchAllBooks()
        let tags = try fetchAllTags()
        let dayRecords = try fetchAllDayRecords(after: Int64(ZCCalendar.manager.today.julianDay))
        let sharedData = SharedData(version: 1, books: books, tags: tags, dayRecord: dayRecords, widgetAddDayRecords: [])
        try SharedDataManager.write(sharedData)
    }
}
