//
//  AppDatabase+Backup.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/6/19.
//

import Foundation
import GRDB
import ZipArchive

private struct DatabaseReplacementResult {
    let imported: Bool
    let backupURL: URL?
}

extension AppDatabase {
    // Backup
    func backupToTempPath() -> String? {
        guard let dbWriter = dbWriter else { return nil }
        
        // Build a temporary path
        let fileName = "db.sqlite"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let time = dateFormatter.string(from: Date())
        let subdirectoryName = "\(time)/database"
        let tempDirPath = NSTemporaryDirectory()
        let directoryPath = (tempDirPath as NSString).appendingPathComponent(subdirectoryName)
        do {
            try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print(error)
        }
        
        let filePath = (directoryPath as NSString).appendingPathComponent(fileName)

        // Export
        do {
            try dbWriter.backup(to: DatabasePool(path: filePath))
        }
        catch {
            print(error)
            return nil
        }
        
        // Zip
        let targetPath = (tempDirPath as NSString).appendingPathComponent(time)
        let zipFile = (tempDirPath as NSString).appendingPathComponent("\(time).zip")
        SSZipArchive.createZipFile(atPath: zipFile, withContentsOfDirectory: targetPath)
        
        do {
            try FileManager.default.removeItem(atPath: targetPath)
        }
        catch {
            print(error)
        }
        
        return zipFile
    }
    
    public func importDatabase(_ fileURL: URL) {
        do {
            try copyFileToTempImportDirectory(fileURL)
            guard try findDatabaseFileInImportDirectory() else {
                return
            }
            
            let importedDatabaseURL = try findSingleSQLiteFileInImportDirectory()
            try validateImportedDatabase(at: importedDatabaseURL)
            
            let destinationURL = try AppDatabase.databaseFolderURL()
            disconnect()
            do {
                let replacement = try replaceDatabase(with: importedDatabaseURL, destinationURL: destinationURL)
                guard reconnect() else {
                    try restoreDatabaseBackup(at: replacement.backupURL, destinationURL: destinationURL)
                    guard reconnect() else {
                        throw NSError(
                            domain: "DatabaseImportError",
                            code: -3,
                            userInfo: [NSLocalizedDescriptionKey: "Imported database could not be opened, and the previous database could not be restored."]
                        )
                    }
                    throw NSError(
                        domain: "DatabaseImportError",
                        code: -2,
                        userInfo: [NSLocalizedDescriptionKey: "Imported database could not be opened. The previous database has been restored."]
                    )
                }
                
                if let backupURL = replacement.backupURL {
                    try? FileManager.default.removeItem(at: backupURL)
                }
                
                if replacement.imported {
                    NotificationCenter.default.post(name: Notification.Name.DatabaseUpdated, object: nil)
                }
            } catch {
                if dbWriter == nil {
                    _ = reconnect()
                }
                throw error
            }
        } catch {
            print(error)
        }
    }
    
    @discardableResult
    func copyFileToTempImportDirectory(_ fileURL: URL) throws -> URL {
        let fileManager = FileManager.default
        
        // 创建 temp/import 目录的路径
        var importURL = URL(fileURLWithPath: NSTemporaryDirectory())
        importURL.appendPathComponent("import", isDirectory: true)
        
        // 删除现有的 import 目录及其内容
        if fileManager.fileExists(atPath: importURL.path) {
            try fileManager.removeItem(at: importURL)
        }
        
        // 创建 import 目录
        try fileManager.createDirectory(at: importURL, withIntermediateDirectories: true, attributes: nil)
        
        // 将文件复制到 import 目录
        let destinationURL = importURL.appendingPathComponent(fileURL.lastPathComponent)
        try fileManager.copyItem(at: fileURL, to: destinationURL)
        
        return destinationURL
    }
    
    func findDatabaseFileInImportDirectory() throws -> Bool {
        let fileManager = FileManager.default
        
        var findDatabase = false
        
        // 1. 获取 temp/import 目录
        var rootURL = URL(fileURLWithPath: NSTemporaryDirectory())
        rootURL.appendPathComponent("import", isDirectory: true)
        
        // 2. 检查 import 目录是否存在
        guard fileManager.fileExists(atPath: rootURL.path) else {
            return findDatabase
        }
        
        let unzipURL = rootURL.appendingPathComponent("unzip", isDirectory: true)
        
        // 如果之前解压过就删除 unzip 文件夹和 zip 文件
        if fileManager.fileExists(atPath: unzipURL.path) {
            try fileManager.removeItem(at: unzipURL)
        }
        
        // 3. 查找并遍历二级目录中的所有 zip 文件
        let unfilteredContents = try fileManager.contentsOfDirectory(at: rootURL, includingPropertiesForKeys: nil)
        
        for itemURL in unfilteredContents {
            if itemURL.pathExtension == "zip",
               let archivePath = itemURL.path.removingPercentEncoding {
                
                // 4. 解压缩 zip 文件内容到 unzip 目录
                let success = SSZipArchive.unzipFile(
                    atPath: archivePath,
                    toDestination: unzipURL.path,
                    overwrite: true,
                    password: nil,
                    progressHandler: nil,
                    completionHandler: nil
                )
                
                guard success else { return findDatabase }
                
                // 5. 遍历 unzip 目录中的所有文件夹和文件，将 .sqlite 文件移动到 temp 目录
                if try findAndMoveSQLiteFiles(in: unzipURL) {
                    findDatabase = true
                }
                
                // 6. 删除解压目录和 zip 文件
                try fileManager.removeItem(at: itemURL)
                try fileManager.removeItem(atPath: unzipURL.path)
            } else {
                if itemURL.pathExtension == "sqlite" {
                    findDatabase = true
                }
            }
        }
        
        return findDatabase
    }

    func findAndMoveSQLiteFiles(in directoryURL: URL) throws -> Bool {
        var findDatabase = false

        let fileManager = FileManager.default
        
        // 获取目录下的所有项目，包括子文件夹
        let contents = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
        
        for itemURL in contents {
            var isDirectory: ObjCBool = false
            
            // 如果是文件夹，则递归查找子文件夹
            if fileManager.fileExists(atPath: itemURL.path, isDirectory: &isDirectory), isDirectory.boolValue {
                if try findAndMoveSQLiteFiles(in: itemURL) {
                    findDatabase = true
                }
            } else if itemURL.pathExtension == "sqlite" {
                // 如果是 .sqlite 文件，则将其移动到 temp/import 目录
                let newLocationURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("import", isDirectory: true).appendingPathComponent(itemURL.lastPathComponent)
                
                try fileManager.moveItem(at: itemURL, to: newLocationURL)
                findDatabase = true
            }
        }
        
        return findDatabase
    }
    
    func findSingleSQLiteFileInImportDirectory() throws -> URL {
        let sourceURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("import", isDirectory: true)
        let contents = try FileManager.default.contentsOfDirectory(at: sourceURL, includingPropertiesForKeys: nil)
        let sqliteFiles = contents.filter { $0.pathExtension == "sqlite" }
        
        guard sqliteFiles.count == 1, let sqliteFile = sqliteFiles.first else {
            throw NSError(
                domain: "DatabaseImportError",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Expected exactly one sqlite database file, found \(sqliteFiles.count)."]
            )
        }
        
        return sqliteFile
    }
    
    func validateImportedDatabase(at databaseURL: URL) throws {
        let pool = try DatabasePool(path: databaseURL.path)
        defer {
            try? pool.close()
        }
        try pool.read { db in
            _ = try Book
                .select(Book.Columns.id, Book.Columns.title, Book.Columns.color, Book.Columns.symbol, Book.Columns.bookType, Book.Columns.order)
                .limit(0)
                .fetchAll(db)
            _ = try Tag
                .select(Tag.Columns.id, Tag.Columns.bookID, Tag.Columns.title, Tag.Columns.subtitle, Tag.Columns.color, Column(Tag.CodingKeys.titleColor), Tag.Columns.order)
                .limit(0)
                .fetchAll(db)
            _ = try DayRecord
                .select(DayRecord.Columns.id, DayRecord.Columns.bookID, DayRecord.Columns.tagID, DayRecord.Columns.day, DayRecord.Columns.comment, DayRecord.Columns.startTime, DayRecord.Columns.endTime, DayRecord.Columns.duration, DayRecord.Columns.order)
                .limit(0)
                .fetchAll(db)
            _ = try BookConfig
                .select(BookConfig.Columns.id, BookConfig.Columns.bookID, Column(BookConfig.CodingKeys.notificationTime), Column(BookConfig.CodingKeys.notificationText), Column(BookConfig.CodingKeys.repeatWeekday))
                .limit(0)
                .fetchAll(db)
        }
    }
    
    private func replaceDatabase(with importedDatabaseURL: URL, destinationURL: URL) throws -> DatabaseReplacementResult {
        let fileManager = FileManager.default
        let parentURL = destinationURL.deletingLastPathComponent()
        let stagingURL = parentURL.appendingPathComponent("database_import_\(UUID().uuidString)", isDirectory: true)
        let backupURL = parentURL.appendingPathComponent("database_backup_\(UUID().uuidString)", isDirectory: true)
        let stagedDatabaseURL = stagingURL.appendingPathComponent(AppDatabase.dbName)
        var didMoveOriginal = false
        
        try fileManager.createDirectory(at: parentURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: stagingURL, withIntermediateDirectories: true)
        try backupDatabase(from: importedDatabaseURL, to: stagedDatabaseURL)
        
        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.moveItem(at: destinationURL, to: backupURL)
                didMoveOriginal = true
            }
            
            try fileManager.moveItem(at: stagingURL, to: destinationURL)
            AppDatabase.setProtectionForDirectory(at: destinationURL)
            
            return DatabaseReplacementResult(imported: true, backupURL: didMoveOriginal ? backupURL : nil)
        } catch {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try? fileManager.removeItem(at: destinationURL)
            }
            if didMoveOriginal, fileManager.fileExists(atPath: backupURL.path) {
                try? fileManager.moveItem(at: backupURL, to: destinationURL)
            }
            try? fileManager.removeItem(at: stagingURL)
            throw error
        }
    }
    
    private func restoreDatabaseBackup(at backupURL: URL?, destinationURL: URL) throws {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        if let backupURL, fileManager.fileExists(atPath: backupURL.path) {
            try fileManager.moveItem(at: backupURL, to: destinationURL)
            AppDatabase.setProtectionForDirectory(at: destinationURL)
        }
    }
    
    private func backupDatabase(from sourceURL: URL, to destinationURL: URL) throws {
        let sourcePool = try DatabasePool(path: sourceURL.path)
        defer {
            try? sourcePool.close()
        }
        
        let destinationPool = try DatabasePool(path: destinationURL.path)
        defer {
            try? destinationPool.close()
        }
        
        try sourcePool.backup(to: destinationPool)
    }
}
