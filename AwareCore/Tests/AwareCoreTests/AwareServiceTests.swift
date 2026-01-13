//
//  AwareServiceTests.swift
//  Aware
//
//  Basic tests for the Aware framework.
//

import XCTest
@testable import Aware

final class AwareServiceTests: XCTestCase {

    @MainActor
    func testRegisterView() async throws {
        // Given
        let viewId = "test-view-\(UUID().uuidString)"
        let uniqueLabel = "Test View \(viewId)"

        // When
        Aware.shared.registerView(viewId, label: uniqueLabel)

        // Then
        let node = Aware.shared.query().where { $0.id == viewId }.first()
        XCTAssertNotNil(node)
        XCTAssertEqual(node?.label, uniqueLabel)

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    @MainActor
    func testRegisterState() async throws {
        // Given
        let viewId = "test-view-\(UUID().uuidString)"
        Aware.shared.registerView(viewId, label: "Test View")

        // When
        Aware.shared.registerState(viewId, key: "count", value: "42")

        // Then - query by state filter should find the view
        let matchingViews = Aware.shared.query()
            .state("count", equals: "42")
            .where { $0.id == viewId }
            .all()
        XCTAssertFalse(matchingViews.isEmpty)

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    @MainActor
    func testSnapshotCapture() async throws {
        // Given
        let viewId = "test-view-\(UUID().uuidString)"
        Aware.shared.registerView(viewId, label: "Snapshot Test")

        // When
        let snapshot = Aware.shared.captureSnapshot(format: .json)

        // Then
        XCTAssertFalse(snapshot.content.isEmpty)
        XCTAssertEqual(snapshot.format, AwareSnapshotFormat.json.rawValue)

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    @MainActor
    func testQueryBuilder() async throws {
        // Given
        let viewId1 = "button-test-\(UUID().uuidString)"
        let viewId2 = "text-test-\(UUID().uuidString)"
        Aware.shared.registerView(viewId1, label: "Save Button")
        Aware.shared.registerView(viewId2, label: "Title Text")

        // When
        let buttonResults = Aware.shared.query().labelContains("Button").all()
        let textResults = Aware.shared.query().labelContains("Text").all()

        // Then
        XCTAssertTrue(buttonResults.contains(where: { $0.id == viewId1 }))
        XCTAssertTrue(textResults.contains(where: { $0.id == viewId2 }))

        // Cleanup
        Aware.shared.unregisterView(viewId1)
        Aware.shared.unregisterView(viewId2)
    }

    // MARK: - Staleness Detection Tests

    @MainActor
    func testStalenessDetection() async throws {
        // Given
        let viewId = "staleness-test-\(UUID().uuidString)"
        Aware.shared.registerView(viewId, label: "Stale View")

        // Register prop-state binding with initial values
        Aware.shared.registerPropStateBinding(
            viewId,
            propKey: "selectedIndex",
            stateKey: "currentSelection",
            propValue: "0",
            stateValue: "0"
        )

        // When: Update prop without updating state (simulates staleness)
        Aware.shared.updatePropValue(viewId, propKey: "selectedIndex", newPropValue: "5")

        // Wait for staleness threshold (300ms + buffer)
        try await Task.sleep(nanoseconds: 400_000_000)

        // Then: Should detect staleness
        let warnings = Aware.shared.getStalenessWarnings(for: viewId)
        XCTAssertFalse(warnings.isEmpty, "Should detect staleness when prop changes but state doesn't")

        // Cleanup
        Aware.shared.clearPropStateBindings(viewId)
        Aware.shared.unregisterView(viewId)
    }

    @MainActor
    func testStalenessClearing() async throws {
        // Given
        let viewId = "staleness-clear-\(UUID().uuidString)"
        Aware.shared.registerView(viewId, label: "Clear Stale View")

        Aware.shared.registerPropStateBinding(
            viewId,
            propKey: "index",
            stateKey: "selection",
            propValue: "0",
            stateValue: "0"
        )

        // When: Update prop then update state (simulates proper sync)
        Aware.shared.updatePropValue(viewId, propKey: "index", newPropValue: "10")
        Aware.shared.updateStateValue(viewId, stateKey: "selection", newStateValue: "10")

        // Then: No staleness should be detected
        let result = Aware.shared.assertNoPropStateStaleness(viewId: viewId)
        XCTAssertTrue(result.passed, "Should have no staleness when state follows prop")

        // Cleanup
        Aware.shared.clearPropStateBindings(viewId)
        Aware.shared.unregisterView(viewId)
    }

    // MARK: - Direct Action Callback Tests

    @MainActor
    func testTapDirectCallback() async throws {
        // Given
        let viewId = "tap-test-\(UUID().uuidString)"
        var callbackExecuted = false

        Aware.shared.registerView(viewId, label: "Tap Button")
        Aware.shared.updateFrame(viewId, frame: CGRect(x: 0, y: 0, width: 100, height: 50))

        // Register direct action callback
        Aware.shared.registerAction(viewId) {
            callbackExecuted = true
        }

        // When: Execute tap via direct callback
        let result = await Aware.shared.tapDirect(viewId)

        // Then
        XCTAssertTrue(result.success, "Tap should succeed")
        XCTAssertTrue(callbackExecuted, "Callback should have been executed")

        // Cleanup
        Aware.shared.unregisterAction(viewId)
        Aware.shared.unregisterView(viewId)
    }

    @MainActor
    func testHasDirectAction() async throws {
        // Given
        let viewId = "action-check-\(UUID().uuidString)"
        Aware.shared.registerView(viewId, label: "Action View")

        // Initially no action
        XCTAssertFalse(Aware.shared.hasDirectAction(viewId))

        // When: Register action
        Aware.shared.registerAction(viewId) { }

        // Then
        XCTAssertTrue(Aware.shared.hasDirectAction(viewId))

        // Cleanup
        Aware.shared.unregisterAction(viewId)
        Aware.shared.unregisterView(viewId)
    }

    // MARK: - Snapshot Format Tests

    @MainActor
    func testCompactSnapshotFormat() async throws {
        // Given
        let viewId = "format-test-\(UUID().uuidString)"
        Aware.shared.registerView(viewId, label: "Compact Test View")
        Aware.shared.registerState(viewId, key: "value", value: "42")

        // When
        let compact = Aware.shared.captureSnapshot(format: .compact)
        let json = Aware.shared.captureSnapshot(format: .json)

        // Then: Compact should be shorter than JSON
        XCTAssertLessThan(compact.content.count, json.content.count, "Compact format should be shorter")
        XCTAssertEqual(compact.format, "compact")

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    @MainActor
    func testTextSnapshotFormat() async throws {
        // Given
        let viewId = "text-format-\(UUID().uuidString)"
        Aware.shared.registerView(viewId, label: "Text Format Test")

        // When
        let text = Aware.shared.captureSnapshot(format: .text)

        // Then
        XCTAssertFalse(text.content.isEmpty)
        XCTAssertEqual(text.format, "text")
        XCTAssertTrue(text.content.contains("Text Format Test"), "Should contain the label")

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    @MainActor
    func testMarkdownSnapshotFormat() async throws {
        // Given
        let viewId = "md-format-\(UUID().uuidString)"
        Aware.shared.registerView(viewId, label: "Markdown Test")

        // When
        let markdown = Aware.shared.captureSnapshot(format: .markdown)

        // Then
        XCTAssertFalse(markdown.content.isEmpty)
        XCTAssertEqual(markdown.format, "markdown")

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    // MARK: - Assertion Tests

    @MainActor
    func testAssertNoPropStateStaleness() async throws {
        // Given: Clean view with no bindings
        let viewId = "assert-test-\(UUID().uuidString)"
        Aware.shared.registerView(viewId, label: "Assert Test")

        // When: Check for staleness on view with no bindings
        let result = Aware.shared.assertNoPropStateStaleness(viewId: viewId)

        // Then: Should pass (no staleness possible without bindings)
        XCTAssertTrue(result.passed)
        XCTAssertEqual(result.message, "No prop-state staleness detected")

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    // MARK: - State Registry Tests

    @MainActor
    func testGetAllStates() async throws {
        // Given
        let viewId = "states-test-\(UUID().uuidString)"
        Aware.shared.registerView(viewId, label: "States Test")
        Aware.shared.registerState(viewId, key: "count", value: "5")
        Aware.shared.registerState(viewId, key: "name", value: "Test")

        // When
        let allStates = Aware.shared.getAllStates()

        // Then
        XCTAssertNotNil(allStates[viewId])
        XCTAssertEqual(allStates[viewId]?["count"], "5")
        XCTAssertEqual(allStates[viewId]?["name"], "Test")

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    @MainActor
    func testListRegisteredActions() async throws {
        // Given
        let viewId1 = "action-list-1-\(UUID().uuidString)"
        let viewId2 = "action-list-2-\(UUID().uuidString)"
        Aware.shared.registerView(viewId1, label: "Action 1")
        Aware.shared.registerView(viewId2, label: "Action 2")
        Aware.shared.registerAction(viewId1) { }
        Aware.shared.registerAction(viewId2) { }

        // When
        let actions = Aware.shared.listRegisteredActions()

        // Then
        XCTAssertTrue(actions.contains(viewId1))
        XCTAssertTrue(actions.contains(viewId2))

        // Cleanup
        Aware.shared.unregisterAction(viewId1)
        Aware.shared.unregisterAction(viewId2)
        Aware.shared.unregisterView(viewId1)
        Aware.shared.unregisterView(viewId2)
    }
}
