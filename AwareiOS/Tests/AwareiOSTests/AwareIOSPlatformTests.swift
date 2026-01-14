//
//  AwareIOSPlatformTests.swift
//  AwareiOSTests
//
//  Tests for AwareIOSPlatform core functionality.
//  Covers configuration, action registration, gesture registration,
//  text binding, input simulation, and snapshot enhancement.
//

#if os(iOS)
import XCTest
@testable import AwareiOS
import AwareCore
import SwiftUI

@MainActor
final class AwareIOSPlatformTests: XCTestCase {

    override func setUp() async throws {
        // Note: AwareIOSPlatform is a singleton, tests may have state dependencies
        try await super.setUp()
    }

    // MARK: - Configuration Tests (4 tests)

    func testSingletonAccess() {
        // Test that shared instance is accessible
        let platform = AwareIOSPlatform.shared
        XCTAssertNotNil(platform)
        XCTAssertEqual(platform.platformName, "iOS")
    }

    func testConfigurationWithDefaultSettings() {
        // Test configuration with default settings
        let config = AwareIOSConfiguration.default

        XCTAssertEqual(config.ipcPath, "~/.aware")
        XCTAssertEqual(config.transportMode, .auto)
        XCTAssertEqual(config.heartbeatInterval, 2.0)
        XCTAssertEqual(config.commandTimeoutAttempts, 50)
    }

    func testConfigurationWithCustomSettings() {
        // Test configuration with custom settings
        let config = AwareIOSConfiguration(
            ipcPath: "/tmp/aware-test",
            transportMode: .fileBased,
            webSocketHost: "127.0.0.1",
            webSocketPort: 8888,
            heartbeatInterval: 1.0,
            commandTimeoutAttempts: 30
        )

        XCTAssertEqual(config.ipcPath, "/tmp/aware-test")
        XCTAssertEqual(config.transportMode, .fileBased)
        XCTAssertEqual(config.webSocketHost, "127.0.0.1")
        XCTAssertEqual(config.webSocketPort, 8888)
        XCTAssertEqual(config.heartbeatInterval, 1.0)
        XCTAssertEqual(config.commandTimeoutAttempts, 30)
    }

    func testConfigurationValidation() {
        // Test configuration validation catches invalid values
        let invalidConfig = AwareIOSConfiguration(
            ipcPath: "",  // Invalid
            transportMode: .auto,
            webSocketHost: "",  // Invalid
            webSocketPort: -1,  // Invalid
            heartbeatInterval: -1.0,  // Invalid
            commandTimeoutAttempts: -1  // Invalid
        )

        let errors = invalidConfig.validate()
        XCTAssertFalse(errors.isEmpty)
        XCTAssertTrue(errors.contains("ipcPath cannot be empty"))
        XCTAssertTrue(errors.contains("webSocketHost cannot be empty"))
        XCTAssertTrue(errors.contains("webSocketPort must be between 1 and 65535"))
        XCTAssertTrue(errors.contains("heartbeatInterval must be positive"))
        XCTAssertTrue(errors.contains("commandTimeoutAttempts must be positive"))
    }

    // MARK: - Action Registration Tests (6 tests)

    func testRegisterActionCallback() async {
        let viewId = "test-btn-\(UUID().uuidString)"
        var executed = false

        AwareIOSPlatform.shared.registerAction(viewId) {
            executed = true
        }

        let success = await AwareIOSPlatform.shared.executeAction(viewId)

        XCTAssertTrue(success)
        XCTAssertTrue(executed)
    }

    func testExecuteUnregisteredAction() async {
        let viewId = "nonexistent-\(UUID().uuidString)"

        let success = await AwareIOSPlatform.shared.executeAction(viewId)

        XCTAssertFalse(success)
    }

    func testRegisterMultipleActions() async {
        let viewId1 = "btn1-\(UUID().uuidString)"
        let viewId2 = "btn2-\(UUID().uuidString)"
        var executed1 = false
        var executed2 = false

        AwareIOSPlatform.shared.registerAction(viewId1) {
            executed1 = true
        }

        AwareIOSPlatform.shared.registerAction(viewId2) {
            executed2 = true
        }

        let success1 = await AwareIOSPlatform.shared.executeAction(viewId1)
        let success2 = await AwareIOSPlatform.shared.executeAction(viewId2)

        XCTAssertTrue(success1)
        XCTAssertTrue(success2)
        XCTAssertTrue(executed1)
        XCTAssertTrue(executed2)
    }

    func testReplaceActionCallback() async {
        let viewId = "test-btn-\(UUID().uuidString)"
        var firstExecuted = false
        var secondExecuted = false

        // Register first action
        AwareIOSPlatform.shared.registerAction(viewId) {
            firstExecuted = true
        }

        // Replace with second action
        AwareIOSPlatform.shared.registerAction(viewId) {
            secondExecuted = true
        }

        let success = await AwareIOSPlatform.shared.executeAction(viewId)

        XCTAssertTrue(success)
        XCTAssertFalse(firstExecuted)  // First callback should not execute
        XCTAssertTrue(secondExecuted)   // Second callback should execute
    }

    func testAsyncActionCallback() async {
        let viewId = "test-btn-\(UUID().uuidString)"
        var executed = false

        AwareIOSPlatform.shared.registerAction(viewId) {
            try? await Task.sleep(for: .milliseconds(50))
            executed = true
        }

        let success = await AwareIOSPlatform.shared.executeAction(viewId)

        XCTAssertTrue(success)
        XCTAssertTrue(executed)
    }

    func testActionableViewIds() async {
        let viewId1 = "btn1-\(UUID().uuidString)"
        let viewId2 = "btn2-\(UUID().uuidString)"

        AwareIOSPlatform.shared.registerAction(viewId1) {}
        AwareIOSPlatform.shared.registerAction(viewId2) {}

        let actionableIds = AwareIOSPlatform.shared.actionableViewIds

        XCTAssertTrue(actionableIds.contains(viewId1))
        XCTAssertTrue(actionableIds.contains(viewId2))
    }

    // MARK: - Gesture Registration Tests (3 tests)

    func testRegisterGestureCallback() {
        let viewId = "test-view-\(UUID().uuidString)"
        var executed = false

        AwareIOSPlatform.shared.registerGesture(viewId, type: "longPress") {
            executed = true
        }

        // Cannot easily test execution without direct access to gestureCallbacks
        // This test verifies registration doesn't crash
        XCTAssertFalse(executed)
    }

    func testRegisterMultipleGesturesPerView() {
        let viewId = "test-view-\(UUID().uuidString)"

        AwareIOSPlatform.shared.registerGesture(viewId, type: "longPress") {}
        AwareIOSPlatform.shared.registerGesture(viewId, type: "swipeUp") {}
        AwareIOSPlatform.shared.registerGesture(viewId, type: "scrollDown") {}

        // Test verifies registration doesn't crash
        XCTAssertTrue(true)
    }

    func testOverwriteGestureCallback() {
        let viewId = "test-view-\(UUID().uuidString)"

        AwareIOSPlatform.shared.registerGesture(viewId, type: "longPress") {}
        AwareIOSPlatform.shared.registerGesture(viewId, type: "longPress") {}

        // Test verifies overwrite doesn't crash
        XCTAssertTrue(true)
    }

    // MARK: - Text Binding Tests (5 tests)

    func testRegisterTextBinding() {
        let viewId = "test-field-\(UUID().uuidString)"
        var text = ""
        let binding = Binding(get: { text }, set: { text = $0 })

        AwareIOSPlatform.shared.registerTextBinding(viewId, binding: binding)

        let textInputIds = AwareIOSPlatform.shared.textInputViewIds
        XCTAssertTrue(textInputIds.contains(viewId))
    }

    func testTypeTextIntoRegisteredField() async {
        let viewId = "test-field-\(UUID().uuidString)"
        var text = ""
        let binding = Binding(get: { text }, set: { text = $0 })

        AwareIOSPlatform.shared.registerTextBinding(viewId, binding: binding)

        let success = await AwareIOSPlatform.shared.typeText(viewId, text: "Hello")

        XCTAssertTrue(success)
        XCTAssertEqual(text, "Hello")
    }

    func testTypeTextIntoUnregisteredField() async {
        let viewId = "nonexistent-\(UUID().uuidString)"

        let success = await AwareIOSPlatform.shared.typeText(viewId, text: "Hello")

        XCTAssertFalse(success)
    }

    func testRegisterMultipleTextBindings() async {
        let viewId1 = "field1-\(UUID().uuidString)"
        let viewId2 = "field2-\(UUID().uuidString)"
        var text1 = ""
        var text2 = ""
        let binding1 = Binding(get: { text1 }, set: { text1 = $0 })
        let binding2 = Binding(get: { text2 }, set: { text2 = $0 })

        AwareIOSPlatform.shared.registerTextBinding(viewId1, binding: binding1)
        AwareIOSPlatform.shared.registerTextBinding(viewId2, binding: binding2)

        let success1 = await AwareIOSPlatform.shared.typeText(viewId1, text: "First")
        let success2 = await AwareIOSPlatform.shared.typeText(viewId2, text: "Second")

        XCTAssertTrue(success1)
        XCTAssertTrue(success2)
        XCTAssertEqual(text1, "First")
        XCTAssertEqual(text2, "Second")
    }

    func testReplaceTextBinding() async {
        let viewId = "test-field-\(UUID().uuidString)"
        var text1 = ""
        var text2 = ""
        let binding1 = Binding(get: { text1 }, set: { text1 = $0 })
        let binding2 = Binding(get: { text2 }, set: { text2 = $0 })

        AwareIOSPlatform.shared.registerTextBinding(viewId, binding: binding1)
        AwareIOSPlatform.shared.registerTextBinding(viewId, binding: binding2)

        let success = await AwareIOSPlatform.shared.typeText(viewId, text: "Test")

        XCTAssertTrue(success)
        XCTAssertEqual(text1, "")      // First binding should not be updated
        XCTAssertEqual(text2, "Test")  // Second binding should be updated
    }

    // MARK: - Input Simulation Tests (5 tests)

    func testSimulateTap() async {
        let viewId = "test-btn-\(UUID().uuidString)"
        var executed = false

        AwareIOSPlatform.shared.registerAction(viewId) {
            executed = true
        }

        let command = AwareInputCommand(type: .tap, target: viewId, parameters: [:])
        let result = await AwareIOSPlatform.shared.simulateInput(command)

        XCTAssertTrue(result.success)
        XCTAssertTrue(executed)
        XCTAssertTrue(result.message.contains("Tapped"))
    }

    func testSimulateTypeText() async {
        let viewId = "test-field-\(UUID().uuidString)"
        var text = ""
        let binding = Binding(get: { text }, set: { text = $0 })

        AwareIOSPlatform.shared.registerTextBinding(viewId, binding: binding)

        let command = AwareInputCommand(type: .type, target: viewId, parameters: ["text": "Hello"])
        let result = await AwareIOSPlatform.shared.simulateInput(command)

        XCTAssertTrue(result.success)
        XCTAssertEqual(text, "Hello")
        XCTAssertTrue(result.message.contains("Typed"))
    }

    func testSimulateLongPress() async {
        let viewId = "test-view-\(UUID().uuidString)"
        var executed = false

        AwareIOSPlatform.shared.registerGesture(viewId, type: "longPress") {
            executed = true
        }

        let command = AwareInputCommand(type: .longPress, target: viewId, parameters: ["duration": "0.1"])
        let result = await AwareIOSPlatform.shared.simulateInput(command)

        XCTAssertTrue(result.success)
        XCTAssertTrue(executed)
        XCTAssertTrue(result.message.contains("Long pressed"))
    }

    func testSimulateSwipe() async {
        let viewId = "test-view-\(UUID().uuidString)"
        var executed = false

        AwareIOSPlatform.shared.registerGesture(viewId, type: "swipeUp") {
            executed = true
        }

        let command = AwareInputCommand(type: .swipe, target: viewId, parameters: ["direction": "up"])
        let result = await AwareIOSPlatform.shared.simulateInput(command)

        XCTAssertTrue(result.success)
        XCTAssertTrue(executed)
        XCTAssertTrue(result.message.contains("Swiped"))
    }

    func testSimulateScroll() async {
        let viewId = "test-view-\(UUID().uuidString)"
        var executed = false

        AwareIOSPlatform.shared.registerGesture(viewId, type: "scrollDown") {
            executed = true
        }

        let command = AwareInputCommand(type: .scroll, target: viewId, parameters: ["direction": "down", "distance": "200"])
        let result = await AwareIOSPlatform.shared.simulateInput(command)

        XCTAssertTrue(result.success)
        XCTAssertTrue(executed)
        XCTAssertTrue(result.message.contains("Scrolled"))
    }

    // MARK: - Snapshot Enhancement Tests (2 tests)

    func testEnhanceSnapshotPassthrough() {
        let snapshot = AwareSnapshot(
            timestamp: Date(),
            viewCount: 5,
            format: .compact,
            content: "Test snapshot"
        )

        let enhanced = AwareIOSPlatform.shared.enhanceSnapshot(snapshot)

        // Currently returns unchanged
        XCTAssertEqual(enhanced.viewCount, snapshot.viewCount)
        XCTAssertEqual(enhanced.format, snapshot.format)
    }

    func testEnhanceSnapshotPreservesMetadata() {
        let snapshot = AwareSnapshot(
            timestamp: Date(),
            viewCount: 10,
            format: .text,
            content: "Detailed snapshot"
        )

        let enhanced = AwareIOSPlatform.shared.enhanceSnapshot(snapshot)

        XCTAssertEqual(enhanced.timestamp, snapshot.timestamp)
        XCTAssertEqual(enhanced.viewCount, snapshot.viewCount)
        XCTAssertEqual(enhanced.content, snapshot.content)
    }
}

#endif // os(iOS)
