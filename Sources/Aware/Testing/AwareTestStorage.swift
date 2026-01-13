//
//  AwareTestStorage.swift
//  Aware
//
//  Test result storage and reporting.
//

import Foundation
import os.log

// Test-target compatible logger
private let testLogger = Logger(subsystem: "com.aware.framework", category: "testing")

// MARK: - Test Run

/// A single test execution run with results
public struct TestRun: Codable, Identifiable {
    public let id: String
    public let projectId: String
    public let timestamp: Date
    public let llmModel: String?
    public let tokensUsed: Int
    public let testsTotal: Int
    public let testsPassed: Int
    public let testsFailed: Int
    public let durationMs: Int
    public let coveragePercent: Double
    public let results: [TestResult]

    public init(
        id: String = UUID().uuidString,
        projectId: String,
        timestamp: Date = Date(),
        llmModel: String? = nil,
        tokensUsed: Int = 0,
        testsTotal: Int = 0,
        testsPassed: Int = 0,
        testsFailed: Int = 0,
        durationMs: Int = 0,
        coveragePercent: Double = 0,
        results: [TestResult] = []
    ) {
        self.id = id
        self.projectId = projectId
        self.timestamp = timestamp
        self.llmModel = llmModel
        self.tokensUsed = tokensUsed
        self.testsTotal = testsTotal
        self.testsPassed = testsPassed
        self.testsFailed = testsFailed
        self.durationMs = durationMs
        self.coveragePercent = coveragePercent
        self.results = results
    }

    public var passRate: Double {
        guard testsTotal > 0 else { return 0 }
        return Double(testsPassed) / Double(testsTotal) * 100
    }

    public var failedTests: [TestResult] {
        results.filter { !$0.passed }
    }

    public func toMarkdown() -> String {
        var lines: [String] = []
        lines.append("# Test Run Report")
        lines.append("")
        lines.append("**Project:** \(projectId)")
        lines.append("**Date:** \(ISO8601DateFormatter().string(from: timestamp))")
        lines.append("**Duration:** \(durationMs)ms")
        if let model = llmModel {
            lines.append("**LLM Model:** \(model)")
            lines.append("**Tokens Used:** \(tokensUsed)")
        }
        lines.append("")
        lines.append("## Summary")
        lines.append("- **Tests:** \(testsPassed)/\(testsTotal) passed (\(String(format: "%.1f", passRate))%)")
        lines.append("- **Coverage:** \(String(format: "%.1f", coveragePercent))%")
        lines.append("")

        if !failedTests.isEmpty {
            lines.append("## Failed Tests")
            lines.append("")
            for test in failedTests {
                lines.append("### \(test.testName)")
                if let error = test.errorMessage {
                    lines.append("```")
                    lines.append(error)
                    lines.append("```")
                }
                lines.append("")
            }
        }

        return lines.joined(separator: "\n")
    }
}

// MARK: - Test Result

/// Result of a single test case
public struct TestResult: Codable, Identifiable {
    public let id: String
    public let runId: String
    public let testName: String
    public let passed: Bool
    public let durationMs: Int
    public let assertions: [AssertionResult]
    public let snapshotBefore: String?
    public let snapshotAfter: String?
    public let errorMessage: String?

    public init(
        id: String = UUID().uuidString,
        runId: String,
        testName: String,
        passed: Bool,
        durationMs: Int = 0,
        assertions: [AssertionResult] = [],
        snapshotBefore: String? = nil,
        snapshotAfter: String? = nil,
        errorMessage: String? = nil
    ) {
        self.id = id
        self.runId = runId
        self.testName = testName
        self.passed = passed
        self.durationMs = durationMs
        self.assertions = assertions
        self.snapshotBefore = snapshotBefore
        self.snapshotAfter = snapshotAfter
        self.errorMessage = errorMessage
    }
}

// MARK: - Assertion Result

/// Result of a single assertion
public struct AssertionResult: Codable {
    public let type: String
    public let passed: Bool
    public let expected: String?
    public let actual: String?
    public let message: String

    public init(
        type: String,
        passed: Bool,
        expected: String? = nil,
        actual: String? = nil,
        message: String
    ) {
        self.type = type
        self.passed = passed
        self.expected = expected
        self.actual = actual
        self.message = message
    }
}

// MARK: - Test Storage

/// Stores test results for persistence
public actor AwareTestStorage {

    public static let shared = AwareTestStorage()

    // In-memory cache
    private var cachedRuns: [TestRun] = []
    private var cachedBaselines: [String: StoredBaseline] = [:]

    public init() {}

    // MARK: - Test Runs

    /// Save a test run
    public func saveRun(_ run: TestRun) async throws {
        cachedRuns.append(run)
        testLogger.info("Saved test run: \(run.testsPassed)/\(run.testsTotal) passed")
    }

    /// Load recent test runs from cache
    public func loadHistory(days: Int = 7) -> [TestRun] {
        let cutoff = Date().addingTimeInterval(-Double(days * 24 * 60 * 60))
        return cachedRuns.filter { $0.timestamp >= cutoff }
            .sorted { $0.timestamp > $1.timestamp }
    }

    /// Get the most recent test run
    public func lastRun() -> TestRun? {
        cachedRuns.max { $0.timestamp < $1.timestamp }
    }

    /// Get runs with failures
    public func failedRuns(limit: Int = 10) -> [TestRun] {
        cachedRuns
            .filter { $0.testsFailed > 0 }
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - Baselines

    /// Save a baseline for regression testing
    public func saveBaseline(name: String, snapshotHash: Int, stateValues: [String: [String: String]], timestamp: Date = Date()) async throws {
        let stored = StoredBaseline(
            id: UUID().uuidString,
            projectId: "",
            name: name,
            snapshotHash: String(snapshotHash),
            stateValues: stateValues,
            createdAt: timestamp
        )
        cachedBaselines[name] = stored
        testLogger.info("Saved baseline: \(name)")
    }

    /// Load a baseline by name
    public func loadBaseline(named name: String) -> StoredBaseline? {
        return cachedBaselines[name]
    }

    /// List all baselines
    public func listBaselines() -> [String] {
        return Array(cachedBaselines.keys).sorted()
    }

    // MARK: - Coverage

    private var cachedCoverageReports: [StoredCoverageReport] = []

    /// Save a coverage report
    public func saveCoverage(projectId: String, coveragePercent: Double, coveredViews: [String], totalViews: Int) async throws {
        let report = StoredCoverageReport(
            id: UUID().uuidString,
            projectId: projectId,
            coveragePercent: coveragePercent,
            coveredViews: coveredViews,
            totalViews: totalViews,
            timestamp: Date()
        )
        cachedCoverageReports.append(report)
        testLogger.info("Saved coverage: \(String(format: "%.1f", coveragePercent))%")
    }

    /// Load coverage history
    public func loadCoverageHistory(limit: Int = 10) -> [StoredCoverageReport] {
        return cachedCoverageReports
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - Trends

    /// Calculate test trends over time
    public func trends() -> TestTrends {
        let runs = cachedRuns.sorted { $0.timestamp < $1.timestamp }
        guard !runs.isEmpty else {
            return TestTrends(
                totalRuns: 0,
                averagePassRate: 0,
                averageCoverage: 0,
                passRateTrend: .stable,
                coverageTrend: .stable
            )
        }

        let passRates = runs.map { $0.passRate }
        let coverages = runs.map { $0.coveragePercent }

        let avgPassRate = passRates.reduce(0, +) / Double(passRates.count)
        let avgCoverage = coverages.reduce(0, +) / Double(coverages.count)

        // Calculate trends (compare first half to second half)
        let midpoint = runs.count / 2
        let firstHalfPassRate = passRates.prefix(midpoint).reduce(0, +) / max(Double(midpoint), 1)
        let secondHalfPassRate = passRates.suffix(midpoint).reduce(0, +) / max(Double(midpoint), 1)

        let firstHalfCoverage = coverages.prefix(midpoint).reduce(0, +) / max(Double(midpoint), 1)
        let secondHalfCoverage = coverages.suffix(midpoint).reduce(0, +) / max(Double(midpoint), 1)

        let passRateTrend: Trend = secondHalfPassRate > firstHalfPassRate + 5 ? .improving :
                                   secondHalfPassRate < firstHalfPassRate - 5 ? .declining : .stable
        let coverageTrend: Trend = secondHalfCoverage > firstHalfCoverage + 5 ? .improving :
                                   secondHalfCoverage < firstHalfCoverage - 5 ? .declining : .stable

        return TestTrends(
            totalRuns: runs.count,
            averagePassRate: avgPassRate,
            averageCoverage: avgCoverage,
            passRateTrend: passRateTrend,
            coverageTrend: coverageTrend
        )
    }

    // MARK: - Clear

    /// Clear cached data
    public func clearCache() {
        cachedRuns.removeAll()
        cachedBaselines.removeAll()
        cachedCoverageReports.removeAll()
    }
}

// MARK: - Supporting Types

/// Stored baseline record
public struct StoredBaseline: Codable {
    public let id: String
    public let projectId: String
    public let name: String
    public let snapshotHash: String
    public let stateValues: [String: [String: String]]
    public let createdAt: Date
}

/// Test trends analysis
public struct TestTrends {
    public let totalRuns: Int
    public let averagePassRate: Double
    public let averageCoverage: Double
    public let passRateTrend: Trend
    public let coverageTrend: Trend
}

/// Trend direction
public enum Trend {
    case improving
    case stable
    case declining
}

/// Stored coverage report
public struct StoredCoverageReport: Codable {
    public let id: String
    public let projectId: String
    public let coveragePercent: Double
    public let coveredViews: [String]
    public let totalViews: Int
    public let timestamp: Date
}

// MARK: - Reporter

/// Generates test reports in various formats
public struct AwareTestReporter {

    /// Generate markdown report from test run
    public static func markdown(_ run: TestRun) -> String {
        run.toMarkdown()
    }

    /// Generate JUnit XML for CI/CD integration
    public static func junitXML(_ run: TestRun) -> String {
        var xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <testsuite name="AwareUITests" tests="\(run.testsTotal)" failures="\(run.testsFailed)" time="\(Double(run.durationMs) / 1000)">

        """

        for result in run.results {
            let durationSec = Double(result.durationMs) / 1000
            if result.passed {
                xml += """
                <testcase name="\(escapeXML(result.testName))" time="\(durationSec)"/>

                """
            } else {
                xml += """
                <testcase name="\(escapeXML(result.testName))" time="\(durationSec)">
                  <failure message="\(escapeXML(result.errorMessage ?? "Test failed"))">\(escapeXML(result.errorMessage ?? ""))</failure>
                </testcase>

                """
            }
        }

        xml += "</testsuite>"
        return xml
    }

    /// Generate JSON report
    public static func json(_ run: TestRun) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(run)
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    /// Generate Slack message
    public static func slack(_ run: TestRun) -> [String: Any] {
        let color = run.testsFailed == 0 ? "good" : "danger"
        let emoji = run.testsFailed == 0 ? ":white_check_mark:" : ":x:"

        return [
            "attachments": [
                [
                    "color": color,
                    "title": "\(emoji) Aware Test Results",
                    "fields": [
                        ["title": "Tests", "value": "\(run.testsPassed)/\(run.testsTotal) passed", "short": true],
                        ["title": "Coverage", "value": "\(String(format: "%.1f", run.coveragePercent))%", "short": true],
                        ["title": "Duration", "value": "\(run.durationMs)ms", "short": true],
                        ["title": "Project", "value": run.projectId, "short": true]
                    ],
                    "footer": "Aware UI Testing",
                    "ts": Int(run.timestamp.timeIntervalSince1970)
                ]
            ]
        ]
    }

    private static func escapeXML(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}
