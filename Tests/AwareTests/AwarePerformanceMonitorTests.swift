//
//  AwarePerformanceMonitorTests.swift
//  AwareTests
//
//  Comprehensive tests for AwarePerformanceMonitor and AwarePerformanceAsserter.
//  Tests Week 1 performance tracking and budget assertion features.
//

import XCTest
@testable import AwareCore

@MainActor
final class AwarePerformanceMonitorTests: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
        // Clear history before each test
        await AwarePerformanceMonitor.shared.clearHistory()
    }

    // MARK: - AwarePerformanceMonitor Tests

    /// Test measure() captures duration correctly
    func testMeasure_capturesDuration() async {
        let (result, metrics) = await AwarePerformanceMonitor.shared.measure(name: "test-operation") {
            // Simulate 100ms operation
            try? await Task.sleep(for: .milliseconds(100))
            return "success"
        }

        XCTAssertEqual(result, "success")
        XCTAssertEqual(metrics.name, "test-operation")
        XCTAssertGreaterThanOrEqual(metrics.duration, 0.09) // Allow 10ms tolerance
        XCTAssertLessThanOrEqual(metrics.duration, 0.15)
    }

    /// Test measure() handles errors correctly
    func testMeasure_handlesErrors() async {
        enum TestError: Error {
            case testFailure
        }

        do {
            let _ = try await AwarePerformanceMonitor.shared.measure(name: "failing-operation") {
                try await Task.sleep(for: .milliseconds(50))
                throw TestError.testFailure
            }
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error is TestError)
        }
    }

    /// Test measureSnapshot() records snapshot performance
    func testMeasureSnapshot() async {
        let metrics = await AwarePerformanceMonitor.shared.measureSnapshot(format: "compact")

        XCTAssertTrue(metrics.name.contains("snapshot"))
        XCTAssertTrue(metrics.name.contains("compact"))
        XCTAssertGreaterThan(metrics.duration, 0)
    }

    /// Test measureAction() records action performance
    func testMeasureAction() async {
        let metrics = await AwarePerformanceMonitor.shared.measureAction {
            try? await Task.sleep(for: .milliseconds(50))
        }

        XCTAssertEqual(metrics.name, "action")
        XCTAssertGreaterThanOrEqual(metrics.duration, 0.04)
        XCTAssertLessThanOrEqual(metrics.duration, 0.1)
    }

    /// Test history management adds entries
    func testHistory_addsEntries() async {
        // Add 3 measurements
        let _ = await AwarePerformanceMonitor.shared.measure(name: "op1") { }
        let _ = await AwarePerformanceMonitor.shared.measure(name: "op2") { }
        let _ = await AwarePerformanceMonitor.shared.measure(name: "op3") { }

        let history = await AwarePerformanceMonitor.shared.history(limit: 10)
        XCTAssertEqual(history.count, 3)

        // Verify order (newest first)
        XCTAssertEqual(history[0].name, "op3")
        XCTAssertEqual(history[1].name, "op2")
        XCTAssertEqual(history[2].name, "op1")
    }

    /// Test history is limited to 100 entries
    func testHistory_limitsTo100Entries() async {
        // Add 150 measurements
        for i in 1...150 {
            let _ = await AwarePerformanceMonitor.shared.measure(name: "op\(i)") { }
        }

        let allHistory = await AwarePerformanceMonitor.shared.history
        XCTAssertEqual(allHistory.count, 100)

        // Verify newest entries are kept (op150 should be first)
        XCTAssertEqual(allHistory.first?.name, "op150")
        XCTAssertEqual(allHistory.last?.name, "op51")
    }

    /// Test clearHistory removes all entries
    func testClearHistory() async {
        // Add some measurements
        let _ = await AwarePerformanceMonitor.shared.measure(name: "op1") { }
        let _ = await AwarePerformanceMonitor.shared.measure(name: "op2") { }

        var history = await AwarePerformanceMonitor.shared.history
        XCTAssertEqual(history.count, 2)

        // Clear history
        await AwarePerformanceMonitor.shared.clearHistory()

        history = await AwarePerformanceMonitor.shared.history
        XCTAssertEqual(history.count, 0)
    }

    /// Test statistics aggregation
    func testStatistics() async {
        // Add multiple measurements of same operation
        let _ = await AwarePerformanceMonitor.shared.measure(name: "query") {
            try? await Task.sleep(for: .milliseconds(10))
        }
        let _ = await AwarePerformanceMonitor.shared.measure(name: "query") {
            try? await Task.sleep(for: .milliseconds(20))
        }
        let _ = await AwarePerformanceMonitor.shared.measure(name: "query") {
            try? await Task.sleep(for: .milliseconds(30))
        }

        let stats = await AwarePerformanceMonitor.shared.statistics()

        guard let queryStats = stats["query"] else {
            XCTFail("Should have query statistics")
            return
        }

        XCTAssertEqual(queryStats.name, "query")
        XCTAssertEqual(queryStats.count, 3)
        XCTAssertGreaterThan(queryStats.min, 0)
        XCTAssertGreaterThan(queryStats.max, queryStats.min)
        XCTAssertGreaterThan(queryStats.average, 0)
        XCTAssertGreaterThan(queryStats.total, 0)
    }

    /// Test operation tracking start/end
    func testOperationTracking() async {
        let operationId = "test-op-123"

        // Start tracking
        await AwarePerformanceMonitor.shared.startTracking(operationId)

        // Simulate work
        try? await Task.sleep(for: .milliseconds(50))

        // End tracking
        let metrics = await AwarePerformanceMonitor.shared.endTracking(operationId)

        XCTAssertNotNil(metrics)
        XCTAssertEqual(metrics?.operationId, operationId)
        XCTAssertGreaterThanOrEqual(metrics?.duration ?? 0, 0.04)
        XCTAssertLessThanOrEqual(metrics?.duration ?? 0, 0.1)
    }

    /// Test getMetrics retrieves by operation ID
    func testGetMetrics() async {
        let (_, metrics) = await AwarePerformanceMonitor.shared.measure(name: "findable-op") { }

        let retrieved = await AwarePerformanceMonitor.shared.getMetrics(metrics.operationId)

        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.operationId, metrics.operationId)
        XCTAssertEqual(retrieved?.name, "findable-op")
    }

    /// Test getAllMetrics returns dictionary
    func testGetAllMetrics() async {
        let _ = await AwarePerformanceMonitor.shared.measure(name: "op1") { }
        let _ = await AwarePerformanceMonitor.shared.measure(name: "op2") { }

        let allMetrics = await AwarePerformanceMonitor.shared.getAllMetrics()

        XCTAssertEqual(allMetrics.count, 2)
    }

    // MARK: - AwarePerformanceAsserter Tests

    /// Test assertWithinBudget passes when within budget
    func testAssertWithinBudget_passes() async {
        // Create metrics for fast operation (50ms)
        let metrics = PerformanceMetrics(
            operationId: "test-id",
            name: "snapshot(compact)",
            startTime: Date(),
            endTime: Date().addingTimeInterval(0.05),
            duration: 0.05
        )

        let result = await AwarePerformanceAsserter.shared.assertWithinBudget(
            metrics,
            budget: .standard // 250ms budget for snapshots
        )

        XCTAssertTrue(result.passed)
        XCTAssertEqual(result.actualMs, 50)
        XCTAssertEqual(result.budgetMs, 250)
        XCTAssertNil(result.overrunMs)
        XCTAssertTrue(result.message.contains("✓"))
    }

    /// Test assertWithinBudget fails when exceeding budget
    func testAssertWithinBudget_fails() async {
        // Create metrics for slow operation (300ms)
        let metrics = PerformanceMetrics(
            operationId: "test-id",
            name: "snapshot(compact)",
            startTime: Date(),
            endTime: Date().addingTimeInterval(0.3),
            duration: 0.3
        )

        let result = await AwarePerformanceAsserter.shared.assertWithinBudget(
            metrics,
            budget: .standard // 250ms budget for snapshots
        )

        XCTAssertFalse(result.passed)
        XCTAssertEqual(result.actualMs, 300)
        XCTAssertEqual(result.budgetMs, 250)
        XCTAssertEqual(result.overrunMs, 50)
        XCTAssertTrue(result.message.contains("✗"))
    }

    /// Test budget selection for snapshot operations
    func testBudgetSelection_snapshot() async {
        let metrics = PerformanceMetrics(
            name: "snapshot(text)",
            startTime: Date(),
            endTime: Date().addingTimeInterval(0.1),
            duration: 0.1
        )

        let result = await AwarePerformanceAsserter.shared.assertWithinBudget(
            metrics,
            budget: .lenient
        )

        // Lenient snapshot budget is 500ms
        XCTAssertEqual(result.budgetMs, 500)
    }

    /// Test budget selection for action operations
    func testBudgetSelection_action() async {
        let metrics = PerformanceMetrics(
            name: "tap(button-id)",
            startTime: Date(),
            endTime: Date().addingTimeInterval(0.1),
            duration: 0.1
        )

        let result = await AwarePerformanceAsserter.shared.assertWithinBudget(
            metrics,
            budget: .standard
        )

        // Standard action budget is 150ms
        XCTAssertEqual(result.budgetMs, 150)
    }

    /// Test budget selection for query operations
    func testBudgetSelection_query() async {
        let metrics = PerformanceMetrics(
            name: "query(find-views)",
            startTime: Date(),
            endTime: Date().addingTimeInterval(0.01),
            duration: 0.01
        )

        let result = await AwarePerformanceAsserter.shared.assertWithinBudget(
            metrics,
            budget: .strict
        )

        // Strict query budget is 10ms
        XCTAssertEqual(result.budgetMs, 10)
    }

    /// Test predefined budget levels
    func testPredefinedBudgets() {
        // Lenient budget
        XCTAssertEqual(AwarePerformanceAsserter.lenient.snapshotMs, 500)
        XCTAssertEqual(AwarePerformanceAsserter.lenient.actionMs, 300)
        XCTAssertEqual(AwarePerformanceAsserter.lenient.queryMs, 50)

        // Standard budget
        XCTAssertEqual(AwarePerformanceAsserter.standard.snapshotMs, 250)
        XCTAssertEqual(AwarePerformanceAsserter.standard.actionMs, 150)
        XCTAssertEqual(AwarePerformanceAsserter.standard.queryMs, 20)

        // Strict budget
        XCTAssertEqual(AwarePerformanceAsserter.strict.snapshotMs, 100)
        XCTAssertEqual(AwarePerformanceAsserter.strict.actionMs, 50)
        XCTAssertEqual(AwarePerformanceAsserter.strict.queryMs, 10)
    }

    /// Test custom budget creation
    func testCustomBudget() {
        let custom = AwarePerformanceAsserter.customBudget(
            snapshotMs: 600,
            actionMs: 400,
            queryMs: 60,
            name: "custom-budget"
        )

        XCTAssertEqual(custom.snapshotMs, 600)
        XCTAssertEqual(custom.actionMs, 400)
        XCTAssertEqual(custom.queryMs, 60)
        XCTAssertEqual(custom.name, "custom-budget")
    }

    /// Test budget descriptions
    func testBudgetDescriptions() {
        let budget = AwarePerformanceAsserter.standard

        XCTAssertTrue(budget.description.contains("standard"))
        XCTAssertTrue(budget.description.contains("250ms"))
        XCTAssertTrue(budget.description.contains("150ms"))
        XCTAssertTrue(budget.description.contains("20ms"))

        XCTAssertTrue(budget.compactDescription.contains("standard"))
        XCTAssertTrue(budget.compactDescription.contains("250/150/20ms"))
    }

    /// Test assertion result descriptions
    func testAssertionResultDescriptions() {
        // Passing result
        let passResult = PerformanceAssertionResult(
            passed: true,
            actualMs: 100,
            budgetMs: 200,
            overrunMs: nil,
            message: "Test passed"
        )

        XCTAssertTrue(passResult.compactDescription.contains("✓"))
        XCTAssertTrue(passResult.compactDescription.contains("100ms"))
        XCTAssertTrue(passResult.compactDescription.contains("200ms"))

        // Failing result
        let failResult = PerformanceAssertionResult(
            passed: false,
            actualMs: 300,
            budgetMs: 200,
            overrunMs: 100,
            message: "Test failed"
        )

        XCTAssertTrue(failResult.compactDescription.contains("✗"))
        XCTAssertTrue(failResult.compactDescription.contains("300ms"))
        XCTAssertTrue(failResult.compactDescription.contains("200ms"))
        XCTAssertTrue(failResult.compactDescription.contains("+100ms"))

        // Detailed description
        XCTAssertTrue(failResult.detailedDescription.contains("FAIL"))
        XCTAssertTrue(failResult.detailedDescription.contains("Actual: 300ms"))
        XCTAssertTrue(failResult.detailedDescription.contains("Budget: 200ms"))
        XCTAssertTrue(failResult.detailedDescription.contains("Overrun: +100ms"))
    }

    /// Test assertSnapshotWithinBudget convenience method
    func testAssertSnapshotWithinBudget() async {
        let result = await AwarePerformanceAsserter.shared.assertSnapshotWithinBudget(
            format: "compact",
            budget: .lenient
        )

        // Should pass with lenient budget (500ms)
        XCTAssertTrue(result.passed)
        XCTAssertEqual(result.budgetMs, 500)
    }

    /// Test assertActionWithinBudget convenience method
    func testAssertActionWithinBudget() async {
        let result = await AwarePerformanceAsserter.shared.assertActionWithinBudget({
            try? await Task.sleep(for: .milliseconds(30))
        }, budget: .standard)

        // Should pass with standard budget (150ms)
        XCTAssertTrue(result.passed)
        XCTAssertLessThan(result.actualMs, 150)
    }

    /// Test assertQueryWithinBudget convenience method
    func testAssertQueryWithinBudget() async {
        let result = await AwarePerformanceAsserter.shared.assertQueryWithinBudget({
            // Very fast query
            _ = 1 + 1
        }, budget: .strict)

        // Should pass with strict budget (10ms)
        XCTAssertTrue(result.passed)
        XCTAssertLessThan(result.actualMs, 10)
    }

    /// Test assertBatchWithinBudget for multiple operations
    func testAssertBatchWithinBudget() async {
        let operations: [String: () async throws -> Void] = [
            "fast-op": {
                try? await Task.sleep(for: .milliseconds(10))
            },
            "medium-op": {
                try? await Task.sleep(for: .milliseconds(50))
            },
            "slow-op": {
                try? await Task.sleep(for: .milliseconds(200))
            }
        ]

        let results = await AwarePerformanceAsserter.shared.assertBatchWithinBudget(
            operations,
            budget: .standard
        )

        XCTAssertEqual(results.count, 3)
        XCTAssertTrue(results["fast-op"]?.passed == true)
        XCTAssertTrue(results["medium-op"]?.passed == true)
        // slow-op might pass or fail depending on system load
    }

    // MARK: - PerformanceMetrics Tests

    /// Test PerformanceMetrics description formatting
    func testPerformanceMetricsDescription() {
        let metrics = PerformanceMetrics(
            name: "test-op",
            startTime: Date(),
            endTime: Date().addingTimeInterval(0.123),
            duration: 0.123,
            memoryUsage: 1024 * 50, // 50KB
            cpuUsage: 45.7
        )

        XCTAssertTrue(metrics.description.contains("test-op"))
        XCTAssertTrue(metrics.description.contains("123ms"))
        XCTAssertTrue(metrics.description.contains("50KB"))
        XCTAssertTrue(metrics.description.contains("45.7% CPU"))

        // Compact description
        XCTAssertTrue(metrics.compactDescription.contains("test-op"))
        XCTAssertTrue(metrics.compactDescription.contains("123ms"))
    }

    /// Test PerformanceMetrics without optional fields
    func testPerformanceMetricsMinimal() {
        let metrics = PerformanceMetrics(
            name: "minimal-op",
            startTime: Date(),
            endTime: Date().addingTimeInterval(0.05),
            duration: 0.05
        )

        XCTAssertEqual(metrics.name, "minimal-op")
        XCTAssertEqual(metrics.duration, 0.05)
        XCTAssertNil(metrics.memoryUsage)
        XCTAssertNil(metrics.cpuUsage)
    }

    // MARK: - OperationStatistics Tests

    /// Test OperationStatistics description formatting
    func testOperationStatisticsDescription() {
        let stats = OperationStatistics(
            name: "test-operation",
            count: 10,
            min: 0.01,
            max: 0.15,
            average: 0.075,
            total: 0.75
        )

        XCTAssertTrue(stats.description.contains("test-operation"))
        XCTAssertTrue(stats.description.contains("avg 75ms"))
        XCTAssertTrue(stats.description.contains("min 10ms"))
        XCTAssertTrue(stats.description.contains("max 150ms"))
        XCTAssertTrue(stats.description.contains("n=10"))

        // Compact description
        XCTAssertTrue(stats.compactDescription.contains("test-operation"))
        XCTAssertTrue(stats.compactDescription.contains("avg 75ms"))
        XCTAssertTrue(stats.compactDescription.contains("n=10"))
    }

    // MARK: - Performance Overhead Tests

    /// Test that monitoring overhead is minimal (<5ms per measurement)
    func testMonitoringOverhead() async {
        let startTime = Date()

        // Measure a very fast operation
        let (_, metrics) = await AwarePerformanceMonitor.shared.measure(name: "overhead-test") {
            _ = 1 + 1 // Trivial operation
        }

        let totalDuration = Date().timeIntervalSince(startTime)

        // Overhead = total time - actual operation time
        let overhead = totalDuration - metrics.duration

        // Overhead should be less than 5ms
        XCTAssertLessThan(overhead, 0.005, "Monitoring overhead too high: \(overhead * 1000)ms")
    }

    /// Test performance with many concurrent measurements
    func testConcurrentMeasurements() async {
        let taskCount = 10

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<taskCount {
                group.addTask {
                    let _ = await AwarePerformanceMonitor.shared.measure(name: "concurrent-\(i)") {
                        try? await Task.sleep(for: .milliseconds(10))
                    }
                }
            }
        }

        let history = await AwarePerformanceMonitor.shared.history
        XCTAssertEqual(history.count, taskCount)
    }

    /// Test memory tracking (when available)
    func testMemoryTracking() async {
        let (_, metrics) = await AwarePerformanceMonitor.shared.measure(name: "memory-test") {
            // Allocate some memory
            var array = [Int]()
            for i in 0..<1000 {
                array.append(i)
            }
            return array.count
        }

        // Memory usage may or may not be available depending on platform
        #if os(macOS) || os(iOS)
        // On Apple platforms, memory tracking should be available
        XCTAssertNotNil(metrics.memoryUsage, "Memory tracking should be available on Apple platforms")
        #endif
    }
}
