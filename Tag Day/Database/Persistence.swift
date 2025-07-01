//
//  Persistence.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/4/29.
//

import Foundation
import GRDB

extension AppDatabase {
    static let shared = makeShared()
    
    private static func makeShared() -> AppDatabase {
        do {
            let databasePool = try generateDatabasePool()
            
            // Create the AppDatabase
            let database = try AppDatabase(databasePool)
            
            return database
        } catch {
            fatalError("Unresolved error \(error)")
        }
    }
    
    static func generateDatabasePool() throws -> DatabasePool {
        let folderURL = try databaseFolderURL()
        try FileManager().createDirectory(at: folderURL, withIntermediateDirectories: true)
        setProtectionForDirectory(at: folderURL)
        
        let dbURL = folderURL.appendingPathComponent("db.sqlite")
        var config = Configuration()
        config.automaticMemoryManagement = true
        let dbPool = try DatabasePool(path: dbURL.path, configuration: config)
        return dbPool
    }
    
    static func databaseFolderURL() throws -> URL {
        return try FileManager()
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("database", isDirectory: true)
    }
    
    static func setProtectionForDirectory(at url: URL) {
        let fileManager = FileManager.default
        
        do {
            // 获取目录下的所有文件和子目录
            let items = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])
            
            for item in items {
                // 设置保护属性为 none
                let attributes: [FileAttributeKey: Any] = [
                    FileAttributeKey.protectionKey: FileProtectionType.none
                ]
                
                // 更新文件或文件夹的属性
                try fileManager.setAttributes(attributes, ofItemAtPath: item.path)
                print("Set protection to none for: \(item.path)")
                
                // 如果是文件夹，递归调用
                if item.hasDirectoryPath {
                    setProtectionForDirectory(at: item)
                }
            }
        } catch {
            print("Error processing directory: \(error)")
        }
    }
}
