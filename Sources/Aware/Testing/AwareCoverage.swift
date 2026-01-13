//
//  AwareCoverage.swift
//  Aware
//
//  Coverage tracking for Aware-instrumented views.
//

import Foundation

// MARK: - Coverage Level

/// Indicates how thoroughly a view has been tested
public enum CoverageLevel: String, Codable {
    case none = "none"           // Never visited
    case low = "low"             // Visited 1-2 times
    case medium = "medium"       // Visited 3-5 times
    case high = "high"           // Visited 6+ times
}

// MARK: - Coverage Report

/// Report of test coverage for a project
public struct CoverageReport: Codable {
    public let projectId: String
    public let timestamp: Date
    public let totalInstrumented: Int
    public let totalVisited: Int
    public let coveragePercent: Double
    public let viewCoverage: [String: ViewCoverage]
    public let actionCoverage: [String: Int]

    public init(
        projectId: String,
        timestamp: Date,
        totalInstrumented: Int,
        totalVisited: Int,
        coveragePercent: Double,
        viewCoverage: [String: ViewCoverage],
        actionCoverage: [String: Int]
    ) {
        self.projectId = projectId
        self.timestamp = timestamp
        self.totalInstrumented = totalInstrumented
        self.totalVisited = totalVisited
        self.coveragePercent = coveragePercent
        self.viewCoverage = viewCoverage
        self.actionCoverage = actionCoverage
    }

    /// Generate markdown report
    public func toMarkdown() -> String {
        var lines: [String] = []
        lines.append("# Aware Coverage Report")
        lines.append("")
        lines.append("**Project:** \(projectId)")
        lines.append("**Date:** \(ISO8601DateFormatter().string(from: timestamp))")
        lines.append("")
        lines.append("## Summary")
        lines.append("- Total Instrumented Views: \(totalInstrumented)")
        lines.append("- Views Visited: \(totalVisited)")
        lines.append("- Coverage: \(String(format: "%.1f", coveragePercent))%")
        lines.append("")
        lines.append("## View Coverage")
        lines.append("")
        lines.append("| View ID | Visits | Level |")
        lines.append("|---------|--------|-------|")

        for (viewId, coverage) in viewCoverage.sorted(by: { $0.value.visitCount > $1.value.visitCount }) {
            lines.append("| \(viewId) | \(coverage.visitCount) | \(coverage.level.rawValue) |")
        }

        if !actionCoverage.isEmpty {
            lines.append("")
            lines.append("## Action Coverage")
            lines.append("")
            lines.append("| Action | Times Triggered |")
            lines.append("|--------|-----------------|")
            for (action, count) in actionCoverage.sorted(by: { $0.value > $1.value }) {
                lines.append("| \(action) | \(count) |")
            }
        }

        return lines.joined(separator: "\n")
    }

    /// Generate JSON report
    public func toJSON() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(self)
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}

// MARK: - View Coverage

/// Coverage data for a single view
public struct ViewCoverage: Codable {
    public let viewId: String
    public var visitCount: Int
    public var lastVisited: Date?
    public var actionsTaken: [String]
    public var statesObserved: Set<String>

    public var level: CoverageLevel {
        switch visitCount {
        case 0: return .none
        case 1...2: return .low
        case 3...5: return .medium
        default: return .high
        }
    }

    public init(viewId: String) {
        self.viewId = viewId
        self.visitCount = 0
        self.lastVisited = nil
        self.actionsTaken = []
        self.statesObserved = []
    }
}

// MARK: - Aware Coverage Tracker

/// Tracks test coverage for Aware-instrumented views
public class AwareCoverage {
    public static let shared = AwareCoverage()

    private var projectId: String = ""
    private var viewCoverage: [String: ViewCoverage] = [:]
    private var actionCoverage: [String: Int] = [:]
    private var stateTransitions: [(from: String, to: String, viewId: String)] = []

    private let queue = DispatchQueue(label: "com.aware.framework.coverage")

    public init() {}

    // MARK: - Configuration

    /// Set the current project for isolation
    public func setProject(_ projectId: String) {
        queue.sync {
            self.projectId = projectId
        }
    }

    // MARK: - Tracking

    /// Record that a view was visited/rendered
    public func trackVisit(_ viewId: String) {
        queue.sync {
            if viewCoverage[viewId] == nil {
                viewCoverage[viewId] = ViewCoverage(viewId: viewId)
            }
            viewCoverage[viewId]?.visitCount += 1
            viewCoverage[viewId]?.lastVisited = Date()
        }
    }

    /// Record that an action was taken on a view
    public func trackAction(_ viewId: String, action: String) {
        queue.sync {
            if viewCoverage[viewId] == nil {
                viewCoverage[viewId] = ViewCoverage(viewId: viewId)
            }
            viewCoverage[viewId]?.actionsTaken.append(action)

            let actionKey = "\(viewId):\(action)"
            actionCoverage[actionKey, default: 0] += 1
        }
    }

    /// Record a state observation
    public func trackState(_ viewId: String, key: String, value: String) {
        queue.sync {
            if viewCoverage[viewId] == nil {
                viewCoverage[viewId] = ViewCoverage(viewId: viewId)
            }
            viewCoverage[viewId]?.statesObserved.insert("\(key)=\(value)")
        }
    }

    /// Record a state transition
    public func trackTransition(from: String, to: String, viewId: String) {
        queue.sync {
            stateTransitions.append((from: from, to: to, viewId: viewId))
        }
    }

    // MARK: - Reporting

    /// Get coverage percentage
    @MainActor
    public var coveragePercent: Double {
        let total = Aware.shared.registeredViewIds.count
        guard total > 0 else { return 0.0 }
        let visited = queue.sync { viewCoverage.values.filter { $0.visitCount > 0 }.count }
        return Double(visited) / Double(total) * 100.0
    }

    /// Get visited view IDs
    public var visitedViews: Set<String> {
        queue.sync {
            Set(viewCoverage.keys)
        }
    }

    /// Get unvisited view IDs
    @MainActor
    public var unvisitedViews: Set<String> {
        let allViews = Set(Aware.shared.registeredViewIds)
        let visited = queue.sync { Set(viewCoverage.keys.filter { viewCoverage[$0]?.visitCount ?? 0 > 0 }) }
        return allViews.subtracting(visited)
    }

    /// Generate coverage heatmap
    @MainActor
    public func heatmap() -> [String: CoverageLevel] {
        var result: [String: CoverageLevel] = [:]

        // Mark all registered views as none initially
        for viewId in Aware.shared.registeredViewIds {
            result[viewId] = CoverageLevel.none
        }

        // Update with actual coverage levels
        queue.sync {
            for (viewId, coverage) in viewCoverage {
                result[viewId] = coverage.level
            }
        }

        return result
    }

    /// Generate full coverage report
    @MainActor
    public func report() -> CoverageReport {
        let allViews = Aware.shared.registeredViewIds
        let (visited, viewCoverageCopy, actionCoverageCopy) = queue.sync {
            (viewCoverage.values.filter { $0.visitCount > 0 }.count, viewCoverage, actionCoverage)
        }

        return CoverageReport(
            projectId: projectId,
            timestamp: Date(),
            totalInstrumented: allViews.count,
            totalVisited: visited,
            coveragePercent: allViews.isEmpty ? 0 : Double(visited) / Double(allViews.count) * 100.0,
            viewCoverage: viewCoverageCopy,
            actionCoverage: actionCoverageCopy
        )
    }

    // MARK: - Reset

    /// Reset coverage data
    public func reset() {
        queue.sync {
            viewCoverage.removeAll()
            actionCoverage.removeAll()
            stateTransitions.removeAll()
        }
    }

    /// Reset coverage for a specific project
    public func reset(projectId: String) {
        queue.sync {
            if self.projectId == projectId {
                viewCoverage.removeAll()
                actionCoverage.removeAll()
                stateTransitions.removeAll()
            }
        }
    }
}
