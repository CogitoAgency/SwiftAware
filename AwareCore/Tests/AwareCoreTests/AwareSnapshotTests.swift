//
//  AwareSnapshotTests.swift
//  Aware
//
//  Tests for snapshot rendering in various formats.
//

import XCTest
@testable import Aware

final class AwareSnapshotTests: XCTestCase {

    // MARK: - Setup & Teardown

    private var testViewIds: [String] = []

    override func tearDown() async throws {
        // Clean up test views
        await MainActor.run {
            for id in testViewIds {
                Aware.shared.unregisterView(id)
            }
        }
        testViewIds.removeAll()
        try await super.tearDown()
    }

    private func makeTestId(_ suffix: String) -> String {
        let id = "snapshot-test-\(suffix)-\(UUID().uuidString)"
        testViewIds.append(id)
        return id
    }

    // MARK: - Format Tests

    @MainActor
    func testCompactFormatShorterThanJSON() async throws {
        // Given: Create multiple views to have substantial content
        let viewId1 = makeTestId("compact-1")
        let viewId2 = makeTestId("compact-2")
        Aware.shared.registerView(viewId1, label: "Button One")
        Aware.shared.registerView(viewId2, label: "Button Two")
        Aware.shared.registerState(viewId1, key: "enabled", value: "true")
        Aware.shared.registerState(viewId2, key: "enabled", value: "false")

        // When
        let compact = Aware.shared.captureSnapshot(format: .compact)
        let json = Aware.shared.captureSnapshot(format: .json)

        // Then: Compact should be more token-efficient
        XCTAssertLessThan(compact.content.count, json.content.count,
                         "Compact format should use fewer characters than JSON")
        XCTAssertEqual(compact.format, "compact")
    }

    @MainActor
    func testJSONFormatIsValidJSON() async throws {
        // Given
        let viewId = makeTestId("json")
        Aware.shared.registerView(viewId, label: "JSON Test")
        Aware.shared.registerState(viewId, key: "count", value: "42")

        // When
        let json = Aware.shared.captureSnapshot(format: .json)

        // Then: Should be valid JSON
        XCTAssertEqual(json.format, "json")
        let data = json.content.data(using: .utf8)!
        XCTAssertNoThrow(try JSONSerialization.jsonObject(with: data))
    }

    @MainActor
    func testTextFormatContainsLabel() async throws {
        // Given
        let uniqueLabel = "Unique Label \(UUID().uuidString)"
        let viewId = makeTestId("text")
        Aware.shared.registerView(viewId, label: uniqueLabel)

        // When
        let text = Aware.shared.captureSnapshot(format: .text)

        // Then
        XCTAssertEqual(text.format, "text")
        XCTAssertTrue(text.content.contains(uniqueLabel),
                     "Text format should contain the view label")
    }

    @MainActor
    func testTextFormatContainsViewId() async throws {
        // Given
        let viewId = makeTestId("viewid")
        Aware.shared.registerView(viewId, label: "ViewID Test")

        // When
        let text = Aware.shared.captureSnapshot(format: .text)

        // Then
        XCTAssertTrue(text.content.contains(viewId),
                     "Text format should contain the view ID")
    }

    @MainActor
    func testMarkdownFormat() async throws {
        // Given
        let viewId = makeTestId("markdown")
        Aware.shared.registerView(viewId, label: "Markdown Test")

        // When
        let markdown = Aware.shared.captureSnapshot(format: .markdown)

        // Then
        XCTAssertEqual(markdown.format, "markdown")
        XCTAssertFalse(markdown.content.isEmpty)
    }

    // MARK: - State in Snapshot Tests

    @MainActor
    func testStateIncludedInTextSnapshot() async throws {
        // Given
        let viewId = makeTestId("state-text")
        Aware.shared.registerView(viewId, label: "State Test")
        Aware.shared.registerState(viewId, key: "counter", value: "99")

        // When
        let text = Aware.shared.captureSnapshot(format: .text)

        // Then: State should appear in text output
        XCTAssertTrue(text.content.contains("counter") || text.content.contains("99"),
                     "Text snapshot should include state information")
    }

    @MainActor
    func testStateIncludedInJSONSnapshot() async throws {
        // Given
        let viewId = makeTestId("state-json")
        Aware.shared.registerView(viewId, label: "State JSON Test")
        Aware.shared.registerState(viewId, key: "mode", value: "active")

        // When
        let json = Aware.shared.captureSnapshot(format: .json)

        // Then: State should appear in JSON
        XCTAssertTrue(json.content.contains("mode") || json.content.contains("active"),
                     "JSON snapshot should include state information")
    }

    // MARK: - Empty Snapshot Tests

    @MainActor
    func testEmptySnapshotStillWorks() async throws {
        // When: Capture with no views registered (cleanup from previous tests)
        // Note: Other tests may have views, so just verify we get a response
        let snapshot = Aware.shared.captureSnapshot(format: .text)

        // Then
        XCTAssertFalse(snapshot.content.isEmpty)
        XCTAssertEqual(snapshot.format, "text")
    }

    // MARK: - Snapshot Result Properties Tests

    @MainActor
    func testSnapshotResultProperties() async throws {
        // Given
        let viewId = makeTestId("result")
        Aware.shared.registerView(viewId, label: "Result Test")

        // When
        let result = Aware.shared.captureSnapshot(format: .compact)

        // Then
        XCTAssertFalse(result.content.isEmpty)
        XCTAssertEqual(result.format, "compact")
        XCTAssertGreaterThan(result.viewCount, 0)
    }
}
