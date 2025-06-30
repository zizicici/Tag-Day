//
//  WidgetStateManager.swift
//  Tag Widget
//
//  Created by Ci Zi on 2025/6/30.
//

import Foundation
import WidgetKit

class WidgetStateManager {
    static let shared = WidgetStateManager()
    private let userDefaults: UserDefaults
    
    private init() {
        guard let defaults = UserDefaults(suiteName: WidgetStateKeys.groupContainer) else {
            fatalError("App Group配置错误，请检查groupContainer ID")
        }
        self.userDefaults = defaults
    }
    
    // 保存状态（包含kind和family）
    func saveState(kind: String, family: WidgetFamily, bookID: Int, state: WidgetState) {
        let stateInfo = WidgetStateInfo(
            kind: kind,
            family: family,
            bookID: bookID,
            state: state,
            lastUpdate: Date()
        )
        
        var allStates = loadAllStates()
        allStates[stateInfo.uniqueIdentifier] = stateInfo
        saveAllStates(allStates)
    }
    
    // 获取状态（考虑kind和family）
    func getState(kind: String, family: WidgetFamily, bookID: Int) -> WidgetState {
        let identifier = WidgetStateInfo.generateUID(kind: kind, family: family, bookID: bookID)
        var allStates = loadAllStates()
        
        guard let stateInfo = allStates[identifier] else {
            return .idle
        }
        
        // 检查是否超时（60秒）
        if case .showTags = stateInfo.state,
           Date().timeIntervalSince(stateInfo.lastUpdate) > 60 {
            
            // 自动恢复空闲状态
            let newInfo = WidgetStateInfo(
                kind: kind,
                family: family,
                bookID: bookID,
                state: .idle,
                lastUpdate: Date()
            )
            allStates[identifier] = newInfo
            saveAllStates(allStates)
            return .idle
        }
        
        return stateInfo.state
    }
    
    // 清理所有超时状态（可在App启动时调用）
    func cleanupExpiredStates() {
        var allStates = loadAllStates()
        let now = Date()
        
        allStates = allStates.filter { _, stateInfo in
            if case .showTags = stateInfo.state {
                return now.timeIntervalSince(stateInfo.lastUpdate) <= 60
            }
            return true
        }
        
        saveAllStates(allStates)
    }
    
    // 删除指定状态
    func removeState(kind: String, family: WidgetFamily, bookID: Int) {
        let identifier = WidgetStateInfo.generateUID(kind: kind, family: family, bookID: bookID)
        var allStates = loadAllStates()
        allStates.removeValue(forKey: identifier)
        saveAllStates(allStates)
    }
    
    // MARK: - Private Methods
    private func loadAllStates() -> [String: WidgetStateInfo] {
        guard let data = userDefaults.data(forKey: WidgetStateKeys.statesKey) else {
            return [:]
        }
        
        do {
            return try JSONDecoder().decode([String: WidgetStateInfo].self, from: data)
        } catch {
            print("状态解码失败: \(error)")
            return [:]
        }
    }
    
    private func saveAllStates(_ states: [String: WidgetStateInfo]) {
        do {
            let data = try JSONEncoder().encode(states)
            userDefaults.set(data, forKey: WidgetStateKeys.statesKey)
        } catch {
            print("状态保存失败: \(error)")
        }
    }
}
