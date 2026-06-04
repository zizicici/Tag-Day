//
//  SharedDataManager.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/6/30.
//

import Foundation

struct SharedDataManager {    
    private static let fileName = "shared_data.json"
    
    // 获取共享目录的 URL
    private static var sharedContainerURL: URL? {
        return FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppConfig.appGroupID
        )?.appendingPathComponent(fileName)
    }
    
    // MARK: - 写入数据
    static func write<T: Encodable>(_ data: T) throws {
        guard let fileURL = sharedContainerURL else {
            throw NSError(domain: "SharedDataError", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法访问共享目录"])
        }
        
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(data)
        
        let coordinator = NSFileCoordinator()
        var writeError: Error?
        
        coordinator.coordinate(writingItemAt: fileURL, options: .forReplacing, error: nil) { (url) in
            do {
                try jsonData.write(to: url, options: .atomic)
            } catch {
                writeError = error
            }
        }
        
        if let error = writeError {
            throw error
        }
    }
    
    // MARK: - 读取数据
    static func read<T: Decodable>(_ type: T.Type) throws -> T? {
        guard let fileURL = sharedContainerURL else {
            throw NSError(domain: "SharedDataError", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法访问共享目录"])
        }
        
        let coordinator = NSFileCoordinator()
        var readError: Error?
        var result: T?
        
        coordinator.coordinate(readingItemAt: fileURL, options: .withoutChanges, error: nil) { (url) in
            do {
                let data = try Data(contentsOf: url)
                result = try JSONDecoder().decode(type, from: data)
            } catch {
                readError = error
            }
        }
        
        if let error = readError {
            throw error
        }
        
        return result
    }

    @discardableResult
    static func mutateSharedData(_ transform: (inout SharedData) throws -> Void) throws -> SharedData {
        guard let fileURL = sharedContainerURL else {
            throw NSError(domain: "SharedDataError", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法访问共享目录"])
        }

        let coordinator = NSFileCoordinator()
        var coordinationError: NSError?
        var mutationError: Error?
        var result: SharedData?

        coordinator.coordinate(writingItemAt: fileURL, options: [], error: &coordinationError) { url in
            do {
                let data = try Data(contentsOf: url)
                let sharedData = try JSONDecoder().decode(SharedData.self, from: data)
                var mutatedData = sharedData
                try transform(&mutatedData)

                let jsonData = try JSONEncoder().encode(mutatedData)
                try jsonData.write(to: url, options: .atomic)
                result = mutatedData
            } catch {
                mutationError = error
            }
        }

        if let coordinationError {
            throw coordinationError
        }

        if let mutationError {
            throw mutationError
        }

        guard let result else {
            throw NSError(domain: "SharedDataError", code: -3, userInfo: [NSLocalizedDescriptionKey: "共享数据修改失败"])
        }

        return result
    }
}
