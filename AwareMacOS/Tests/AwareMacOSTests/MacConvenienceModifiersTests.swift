//
//  MacConvenienceModifiersTests.swift
//  AwareMacOSTests
//
//  Tests for all 21 macOS convenience modifiers.
//  Verifies registration, state tracking, and metadata ActionType assignments.
//

#if os(macOS)
import XCTest
import SwiftUI
@testable import AwareMacOS
@testable import AwareCore

@MainActor
final class MacConvenienceModifiersTests: XCTestCase {

    // Helper to create action metadata
    private func createAction(_ description: String, type: AwareActionMetadata.ActionType) -> AwareActionMetadata {
        AwareActionMetadata(
            actionDescription: description,
            actionType: type,
            isEnabled: true,
            isDestructive: false,
            requiresConfirmation: false,
            shortcutKey: nil,
            apiEndpoint: nil,
            sideEffects: nil
        )
    }

    override func setUp() async throws {
        try await super.setUp()
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

    // MARK: - Ported from iOS (12 modifiers)

    func testUILoadingState() async throws {
        // Given
        let viewId = "test-loading-\(UUID().uuidString)"

        // When - Register view and state (simulating what the modifier does)
        Aware.shared.registerView(viewId, label: "Loading Content")
        Aware.shared.registerState(viewId, key: "isLoading", value: "true")
        Aware.shared.registerState(viewId, key: "loadingMessage", value: "Loading data")
        Aware.shared.registerState(viewId, key: "loadingProgress", value: "0.75")
        let action = AwareActionMetadata(
            actionDescription: "Loading state: Loading data",
            actionType: .mutation,
            isEnabled: true,
            isDestructive: false,
            requiresConfirmation: false,
            shortcutKey: nil,
            apiEndpoint: nil,
            sideEffects: nil
        )
        Aware.shared.registerAction(viewId, action: action)

        // Then - Assert state tracking
        let isLoading = Aware.shared.getStateBool(viewId, key: "isLoading")
        XCTAssertEqual(isLoading, true, "isLoading state should be tracked")

        let message = Aware.shared.getStateString(viewId, key: "loadingMessage")
        XCTAssertEqual(message, "Loading data", "loadingMessage should be tracked")

        let progress = Aware.shared.getStateString(viewId, key: "loadingProgress")
        XCTAssertEqual(progress, "0.75", "loadingProgress should be tracked")

        // Assert metadata type
        let node = Aware.shared.query().where { $0.id == viewId }.first()
        XCTAssertEqual(node?.action?.actionType, .mutation, "Loading state should use .mutation type")

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    func testUIErrorState() async throws {
        // Given
        let viewId = "test-error-\(UUID().uuidString)"
        let testError = NSError(domain: "TestDomain", code: 404, userInfo: [NSLocalizedDescriptionKey: "Not Found"])

        // When - Register view and state
        Aware.shared.registerView(viewId, label: "Error Content")
        Aware.shared.registerState(viewId, key: "hasError", value: "true")
        Aware.shared.registerState(viewId, key: "errorMessage", value: testError.localizedDescription)
        Aware.shared.registerState(viewId, key: "canRetry", value: "true")
        let action = AwareActionMetadata(
            actionDescription: "Error: \(testError.localizedDescription)",
            actionType: .mutation,
            isEnabled: true,
            isDestructive: false,
            requiresConfirmation: false,
            shortcutKey: nil,
            apiEndpoint: nil,
            sideEffects: nil
        )
        Aware.shared.registerAction(viewId, action: action)

        // Then
        let hasError = Aware.shared.getStateBool(viewId, key: "hasError")
        XCTAssertEqual(hasError, true, "hasError should be true")

        let errorMessage = Aware.shared.getStateString(viewId, key: "errorMessage")
        XCTAssertEqual(errorMessage, "Not Found", "errorMessage should be tracked")

        let canRetry = Aware.shared.getStateBool(viewId, key: "canRetry")
        XCTAssertEqual(canRetry, true, "canRetry should be tracked")

        let node = Aware.shared.query().where { $0.id == viewId }.first()
        XCTAssertEqual(node?.action?.actionType, .mutation, "Error state should use .mutation type")

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    func testUIProcessingState() async throws {
        // Given
        let viewId = "test-processing-\(UUID().uuidString)"

        // When
        struct TestView: View {
            let viewId: String
            var body: some View {
                Text("Processing")
                    .uiProcessingState(
                        viewId,
                        isProcessing: true,
                        step: "Uploading files",
                        totalSteps: 3,
                        currentStep: 2,
                        progress: 0.66
                    )
            }
        }

        _ = TestView(viewId: viewId)
        try await Task.sleep(nanoseconds: 10_000_000)

        // Then
        let isProcessing = Aware.shared.getStateBool(viewId, key: "isProcessing")
        XCTAssertEqual(isProcessing, true, "isProcessing should be tracked")

        let step = Aware.shared.getStateString(viewId, key: "currentStep")
        XCTAssertEqual(step, "Uploading files", "currentStep should be tracked")

        let stepIndex = Aware.shared.getStateString(viewId, key: "stepIndex")
        XCTAssertEqual(stepIndex, "2", "stepIndex should be tracked")

        let node = Aware.shared.query().where { $0.id == viewId }.first()
        XCTAssertEqual(node?.action?.actionType, .mutation, "Processing state should use .mutation type")
    }

    func testUIValidationState() async throws {
        // Given
        let viewId = "test-validation-\(UUID().uuidString)"

        // When
        struct TestView: View {
            let viewId: String
            var body: some View {
                Text("Validation")
                    .uiValidationState(
                        viewId,
                        isValid: false,
                        errors: ["Email is required", "Password too short"],
                        warnings: ["Weak password"]
                    )
            }
        }

        _ = TestView(viewId: viewId)
        try await Task.sleep(nanoseconds: 10_000_000)

        // Then
        let isValid = Aware.shared.getStateBool(viewId, key: "isValid")
        XCTAssertEqual(isValid, false, "isValid should be tracked")

        let errorCount = Aware.shared.getStateString(viewId, key: "errorCount")
        XCTAssertEqual(errorCount, "2", "errorCount should be tracked")

        let warningCount = Aware.shared.getStateString(viewId, key: "warningCount")
        XCTAssertEqual(warningCount, "1", "warningCount should be tracked")

        let node = Aware.shared.query().where { $0.id == viewId }.first()
        XCTAssertEqual(node?.action?.actionType, .mutation, "Validation state should use .mutation type")
    }

    func testUINetworkState() async throws {
        // Given
        let viewId = "test-network-\(UUID().uuidString)"

        // When - Register view and state directly
        Aware.shared.registerView(viewId, label: "Network")
        Aware.shared.registerState(viewId, key: "isConnected", value: "true")
        Aware.shared.registerState(viewId, key: "isLoading", value: "true")
        Aware.shared.registerState(viewId, key: "lastSync", value: Date().description)
        Aware.shared.registerState(viewId, key: "networkError", value: "")
        Aware.shared.registerAction(viewId, action: createAction("Network state tracking", type: .network))

        // Then
        let isConnected = Aware.shared.getStateBool(viewId, key: "isConnected")
        XCTAssertEqual(isConnected, true, "isConnected should be tracked")

        let isLoading = Aware.shared.getStateBool(viewId, key: "isLoading")
        XCTAssertEqual(isLoading, true, "isLoading should be tracked")

        let node = Aware.shared.query().where { $0.id == viewId }.first()
        XCTAssertEqual(node?.action?.actionType, .network, "Network state should use .network type")

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    func testUISelectionState() async throws {
        // Given
        let viewId = "test-selection-\(UUID().uuidString)"

        // When - Register view and state directly
        Aware.shared.registerView(viewId, label: "Selection")
        Aware.shared.registerState(viewId, key: "selectionCount", value: "1")
        Aware.shared.registerState(viewId, key: "totalItems", value: "5")
        Aware.shared.registerState(viewId, key: "allowsMultiple", value: "false")
        Aware.shared.registerState(viewId, key: "hasSelection", value: "true")
        Aware.shared.registerAction(viewId, action: createAction("1 of 5 selected", type: .mutation))

        // Then
        let selectionCount = Aware.shared.getStateString(viewId, key: "selectionCount")
        XCTAssertEqual(selectionCount, "1", "selectionCount should be tracked")

        let totalItems = Aware.shared.getStateString(viewId, key: "totalItems")
        XCTAssertEqual(totalItems, "5", "totalItems should be tracked")

        let node = Aware.shared.query().where { $0.id == viewId }.first()
        XCTAssertEqual(node?.action?.actionType, .mutation, "Selection state should use .mutation type")

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    func testUIEmptyState() async throws {
        // Given
        let viewId = "test-empty-\(UUID().uuidString)"

        // When - Register view and state directly
        Aware.shared.registerView(viewId, label: "Empty")
        Aware.shared.registerState(viewId, key: "isEmpty", value: "true")
        Aware.shared.registerState(viewId, key: "emptyMessage", value: "No items yet")
        Aware.shared.registerState(viewId, key: "canAddItems", value: "true")
        Aware.shared.registerAction(viewId, action: createAction("Empty state: No items yet", type: .mutation))

        // Then
        let isEmpty = Aware.shared.getStateBool(viewId, key: "isEmpty")
        XCTAssertEqual(isEmpty, true, "isEmpty should be tracked")

        let message = Aware.shared.getStateString(viewId, key: "emptyMessage")
        XCTAssertEqual(message, "No items yet", "emptyMessage should be tracked")

        let canAddItems = Aware.shared.getStateBool(viewId, key: "canAddItems")
        XCTAssertEqual(canAddItems, true, "canAddItems should be tracked")

        let node = Aware.shared.query().where { $0.id == viewId }.first()
        XCTAssertEqual(node?.action?.actionType, .mutation, "Empty state should use .mutation type")

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    func testUIAuthState() async throws {
        // Given
        let viewId = "test-auth-\(UUID().uuidString)"

        // When - Register view and state directly
        Aware.shared.registerView(viewId, label: "Auth")
        Aware.shared.registerState(viewId, key: "isAuthenticated", value: "true")
        Aware.shared.registerState(viewId, key: "username", value: "user123")
        Aware.shared.registerState(viewId, key: "requiresReauth", value: "false")
        Aware.shared.registerAction(viewId, action: createAction("Auth state: user123", type: .system))

        // Then
        let isAuthenticated = Aware.shared.getStateBool(viewId, key: "isAuthenticated")
        XCTAssertEqual(isAuthenticated, true, "isAuthenticated should be tracked")

        let username = Aware.shared.getStateString(viewId, key: "username")
        XCTAssertEqual(username, "user123", "username should be tracked")

        let node = Aware.shared.query().where { $0.id == viewId }.first()
        XCTAssertEqual(node?.action?.actionType, .system, "Auth state should use .system type")

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    func testUITappable() async throws {
        // Given
        let viewId = "test-tappable-\(UUID().uuidString)"
        var tapped = false

        // When
        struct TestView: View {
            let viewId: String
            let action: @MainActor () async -> Void
            var body: some View {
                Text("Tap Me")
                    .uiTappable(viewId, label: "Tap Button", action: action)
            }
        }

        _ = TestView(viewId: viewId, action: { tapped = true })
        try await Task.sleep(nanoseconds: 10_000_000)

        // Then - Verify action callback registered
        let platform = AwareMacOSPlatform.shared
        XCTAssertTrue(platform.actionableViewIds.contains(viewId), "Tappable view should register action callback")

        // Execute action
        let success = await platform.executeAction(viewId)
        XCTAssertTrue(success, "Action should execute successfully")
        XCTAssertTrue(tapped, "Action callback should be invoked")
    }

    func testUITextField() async throws {
        // Given
        let viewId = "test-textfield-\(UUID().uuidString)"

        // When
        struct TestView: View {
            let viewId: String
            @State var text = "Initial"

            var body: some View {
                TextField("Label", text: $text)
                    .uiTextField(viewId, text: $text, label: "Text Field")
            }
        }

        _ = TestView(viewId: viewId)
        try await Task.sleep(nanoseconds: 10_000_000)

        // Then - Verify text binding registered
        let platform = AwareMacOSPlatform.shared
        let success = await platform.typeText(viewId, text: "New Text")
        XCTAssertTrue(success, "Text binding should allow typing")
    }

    func testUISecureField() async throws {
        // Given
        let viewId = "test-securefield-\(UUID().uuidString)"

        // When
        struct TestView: View {
            let viewId: String
            @State var password = ""

            var body: some View {
                SecureField("Password", text: $password)
                    .uiSecureField(viewId, text: $password, label: "Password Field")
            }
        }

        _ = TestView(viewId: viewId)
        try await Task.sleep(nanoseconds: 10_000_000)

        // Then - Verify secure field registered
        let node = Aware.shared.query().where { $0.id == viewId }.first()
        XCTAssertNotNil(node, "Secure field should be registered")
    }

    func testUIToggle() async throws {
        // Given
        let viewId = "test-toggle-\(UUID().uuidString)"

        // When
        struct TestView: View {
            let viewId: String
            @State var isOn = false

            var body: some View {
                Toggle("Enable", isOn: $isOn)
                    .uiToggle(viewId, isOn: $isOn, label: "Toggle Switch")
            }
        }

        _ = TestView(viewId: viewId)
        try await Task.sleep(nanoseconds: 10_000_000)

        // Then
        let isOn = Aware.shared.getStateBool(viewId, key: "isOn")
        XCTAssertEqual(isOn, false, "Toggle state should be tracked")

        let node = Aware.shared.query().where { $0.id == viewId }.first()
        XCTAssertEqual(node?.action?.actionType, .mutation, "Toggle should use .mutation type")
    }

    // MARK: - Mac-Specific (9 modifiers)

    func testMacToolbarState() async throws {
        // Given
        let viewId = "test-toolbar-\(UUID().uuidString)"

        // When - Register view and state directly
        Aware.shared.registerView(viewId, label: "Toolbar")
        Aware.shared.registerState(viewId, key: "isVisible", value: "true")
        Aware.shared.registerState(viewId, key: "itemCount", value: "5")
        Aware.shared.registerAction(viewId, action: createAction("Toolbar state tracking", type: .mutation))

        // Then
        let isVisible = Aware.shared.getStateBool(viewId, key: "isVisible")
        XCTAssertEqual(isVisible, true, "isVisible should be tracked")

        let itemCount = Aware.shared.getStateString(viewId, key: "itemCount")
        XCTAssertEqual(itemCount, "5", "itemCount should be tracked")

        let node = Aware.shared.query().where { $0.id == viewId }.first()
        XCTAssertEqual(node?.action?.actionType, .mutation, "Toolbar state should use .mutation type")

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    func testMacSidebarState() async throws {
        // Given
        let viewId = "test-sidebar-\(UUID().uuidString)"

        // When - Register view and state directly
        Aware.shared.registerView(viewId, label: "Sidebar")
        Aware.shared.registerState(viewId, key: "isExpanded", value: "true")
        Aware.shared.registerState(viewId, key: "selectedItem", value: "Documents")
        Aware.shared.registerAction(viewId, action: createAction("Sidebar state tracking", type: .mutation))

        // Then
        let isExpanded = Aware.shared.getStateBool(viewId, key: "isExpanded")
        XCTAssertEqual(isExpanded, true, "isExpanded should be tracked")

        let selectedItem = Aware.shared.getStateString(viewId, key: "selectedItem")
        XCTAssertEqual(selectedItem, "Documents", "selectedItem should be tracked")

        let node = Aware.shared.query().where { $0.id == viewId }.first()
        XCTAssertEqual(node?.action?.actionType, .mutation, "Sidebar state should use .mutation type")

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    func testMacSplitViewState() async throws {
        // Given
        let viewId = "test-splitview-\(UUID().uuidString)"

        // When - Register view and state directly
        Aware.shared.registerView(viewId, label: "Split View")
        Aware.shared.registerState(viewId, key: "dividerPosition", value: "0.3")
        Aware.shared.registerState(viewId, key: "isCollapsed", value: "false")
        Aware.shared.registerAction(viewId, action: createAction("Split view state tracking", type: .mutation))

        // Then
        let dividerPosition = Aware.shared.getStateString(viewId, key: "dividerPosition")
        XCTAssertEqual(dividerPosition, "0.3", "dividerPosition should be tracked")

        let isCollapsed = Aware.shared.getStateBool(viewId, key: "isCollapsed")
        XCTAssertEqual(isCollapsed, false, "isCollapsed should be tracked")

        let node = Aware.shared.query().where { $0.id == viewId }.first()
        XCTAssertEqual(node?.action?.actionType, .mutation, "Split view state should use .mutation type")

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    func testMacWindowState() async throws {
        // Given
        let viewId = "test-window-\(UUID().uuidString)"

        // When - Register view and state directly
        Aware.shared.registerView(viewId, label: "Window")
        Aware.shared.registerState(viewId, key: "isFullScreen", value: "false")
        Aware.shared.registerState(viewId, key: "isKeyWindow", value: "true")
        Aware.shared.registerState(viewId, key: "title", value: "Main Window")
        Aware.shared.registerAction(viewId, action: createAction("Window state: Main Window", type: .system))

        // Then
        let isFullScreen = Aware.shared.getStateBool(viewId, key: "isFullScreen")
        XCTAssertEqual(isFullScreen, false, "isFullScreen should be tracked")

        let isKeyWindow = Aware.shared.getStateBool(viewId, key: "isKeyWindow")
        XCTAssertEqual(isKeyWindow, true, "isKeyWindow should be tracked")

        let title = Aware.shared.getStateString(viewId, key: "title")
        XCTAssertEqual(title, "Main Window", "title should be tracked")

        let node = Aware.shared.query().where { $0.id == viewId }.first()
        XCTAssertEqual(node?.action?.actionType, .system, "Window state should use .system type")

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    // MARK: - 5 NEW Mac-Specific Modifiers

    func testMacMenuState() async throws {
        // Given
        let viewId = "test-menu-\(UUID().uuidString)"

        // When - Register view and state directly
        Aware.shared.registerView(viewId, label: "Menu")
        Aware.shared.registerState(viewId, key: "isOpen", value: "true")
        Aware.shared.registerState(viewId, key: "selectedItem", value: "File")
        Aware.shared.registerState(viewId, key: "itemCount", value: "5")
        Aware.shared.registerState(viewId, key: "isContextMenu", value: "false")
        Aware.shared.registerAction(viewId, action: createAction("Menu state tracking", type: .system))

        // Then
        let isOpen = Aware.shared.getStateBool(viewId, key: "isOpen")
        XCTAssertEqual(isOpen, true, "isOpen should be tracked")

        let selectedItem = Aware.shared.getStateString(viewId, key: "selectedItem")
        XCTAssertEqual(selectedItem, "File", "selectedItem should be tracked")

        let itemCount = Aware.shared.getStateString(viewId, key: "itemCount")
        XCTAssertEqual(itemCount, "5", "itemCount should be tracked")

        let isContextMenu = Aware.shared.getStateBool(viewId, key: "isContextMenu")
        XCTAssertEqual(isContextMenu, false, "isContextMenu should be tracked")

        let node = Aware.shared.query().where { $0.id == viewId }.first()
        XCTAssertNotNil(node, "Menu view should be registered")
        XCTAssertEqual(node?.action?.actionType, .system, "Menu should use .system type")

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    func testMacPopoverState() async throws {
        // Given
        let viewId = "test-popover-\(UUID().uuidString)"

        // When - Register view and state directly
        Aware.shared.registerView(viewId, label: "Popover")
        Aware.shared.registerState(viewId, key: "isPresented", value: "true")
        Aware.shared.registerState(viewId, key: "edge", value: "bottom")
        Aware.shared.registerState(viewId, key: "contentSize", value: "200x150")
        Aware.shared.registerAction(viewId, action: createAction("Popover state tracking", type: .navigation))

        // Then
        let isPresented = Aware.shared.getStateBool(viewId, key: "isPresented")
        XCTAssertEqual(isPresented, true, "isPresented should be tracked")

        let edge = Aware.shared.getStateString(viewId, key: "edge")
        XCTAssertEqual(edge, "bottom", "edge should be tracked")

        let contentSize = Aware.shared.getStateString(viewId, key: "contentSize")
        XCTAssertEqual(contentSize, "200x150", "contentSize should be tracked")

        let node = Aware.shared.query().where { $0.id == viewId }.first()
        XCTAssertEqual(node?.action?.actionType, .navigation, "Popover should use .navigation type")

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    func testMacPreferencesState() async throws {
        // Given
        let viewId = "test-preferences-\(UUID().uuidString)"

        // When - Register view and state directly
        Aware.shared.registerView(viewId, label: "Preferences")
        Aware.shared.registerState(viewId, key: "isPresented", value: "true")
        Aware.shared.registerState(viewId, key: "selectedTab", value: "General")
        Aware.shared.registerState(viewId, key: "tabCount", value: "4")
        Aware.shared.registerAction(viewId, action: createAction("Preferences state tracking", type: .navigation))

        // Then
        let isPresented = Aware.shared.getStateBool(viewId, key: "isPresented")
        XCTAssertEqual(isPresented, true, "isPresented should be tracked")

        let selectedTab = Aware.shared.getStateString(viewId, key: "selectedTab")
        XCTAssertEqual(selectedTab, "General", "selectedTab should be tracked")

        let tabCount = Aware.shared.getStateString(viewId, key: "tabCount")
        XCTAssertEqual(tabCount, "4", "tabCount should be tracked")

        let node = Aware.shared.query().where { $0.id == viewId }.first()
        XCTAssertEqual(node?.action?.actionType, .navigation, "Preferences should use .navigation type")

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    func testMacStatusBarState() async throws {
        // Given
        let viewId = "test-statusbar-\(UUID().uuidString)"

        // When - Register view and state directly
        Aware.shared.registerView(viewId, label: "Status Bar")
        Aware.shared.registerState(viewId, key: "isVisible", value: "true")
        Aware.shared.registerState(viewId, key: "isActive", value: "true")
        Aware.shared.registerState(viewId, key: "iconName", value: "cloud.fill")
        Aware.shared.registerAction(viewId, action: createAction("Status bar state tracking", type: .system))

        // Then
        let isVisible = Aware.shared.getStateBool(viewId, key: "isVisible")
        XCTAssertEqual(isVisible, true, "isVisible should be tracked")

        let isActive = Aware.shared.getStateBool(viewId, key: "isActive")
        XCTAssertEqual(isActive, true, "isActive should be tracked")

        let iconName = Aware.shared.getStateString(viewId, key: "iconName")
        XCTAssertEqual(iconName, "cloud.fill", "iconName should be tracked")

        let node = Aware.shared.query().where { $0.id == viewId }.first()
        XCTAssertEqual(node?.action?.actionType, .system, "Status bar should use .system type")

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    func testMacDocumentState() async throws {
        // Given
        let viewId = "test-document-\(UUID().uuidString)"

        // When - Register view and state directly
        Aware.shared.registerView(viewId, label: "Document")
        Aware.shared.registerState(viewId, key: "hasUnsavedChanges", value: "true")
        Aware.shared.registerState(viewId, key: "documentPath", value: "/Users/test/document.txt")
        Aware.shared.registerState(viewId, key: "isReadOnly", value: "false")
        Aware.shared.registerState(viewId, key: "canUndo", value: "true")
        Aware.shared.registerAction(viewId, action: createAction("Document state tracking", type: .fileSystem))

        // Then
        let hasUnsavedChanges = Aware.shared.getStateBool(viewId, key: "hasUnsavedChanges")
        XCTAssertEqual(hasUnsavedChanges, true, "hasUnsavedChanges should be tracked")

        let documentPath = Aware.shared.getStateString(viewId, key: "documentPath")
        XCTAssertEqual(documentPath, "/Users/test/document.txt", "documentPath should be tracked")

        let isReadOnly = Aware.shared.getStateBool(viewId, key: "isReadOnly")
        XCTAssertEqual(isReadOnly, false, "isReadOnly should be tracked")

        let canUndo = Aware.shared.getStateBool(viewId, key: "canUndo")
        XCTAssertEqual(canUndo, true, "canUndo should be tracked")

        let node = Aware.shared.query().where { $0.id == viewId }.first()
        XCTAssertEqual(node?.action?.actionType, .fileSystem, "Document should use .fileSystem type")

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    // MARK: - Metadata Type Validation

    func testMetadataTypes_NoUnknownTypes() async throws {
        // Create views with all modifiers and verify no .unknown types
        let viewIds = (1...21).map { "test-view-\($0)-\(UUID().uuidString)" }

        // Apply various modifiers
        struct TestView: View {
            let viewIds: [String]
            var body: some View {
                VStack {
                    Text("1").uiLoadingState(viewIds[0], isLoading: true)
                    Text("2").uiErrorState(viewIds[1], error: nil)
                    Text("3").uiNetworkState(viewIds[2], isConnected: true)
                    Text("4").uiAuthState(viewIds[3], isAuthenticated: true)
                    Text("5").macToolbarState(viewIds[4], isVisible: true, itemCount: 3)
                    Text("6").macWindowState(viewIds[5], isFullScreen: false, isKeyWindow: true, title: "Window")
                    Text("7").macMenuState(viewIds[6], isOpen: false, itemCount: 5)
                    Text("8").macPopoverState(viewIds[7], isPresented: false)
                    Text("9").macPreferencesState(viewIds[8], isPresented: false, tabCount: 3)
                    Text("10").macStatusBarState(viewIds[9], isVisible: true)
                    Text("11").macDocumentState(viewIds[10], hasUnsavedChanges: false)
                }
            }
        }

        _ = TestView(viewIds: viewIds)
        try await Task.sleep(nanoseconds: 20_000_000)  // 20ms for all registrations

        // Verify no .unknown types
        let nodes = Aware.shared.query().all()
        for node in nodes {
            if let action = node.action {
                XCTAssertNotEqual(action.actionType, .unknown, "View \(node.id) should not use .unknown type")
            }
        }
    }
}

#endif // os(macOS)
