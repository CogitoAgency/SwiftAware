//
//  AwareMacOSPlatformTests.swift
//  AwareMacOSTests
//
//  Tests for AwareMacOSPlatform core functionality.
//  Verifies action callbacks, text bindings, and CGEvent input simulation.
//

#if os(macOS)
import XCTest
import SwiftUI
@testable import AwareMacOS
@testable import AwareCore

@MainActor
final class AwareMacOSPlatformTests: XCTestCase {
    var platform: AwareMacOSPlatform!

    override func setUp() async throws {
        try await super.setUp()
        platform = AwareMacOSPlatform.shared
        Aware.shared.reset()

        #if DEBUG
        print("\n=== Starting test: \(self.name) ===")
        #endif
    }

    override func tearDown() async throws {
        #if DEBUG
        print("=== Finished test: \(self.name) ===\n")
        #endif

        try await super.tearDown()
    }

    // MARK: - Action Callback Tests (Fast Path <1ms)

    func testRegisterAction() async throws {
        // Given
        let viewId = "test-view-\(UUID().uuidString)"

        // When
        platform.registerAction(viewId) {
            // Action callback registered
        }

        // Then
        XCTAssertTrue(platform.actionableViewIds.contains(viewId), "View ID should be registered")
        XCTAssertEqual(platform.actionableViewIds.filter { $0 == viewId }.count, 1, "View ID should appear once")
    }

    func testExecuteAction_Success() async throws {
        // Given
        let viewId = "test-button-\(UUID().uuidString)"
        var actionExecuted = false
        var executionCount = 0

        platform.registerAction(viewId) {
            actionExecuted = true
            executionCount += 1
        }

        // When
        let success = await platform.executeAction(viewId)

        // Then
        XCTAssertTrue(success, "Action execution should succeed")
        XCTAssertTrue(actionExecuted, "Action callback should be executed")
        XCTAssertEqual(executionCount, 1, "Action should execute exactly once")
    }

    func testExecuteAction_NotFound() async throws {
        // Given
        let nonexistentViewId = "nonexistent-\(UUID().uuidString)"

        // When
        let success = await platform.executeAction(nonexistentViewId)

        // Then
        XCTAssertFalse(success, "Action execution should fail for unregistered view")
    }

    func testMultipleActionsForSameView() async throws {
        // Given
        let viewId = "test-view-\(UUID().uuidString)"
        var firstActionExecuted = false
        var secondActionExecuted = false

        // Register first action
        platform.registerAction(viewId) {
            firstActionExecuted = true
        }

        // When - Register second action (should replace first)
        platform.registerAction(viewId) {
            secondActionExecuted = true
        }

        let success = await platform.executeAction(viewId)

        // Then
        XCTAssertTrue(success, "Action execution should succeed")
        XCTAssertFalse(firstActionExecuted, "First action should be replaced")
        XCTAssertTrue(secondActionExecuted, "Second action should execute")
    }

    func testActionCallbackPerformance() async throws {
        // Given
        let viewId = "test-button-\(UUID().uuidString)"
        var actionExecuted = false

        platform.registerAction(viewId) {
            actionExecuted = true
        }

        // When - Measure execution time
        let startTime = CFAbsoluteTimeGetCurrent()
        let success = await platform.executeAction(viewId)
        let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000 // Convert to ms

        // Then
        XCTAssertTrue(success, "Action should execute successfully")
        XCTAssertTrue(actionExecuted, "Action callback should run")
        XCTAssertLessThan(duration, 10.0, "Action callback should execute in < 10ms (fast path)")

        #if DEBUG
        print("Action callback execution time: \(String(format: "%.3f", duration))ms")
        #endif
    }

    // MARK: - Text Binding Tests (Fast Path)

    func testRegisterTextBinding() async throws {
        // Given
        let viewId = "test-textfield-\(UUID().uuidString)"
        @State var text = ""
        let binding = Binding(
            get: { text },
            set: { text = $0 }
        )

        // When
        platform.registerTextBinding(viewId, binding: binding)

        // Then - No direct way to verify internal state, but we can test typeText behavior
        let success = await platform.typeText(viewId, text: "Hello")

        XCTAssertTrue(success, "Type text should succeed with registered binding")
        XCTAssertEqual(text, "Hello", "Text should be set via binding")
    }

    func testTypeText_WithBinding() async throws {
        // Given
        let viewId = "test-field-\(UUID().uuidString)"
        var capturedText = ""

        let binding = Binding<String>(
            get: { capturedText },
            set: { capturedText = $0 }
        )

        platform.registerTextBinding(viewId, binding: binding)

        // When - Type text via binding (fast path)
        let success = await platform.typeText(viewId, text: "Test Input")

        // Then
        XCTAssertTrue(success, "Type text should succeed")
        XCTAssertEqual(capturedText, "Test Input", "Text should be captured via binding")
    }

    func testTypeText_WithoutBinding_FallsBackToCGEvent() async throws {
        // Given
        let viewId = "test-field-no-binding-\(UUID().uuidString)"

        // When - Type text without binding (should fall back to CGEvent)
        let success = await platform.typeText(viewId, text: "Fallback Test")

        // Then
        XCTAssertTrue(success, "Type text should succeed even without binding (CGEvent fallback)")
        // Note: We can't verify the actual CGEvent simulation in unit tests without a real UI
    }

    func testTextBindingPerformance() async throws {
        // Given
        let viewId = "test-field-\(UUID().uuidString)"
        var text = ""

        let binding = Binding(
            get: { text },
            set: { text = $0 }
        )

        platform.registerTextBinding(viewId, binding: binding)

        // When - Measure typing time
        let longText = String(repeating: "A", count: 100)
        let startTime = CFAbsoluteTimeGetCurrent()
        let success = await platform.typeText(viewId, text: longText)
        let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000

        // Then
        XCTAssertTrue(success, "Type text should succeed")
        XCTAssertEqual(text, longText, "All text should be typed")
        XCTAssertLessThan(duration, 10.0, "Binding-based typing should be < 10ms (fast path)")

        #if DEBUG
        print("Text binding typing time: \(String(format: "%.3f", duration))ms")
        #endif
    }

    // MARK: - Input Command Tests

    func testSimulateInput_Tap_WithCallback() async throws {
        // Given
        let viewId = "test-button-\(UUID().uuidString)"
        var tapped = false

        platform.registerAction(viewId) {
            tapped = true
        }

        let command = AwareInputCommand(
            type: .tap,
            target: viewId,
            parameters: [:]
        )

        // When
        let result = await platform.simulateInput(command)

        // Then
        XCTAssertTrue(result.success, "Tap command should succeed")
        XCTAssertTrue(tapped, "Tap callback should be invoked")
        XCTAssertTrue(result.message?.contains("callback") == true, "Message should mention callback route")
    }

    func testSimulateInput_Tap_WithCoordinates() async throws {
        // Given
        let viewId = "test-view-\(UUID().uuidString)"
        let command = AwareInputCommand(
            type: .tap,
            target: viewId,
            parameters: ["x": "100", "y": "200"]
        )

        // When
        let result = await platform.simulateInput(command)

        // Then - CGEvent simulation will always return true (best effort)
        XCTAssertTrue(result.success, "Tap with coordinates should succeed (best effort)")
        // Note: Actual CGEvent execution can't be verified in unit tests
    }

    func testSimulateInput_LongPress() async throws {
        // Given
        let viewId = "test-view-\(UUID().uuidString)"
        let command = AwareInputCommand(
            type: .longPress,
            target: viewId,
            parameters: ["x": "150", "y": "250", "duration": "1.0"]
        )

        // When
        let result = await platform.simulateInput(command)

        // Then
        XCTAssertTrue(result.success, "Long press should succeed (best effort)")
        XCTAssertTrue(result.message?.contains("1.0") == true, "Message should mention duration")
    }

    func testSimulateInput_Type() async throws {
        // Given
        let viewId = "test-field-\(UUID().uuidString)"
        var text = ""

        let binding = Binding(
            get: { text },
            set: { text = $0 }
        )

        platform.registerTextBinding(viewId, binding: binding)

        let command = AwareInputCommand(
            type: .type,
            target: viewId,
            parameters: ["text": "Test Input"]
        )

        // When
        let result = await platform.simulateInput(command)

        // Then
        XCTAssertTrue(result.success, "Type command should succeed")
        XCTAssertEqual(text, "Test Input", "Text should be typed")
        XCTAssertTrue(result.message?.contains("10 characters") == true, "Message should mention character count")
    }

    func testSimulateInput_Type_MissingParameter() async throws {
        // Given
        let viewId = "test-field-\(UUID().uuidString)"
        let command = AwareInputCommand(
            type: .type,
            target: viewId,
            parameters: [:] // Missing "text" parameter
        )

        // When
        let result = await platform.simulateInput(command)

        // Then
        XCTAssertFalse(result.success, "Type command should fail without text parameter")
        XCTAssertTrue(result.message?.contains("Missing text") == true, "Error message should be clear")
    }

    func testSimulateInput_UnsupportedType() async throws {
        // Given
        let viewId = "test-view-\(UUID().uuidString)"
        let command = AwareInputCommand(
            type: .scroll,
            target: viewId,
            parameters: [:]
        )

        // When
        let result = await platform.simulateInput(command)

        // Then
        XCTAssertFalse(result.success, "Scroll should not be supported yet")
        XCTAssertTrue(result.message?.contains("not yet implemented") == true, "Message should indicate not implemented")
    }

    // MARK: - Configuration Tests

    func testPlatformName() throws {
        // Then
        XCTAssertEqual(platform.platformName, "macOS", "Platform name should be 'macOS'")
    }

    func testConfigureForMacOS() throws {
        // When
        Aware.configureForMacOS()

        // Then - No crash, configuration succeeds
        // Subsequent calls should be idempotent
        Aware.configureForMacOS()
        Aware.configureForMacOS()

        // No assertion needed - success is no crash
    }

    // MARK: - Snapshot Enhancement Tests

    func testEnhanceSnapshot() async throws {
        // Note: enhanceSnapshot currently returns snapshot unchanged
        // This test verifies it doesn't crash - actual enhancement is placeholder for future

        // Given - Create a simple snapshot (using AwareSnapshot visual type)
        let visualSnapshot = AwareSnapshot()

        // When/Then - Should not crash (currently returns input unchanged)
        let enhanced = platform.enhanceSnapshot(visualSnapshot)

        // Verify it returns a valid snapshot
        XCTAssertEqual(enhanced.opacity, visualSnapshot.opacity, "Visual properties should be preserved")
    }

    // MARK: - Edge Cases

    func testMultipleTextBindingsForSameView() async throws {
        // Given
        let viewId = "test-field-\(UUID().uuidString)"
        var firstText = ""
        var secondText = ""

        let firstBinding = Binding(
            get: { firstText },
            set: { firstText = $0 }
        )

        let secondBinding = Binding(
            get: { secondText },
            set: { secondText = $0 }
        )

        // Register first binding
        platform.registerTextBinding(viewId, binding: firstBinding)

        // When - Register second binding (should replace first)
        platform.registerTextBinding(viewId, binding: secondBinding)

        let _ = await platform.typeText(viewId, text: "Test")

        // Then
        XCTAssertEqual(firstText, "", "First binding should not receive text")
        XCTAssertEqual(secondText, "Test", "Second binding should receive text")
    }

    func testActionableViewIds() async throws {
        // Given
        let viewId1 = "view-1-\(UUID().uuidString)"
        let viewId2 = "view-2-\(UUID().uuidString)"
        let viewId3 = "view-3-\(UUID().uuidString)"

        // When
        platform.registerAction(viewId1) { }
        platform.registerAction(viewId2) { }
        platform.registerAction(viewId3) { }

        // Then
        let actionableIds = platform.actionableViewIds
        XCTAssertEqual(actionableIds.count, 3, "Should have 3 actionable view IDs")
        XCTAssertTrue(actionableIds.contains(viewId1), "Should contain view 1")
        XCTAssertTrue(actionableIds.contains(viewId2), "Should contain view 2")
        XCTAssertTrue(actionableIds.contains(viewId3), "Should contain view 3")
    }
}

#endif // os(macOS)
