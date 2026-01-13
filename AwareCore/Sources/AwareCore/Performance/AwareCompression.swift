//  AwareCompression.swift
//  Aware
//
//  Token compression and optimization for snapshot generation.
//  Reduces LLM token usage while maintaining readability.
//

import Foundation

/// Token compression strategies for different snapshot formats
public enum CompressionStrategy {
    /// No compression - full readability
    case none

    /// Basic compression - remove redundant whitespace and common patterns
    case basic

    /// Advanced compression - abbreviations and structural optimization
    case advanced

    /// Minimal compression - maximum token reduction for LLMs
    case minimal
}

/// Token compression engine
@MainActor
public final class AwareCompressionEngine {
    public static let shared = AwareCompressionEngine()

    private init() {}

    /// Compress snapshot content using specified strategy
    public func compress(
        content: String,
        format: AwareSnapshotFormat,
        strategy: CompressionStrategy = .basic
    ) -> String {
        switch strategy {
        case .none:
            return content
        case .basic:
            return applyBasicCompression(to: content, format: format)
        case .advanced:
            return applyAdvancedCompression(to: content, format: format)
        case .minimal:
            return applyMinimalCompression(to: content, format: format)
        }
    }

    /// Estimate token count for compressed content
    public func estimateTokens(for content: String, strategy: CompressionStrategy) -> Int {
        let compressed = compress(content: content, format: .compact, strategy: strategy)
        // Rough estimation: ~4 characters per token
        return compressed.count / 4
    }

    // MARK: - Compression Strategies

    private func applyBasicCompression(to content: String, format: AwareSnapshotFormat) -> String {
        var compressed = content

        // Remove excessive whitespace
        compressed = compressed.replacingOccurrences(of: #"\n\s*\n\s*\n"#, with: "\n\n", options: .regularExpression)
        compressed = compressed.replacingOccurrences(of: #"\s+\n"#, with: "\n", options: .regularExpression)

        // Shorten common patterns
        compressed = compressed.replacingOccurrences(of: "visible: true", with: "✓")
        compressed = compressed.replacingOccurrences(of: "visible: false", with: "✗")
        compressed = compressed.replacingOccurrences(of: "isEnabled: true", with: "enabled")
        compressed = compressed.replacingOccurrences(of: "isEnabled: false", with: "disabled")

        // Compact coordinates
        compressed = compressed.replacingOccurrences(of: #"frame: \(\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+)\s*\)"#,
                                                   with: "frame:($1,$2,$3,$4)",
                                                   options: .regularExpression)

        return compressed
    }

    private func applyAdvancedCompression(to content: String, format: AwareSnapshotFormat) -> String {
        var compressed = applyBasicCompression(to: content, format: format)

        // Use abbreviations
        let abbreviations = [
            "TextField": "TF",
            "SecureField": "SF",
            "Button": "Btn",
            "Toggle": "Tgl",
            "Slider": "Sldr",
            "Picker": "Pkr",
            "Navigation": "Nav",
            "Container": "Cnt",
            "backgroundColor": "bgColor",
            "foregroundColor": "fgColor",
            "fontSize": "fontSz"
        ]

        for (full, abbr) in abbreviations {
            compressed = compressed.replacingOccurrences(of: full, with: abbr)
        }

        // Compress structural elements
        compressed = compressed.replacingOccurrences(of: "├── ", with: "├─")
        compressed = compressed.replacingOccurrences(of: "└── ", with: "└─")
        compressed = compressed.replacingOccurrences(of: "│   ", with: "│ ")

        // Compress state objects
        compressed = compressed.replacingOccurrences(of: #"state: \{([^}]*)\}"#,
                                                   with: "state:{$1}",
                                                   options: .regularExpression)

        return compressed
    }

    private func applyMinimalCompression(to content: String, format: AwareSnapshotFormat) -> String {
        var compressed = applyAdvancedCompression(to: content, format: format)

        // Extreme compression for LLM consumption
        compressed = compressed.replacingOccurrences(of: "View", with: "V")
        compressed = compressed.replacingOccurrences(of: "Button", with: "B")
        compressed = compressed.replacingOccurrences(of: "Text", with: "T")
        compressed = compressed.replacingOccurrences(of: "Label", with: "L")

        // Remove all whitespace except single spaces between words
        compressed = compressed.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        compressed = compressed.trimmingCharacters(in: .whitespacesAndNewlines)

        // Use single-character separators
        compressed = compressed.replacingOccurrences(of: ": ", with: ":")
        compressed = compressed.replacingOccurrences(of: ", ", with: ",")

        return compressed
    }
}

/// Caching system for expensive operations
@MainActor
public final class AwareCache {
    public static let shared = AwareCache()

    private var snapshotCache: [String: (content: String, timestamp: Date)] = [:]
    private var queryCache: [String: (result: [AwareViewSnapshot], timestamp: Date)] = [:]
    private let cacheTimeout: TimeInterval = 1.0 // 1 second

    private init() {}

    /// Cache snapshot result
    public func cacheSnapshot(_ key: String, content: String) {
        snapshotCache[key] = (content: content, timestamp: Date())
    }

    /// Get cached snapshot if still valid
    public func getCachedSnapshot(_ key: String) -> String? {
        guard let cached = snapshotCache[key] else { return nil }
        guard Date().timeIntervalSince(cached.timestamp) < cacheTimeout else {
            snapshotCache.removeValue(forKey: key)
            return nil
        }
        return cached.content
    }

    /// Cache query result
    public func cacheQuery(_ key: String, result: [AwareViewSnapshot]) {
        queryCache[key] = (result: result, timestamp: Date())
    }

    /// Get cached query result if still valid
    public func getCachedQuery(_ key: String) -> [AwareViewSnapshot]? {
        guard let cached = queryCache[key] else { return nil }
        guard Date().timeIntervalSince(cached.timestamp) < cacheTimeout else {
            queryCache.removeValue(forKey: key)
            return nil
        }
        return cached.result
    }

    /// Clear all caches
    public func clear() {
        snapshotCache.removeAll()
        queryCache.removeAll()
    }

    /// Get cache statistics
    public func statistics() -> (snapshots: Int, queries: Int, totalSize: Int) {
        let snapshotSize = snapshotCache.values.reduce(0) { $0 + $1.content.count }
        let querySize = queryCache.values.reduce(0) { $0 + $1.result.count * 100 } // Rough estimate
        return (snapshots: snapshotCache.count, queries: queryCache.count, totalSize: snapshotSize + querySize)
    }
}

/// Memory pool for frequently allocated objects
@MainActor
public final class AwareMemoryPool {
    public static let shared = AwareMemoryPool()

    private var snapshotPool: [AwareViewSnapshot] = []
    private var maxPoolSize = 50

    private init() {}

    /// Get a recycled snapshot or create new one
    public func getSnapshot(id: String, label: String?, isContainer: Bool = false, parentId: String? = nil) -> AwareViewSnapshot {
        if let recycled = snapshotPool.popLast() {
            // Reuse existing instance
            return AwareViewSnapshot(
                id: id,
                label: label,
                isContainer: isContainer,
                isVisible: true,
                frame: recycled.frame,
                visual: recycled.visual,
                parentId: parentId,
                childIds: [],
                animation: recycled.animation,
                action: recycled.action,
                behavior: recycled.behavior
            )
        } else {
            return AwareViewSnapshot(
                id: id,
                label: label,
                isContainer: isContainer,
                parentId: parentId
            )
        }
    }

    /// Return snapshot to pool for reuse
    public func returnSnapshot(_ snapshot: AwareViewSnapshot) {
        if snapshotPool.count < maxPoolSize {
            snapshotPool.append(snapshot)
        }
    }

    /// Clear the memory pool
    public func clear() {
        snapshotPool.removeAll()
    }

    /// Get pool statistics
    public func statistics() -> (size: Int, maxSize: Int) {
        return (size: snapshotPool.count, maxSize: maxPoolSize)
    }
}