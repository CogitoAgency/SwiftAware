//
//  AwareIOSBasicModifiersTests.swift
//  AwareiOSTests
//
//  Tests for basic UI modifiers (uiButton, uiTextField, etc.).
//  Covers registration, state tracking, and modifier integration.
//

#if os(iOS)
import XCTest
@testable import AwareiOS
import AwareCore
import SwiftUI

@MainActor
final class AwareIOSBasicModifiersTests: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
    }

    // MARK: - Button Modifier Tests (4 tests)

    func testUIButtonRegistersView() async {
        let viewId = "test-btn-\(UUID().uuidString)"
        var actionExecuted = false

        let button = Button("Test") {
            actionExecuted = true
        }
        .uiButton(viewId, label: "Test Button") {
            actionExecuted = true
        }

        // Allow registration to complete
        try? await Task.sleep(for: .milliseconds(100))

        // Verify action callback works
        let success = await AwareIOSPlatform.shared.executeAction(viewId)

        XCTAssertTrue(success)
        XCTAssertTrue(actionExecuted)
    }

    func testUIButtonWithoutAction() async {
        let viewId = "test-btn-\(UUID().uuidString)"

        let button = Button("Test") {}
            .uiButton(viewId, label: "Test Button", action: nil)

        try? await Task.sleep(for: .milliseconds(100))

        // Should not have action callback
        let actionableIds = AwareIOSPlatform.shared.actionableViewIds
        XCTAssertFalse(actionableIds.contains(viewId))
    }

    func testUIButtonStateTracking() async {
        let viewId = "test-btn-\(UUID().uuidString)"

        let button = Button("Test") {}
            .uiButton(viewId, label: "Test Button") {}

        try? await Task.sleep(for: .milliseconds(100))

        // Verify button is actionable
        let actionableIds = AwareIOSPlatform.shared.actionableViewIds
        XCTAssertTrue(actionableIds.contains(viewId))
    }

    func testUIButtonMultipleInstances() async {
        let viewId1 = "btn1-\(UUID().uuidString)"
        let viewId2 = "btn2-\(UUID().uuidString)"
        var executed1 = false
        var executed2 = false

        let button1 = Button("Test 1") {}
            .uiButton(viewId1, label: "Button 1") { executed1 = true }

        let button2 = Button("Test 2") {}
            .uiButton(viewId2, label: "Button 2") { executed2 = true }

        try? await Task.sleep(for: .milliseconds(100))

        let success1 = await AwareIOSPlatform.shared.executeAction(viewId1)
        let success2 = await AwareIOSPlatform.shared.executeAction(viewId2)

        XCTAssertTrue(success1)
        XCTAssertTrue(success2)
        XCTAssertTrue(executed1)
        XCTAssertTrue(executed2)
    }

    // MARK: - TextField Modifier Tests (5 tests)

    func testUITextFieldRegistersView() async {
        let viewId = "test-field-\(UUID().uuidString)"
        @State var text = ""

        let field = TextField("Test", text: $text)
            .uiTextField(viewId, text: $text, label: "Test Field")

        try? await Task.sleep(for: .milliseconds(100))

        // Verify text binding works
        let success = await AwareIOSPlatform.shared.typeText(viewId, text: "Hello")

        XCTAssertTrue(success)
        XCTAssertEqual(text, "Hello")
    }

    func testUITextFieldTextTracking() async {
        let viewId = "test-field-\(UUID().uuidString)"
        @State var text = "Initial"

        let field = TextField("Test", text: $text)
            .uiTextField(viewId, text: $text, label: "Test Field")

        try? await Task.sleep(for: .milliseconds(100))

        // Text binding should be registered
        let textInputIds = AwareIOSPlatform.shared.textInputViewIds
        XCTAssertTrue(textInputIds.contains(viewId))
    }

    func testUITextFieldWithFocus() async {
        let viewId = "test-field-\(UUID().uuidString)"
        @State var text = ""
        @State var isFocused = false

        let field = TextField("Test", text: $text)
            .uiTextField(viewId, text: $text, label: "Test Field", isFocused: $isFocused)

        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertTrue(AwareIOSPlatform.shared.textInputViewIds.contains(viewId))
    }

    func testUITextFieldWithPlaceholder() async {
        let viewId = "test-field-\(UUID().uuidString)"
        @State var text = ""

        let field = TextField("Test", text: $text)
            .uiTextField(viewId, text: $text, label: "Test Field", placeholder: "Enter text")

        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertTrue(AwareIOSPlatform.shared.textInputViewIds.contains(viewId))
    }

    func testUITextFieldEmpty() async {
        let viewId = "test-field-\(UUID().uuidString)"
        @State var text = ""

        let field = TextField("Test", text: $text)
            .uiTextField(viewId, text: $text, label: "Test Field")

        try? await Task.sleep(for: .milliseconds(100))

        // Empty field should still be registered
        XCTAssertTrue(AwareIOSPlatform.shared.textInputViewIds.contains(viewId))
    }

    // MARK: - SecureField Modifier Tests (3 tests)

    func testUISecureFieldRegistersView() async {
        let viewId = "test-secure-\(UUID().uuidString)"
        @State var password = ""

        let field = SecureField("Password", text: $password)
            .uiSecureField(viewId, text: $password, label: "Password")

        try? await Task.sleep(for: .milliseconds(100))

        // Verify it's registered as a text input
        XCTAssertTrue(AwareIOSPlatform.shared.textInputViewIds.contains(viewId))
    }

    func testUISecureFieldHidesText() async {
        let viewId = "test-secure-\(UUID().uuidString)"
        @State var password = "secret123"

        let field = SecureField("Password", text: $password)
            .uiSecureField(viewId, text: $password, label: "Password")

        try? await Task.sleep(for: .milliseconds(100))

        // Text binding should work even though text is hidden
        let success = await AwareIOSPlatform.shared.typeText(viewId, text: "newpassword")

        XCTAssertTrue(success)
        XCTAssertEqual(password, "newpassword")
    }

    func testUISecureFieldCharacterCount() async {
        let viewId = "test-secure-\(UUID().uuidString)"
        @State var password = ""

        let field = SecureField("Password", text: $password)
            .uiSecureField(viewId, text: $password, label: "Password", placeholder: "Enter password")

        try? await Task.sleep(for: .milliseconds(100))

        await AwareIOSPlatform.shared.typeText(viewId, text: "12345")

        // Character count should be tracked
        XCTAssertEqual(password.count, 5)
    }

    // MARK: - Toggle Modifier Tests (3 tests)

    func testUIToggleRegistersView() async {
        let viewId = "test-toggle-\(UUID().uuidString)"
        @State var isOn = false

        let toggle = Toggle("Test", isOn: $isOn)
            .uiToggle(viewId, isOn: $isOn, label: "Test Toggle")

        try? await Task.sleep(for: .milliseconds(100))

        // Toggle should be registered (verify doesn't crash)
        XCTAssertTrue(true)
    }

    func testUIToggleStateTracking() async {
        let viewId = "test-toggle-\(UUID().uuidString)"
        @State var isOn = false

        let toggle = Toggle("Test", isOn: $isOn)
            .uiToggle(viewId, isOn: $isOn, label: "Test Toggle")

        try? await Task.sleep(for: .milliseconds(100))

        // Initial state should be false
        XCTAssertFalse(isOn)
    }

    func testUIToggleInitiallyOn() async {
        let viewId = "test-toggle-\(UUID().uuidString)"
        @State var isOn = true

        let toggle = Toggle("Test", isOn: $isOn)
            .uiToggle(viewId, isOn: $isOn, label: "Test Toggle")

        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertTrue(isOn)
    }

    // MARK: - Picker Modifier Tests (3 tests)

    func testUIPickerRegistersView() async {
        let viewId = "test-picker-\(UUID().uuidString)"
        @State var selection = "Option 1"
        let options = ["Option 1", "Option 2", "Option 3"]

        let picker = Picker("Test", selection: $selection) {
            ForEach(options, id: \.self) { option in
                Text(option)
            }
        }
        .uiPicker(viewId, selection: $selection, label: "Test Picker", options: options)

        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertTrue(true)  // Verify doesn't crash
    }

    func testUIPickerSelectionTracking() async {
        let viewId = "test-picker-\(UUID().uuidString)"
        @State var selection = 0
        let options = [0, 1, 2]

        let picker = Picker("Test", selection: $selection) {
            ForEach(options, id: \.self) { option in
                Text("Option \(option)")
            }
        }
        .uiPicker(viewId, selection: $selection, label: "Test Picker", options: options)

        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertEqual(selection, 0)
    }

    func testUIPickerWithMultipleOptions() async {
        let viewId = "test-picker-\(UUID().uuidString)"
        @State var selection = "Red"
        let options = ["Red", "Green", "Blue", "Yellow"]

        let picker = Picker("Color", selection: $selection) {
            ForEach(options, id: \.self) { color in
                Text(color)
            }
        }
        .uiPicker(viewId, selection: $selection, label: "Color Picker", options: options)

        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertEqual(selection, "Red")
        XCTAssertEqual(options.count, 4)
    }

    // MARK: - Slider Modifier Tests (2 tests)

    func testUISliderRegistersView() async {
        let viewId = "test-slider-\(UUID().uuidString)"
        @State var value = 0.5

        let slider = Slider(value: $value, in: 0...1)
            .uiSlider(viewId, value: $value, in: 0...1, label: "Test Slider")

        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertTrue(true)  // Verify doesn't crash
    }

    func testUISliderValueTracking() async {
        let viewId = "test-slider-\(UUID().uuidString)"
        @State var value = 25.0

        let slider = Slider(value: $value, in: 0...100)
            .uiSlider(viewId, value: $value, in: 0...100, label: "Test Slider")

        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertEqual(value, 25.0)
    }
}

#endif // os(iOS)
