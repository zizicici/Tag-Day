//
//  RenderMetrics.swift
//  Tag Day
//
//  Created by Codex on 2026/2/13.
//

import Foundation
import QuartzCore

enum RenderMetrics {
#if DEBUG
    private struct Timing {
        var count: Int = 0
        var totalMilliseconds: Double = 0
        var minMilliseconds: Double = .greatestFiniteMagnitude
        var maxMilliseconds: Double = 0
    }
    
    private static let flushInterval: CFTimeInterval = 3.0
    private static let lock = NSLock()
    private static let printQueue = DispatchQueue(label: "com.zizicici.tag.render.metrics.print", qos: .utility)
    private static var counters: [String: Int] = [:]
    private static var timings: [String: Timing] = [:]
    private static var lastFlushTime: CFTimeInterval = CACurrentMediaTime()
    
    static let isEnabled: Bool = {
        if ProcessInfo.processInfo.arguments.contains("--render-metrics") {
            return true
        }
        if ProcessInfo.processInfo.environment["RENDER_METRICS"] == "1" {
            return true
        }
        if UserDefaults.standard.bool(forKey: "debug.render.metrics.enabled") {
            return true
        }
        return false
    }()
    
    static func begin() -> CFTimeInterval {
        guard isEnabled else { return 0 }
        return CACurrentMediaTime()
    }
    
    static func end(_ key: String, from start: CFTimeInterval) {
        guard isEnabled, start > 0 else { return }
        let durationMs = (CACurrentMediaTime() - start) * 1000
        observe(key, durationMs)
    }
    
    static func increment(_ key: String, by value: Int = 1) {
        guard isEnabled, value != 0 else { return }
        lock.lock()
        counters[key, default: 0] += value
        maybeFlushLocked()
        lock.unlock()
    }
    
    static func observe(_ key: String, _ milliseconds: Double) {
        guard isEnabled else { return }
        lock.lock()
        var timing = timings[key, default: Timing()]
        timing.count += 1
        timing.totalMilliseconds += milliseconds
        timing.minMilliseconds = min(timing.minMilliseconds, milliseconds)
        timing.maxMilliseconds = max(timing.maxMilliseconds, milliseconds)
        timings[key] = timing
        maybeFlushLocked()
        lock.unlock()
    }
    
    private static func maybeFlushLocked() {
        let now = CACurrentMediaTime()
        guard now - lastFlushTime >= flushInterval else { return }
        
        lastFlushTime = now
        let counterSnapshot = counters
        let timingSnapshot = timings
        counters.removeAll(keepingCapacity: true)
        timings.removeAll(keepingCapacity: true)
        
        guard !counterSnapshot.isEmpty || !timingSnapshot.isEmpty else { return }
        
        printQueue.async {
            print(formatSummary(counters: counterSnapshot, timings: timingSnapshot))
        }
    }
    
    private static func formatSummary(counters: [String: Int], timings: [String: Timing]) -> String {
        var lines: [String] = []
        lines.append("[RenderMetrics] interval=\(String(format: "%.1f", flushInterval))s")
        
        if !counters.isEmpty {
            lines.append("  counters:")
            for (key, value) in counters.sorted(by: { $0.key < $1.key }) {
                lines.append("    \(key)=\(value)")
            }
            
            let hitRates = calculateHitRates(counters: counters)
            if !hitRates.isEmpty {
                lines.append("  cache_hit_rate:")
                for line in hitRates {
                    lines.append("    \(line)")
                }
            }
        }
        
        if !timings.isEmpty {
            lines.append("  timings(ms):")
            for (key, timing) in timings.sorted(by: { $0.key < $1.key }) {
                guard timing.count > 0 else { continue }
                let avg = timing.totalMilliseconds / Double(timing.count)
                let minMs = timing.minMilliseconds.isFinite ? timing.minMilliseconds : 0
                lines.append("    \(key): count=\(timing.count), avg=\(String(format: "%.3f", avg)), min=\(String(format: "%.3f", minMs)), max=\(String(format: "%.3f", timing.maxMilliseconds))")
            }
        }
        
        return lines.joined(separator: "\n")
    }
    
    private static func calculateHitRates(counters: [String: Int]) -> [String] {
        var lines: [String] = []
        for (key, hitValue) in counters where key.hasSuffix(".hit") {
            let prefix = String(key.dropLast(4))
            let missKey = prefix + ".miss"
            guard let missValue = counters[missKey] else { continue }
            let total = hitValue + missValue
            guard total > 0 else { continue }
            let rate = Double(hitValue) / Double(total) * 100
            lines.append("\(prefix): \(String(format: "%.1f", rate))% (\(hitValue)/\(total))")
        }
        return lines.sorted()
    }
#else
    static let isEnabled: Bool = false
    
    static func begin() -> CFTimeInterval { 0 }
    static func end(_ key: String, from start: CFTimeInterval) {}
    static func increment(_ key: String, by value: Int = 1) {}
    static func observe(_ key: String, _ milliseconds: Double) {}
#endif
}
