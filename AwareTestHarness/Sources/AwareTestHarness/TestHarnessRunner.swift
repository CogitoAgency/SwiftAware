//
//  TestHarnessRunner.swift
//  AwareTestHarness
//
//  Programmatic initialization of test views for headless testing.
//

import Foundation
import SwiftUI
import AwareCore

/// Orchestrates programmatic view initialization for headless testing
@MainActor
public final class TestHarnessRunner: ObservableObject {

    // MARK: - State

    @Published public private(set) var currentView: String = "login"
    @Published public private(set) var isInitialized: Bool = false

    /// View instances (programmatically created)
    private var loginView: LoginView?
    private var listView: ListViewWithSearch?
    private var formView: FormView?

    public init() {}

    // MARK: - Initialization

    /// Initialize all test views programmatically
    public func initialize() async {
        print("  → Creating LoginView...")
        loginView = LoginView()
        await registerLoginView()

        print("  → Creating ListViewWithSearch...")
        listView = ListViewWithSearch()
        await registerListView()

        print("  → Creating FormView...")
        formView = FormView()
        await registerFormView()

        isInitialized = true
        print("  ✓ All views initialized")

        // Generate initial snapshot
        await captureSnapshot()
    }

    // MARK: - View Registration

    private func registerLoginView() async {
        // Register the login view container
        Aware.shared.registerView(
            "login-view",
            label: "Login Form",
            isContainer: true,
            parentId: nil
        )

        // Register email field
        Aware.shared.registerView(
            "email-field",
            label: "Email",
            isContainer: false,
            parentId: "login-view"
        )
        Aware.shared.registerStateTyped("email-field", key: "value", value: .string(""))
        Aware.shared.registerStateTyped("email-field", key: "isFocused", value: .bool(false))

        // Register password field
        Aware.shared.registerView(
            "password-field",
            label: "Password",
            isContainer: false,
            parentId: "login-view"
        )
        Aware.shared.registerStateTyped("password-field", key: "value", value: .string(""))
        Aware.shared.registerStateTyped("password-field", key: "isFocused", value: .bool(false))

        // Register login button
        Aware.shared.registerView(
            "login-btn",
            label: "Login",
            isContainer: false,
            parentId: "login-view"
        )
        Aware.shared.registerStateTyped("login-btn", key: "isEnabled", value: .bool(true))

        // Register loading state
        Aware.shared.registerStateTyped("login-view", key: "isLoading", value: .bool(false))
        Aware.shared.registerStateTyped("login-view", key: "isAuthenticated", value: .bool(false))
        Aware.shared.registerStateTyped("login-view", key: "errorMessage", value: .string(""))
    }

    private func registerListView() async {
        // Register list container
        Aware.shared.registerView(
            "list-view",
            label: "List with Search",
            isContainer: true,
            parentId: nil
        )

        // Register search field
        Aware.shared.registerView(
            "search-field",
            label: "Search",
            isContainer: false,
            parentId: "list-view"
        )
        Aware.shared.registerStateTyped("search-field", key: "value", value: .string(""))

        // Register list items (10 sample items)
        for i in 0..<10 {
            let viewId = "list-item-\(i)"
            Aware.shared.registerView(
                viewId,
                label: "Item \(i + 1)",
                isContainer: false,
                parentId: "list-view"
            )
            Aware.shared.registerStateTyped(viewId, key: "title", value: .string("Item \(i + 1)"))
            Aware.shared.registerStateTyped(viewId, key: "isSelected", value: .bool(false))
        }

        // Register list state
        Aware.shared.registerStateTyped("list-view", key: "itemCount", value: .int(10))
        Aware.shared.registerStateTyped("list-view", key: "filteredCount", value: .int(10))
    }

    private func registerFormView() async {
        // Register form container
        Aware.shared.registerView(
            "form-view",
            label: "Multi-step Form",
            isContainer: true,
            parentId: nil
        )

        // Register step indicator
        Aware.shared.registerView(
            "step-indicator",
            label: "Step 1 of 3",
            isContainer: false,
            parentId: "form-view"
        )

        // Register name field (Step 1)
        Aware.shared.registerView(
            "name-field",
            label: "Full Name",
            isContainer: false,
            parentId: "form-view"
        )
        Aware.shared.registerStateTyped("name-field", key: "value", value: .string(""))
        Aware.shared.registerStateTyped("name-field", key: "isValid", value: .bool(false))

        // Register email field (Step 2)
        Aware.shared.registerView(
            "form-email-field",
            label: "Email Address",
            isContainer: false,
            parentId: "form-view"
        )
        Aware.shared.registerStateTyped("form-email-field", key: "value", value: .string(""))
        Aware.shared.registerStateTyped("form-email-field", key: "isValid", value: .bool(false))

        // Register phone field (Step 3)
        Aware.shared.registerView(
            "phone-field",
            label: "Phone Number",
            isContainer: false,
            parentId: "form-view"
        )
        Aware.shared.registerStateTyped("phone-field", key: "value", value: .string(""))
        Aware.shared.registerStateTyped("phone-field", key: "isValid", value: .bool(false))

        // Register Next/Submit button
        Aware.shared.registerView(
            "next-btn",
            label: "Next",
            isContainer: false,
            parentId: "form-view"
        )

        // Register form state
        Aware.shared.registerStateTyped("form-view", key: "currentStep", value: .int(1))
        Aware.shared.registerStateTyped("form-view", key: "totalSteps", value: .int(3))
        Aware.shared.registerStateTyped("form-view", key: "isComplete", value: .bool(false))
        Aware.shared.registerStateTyped("form-view", key: "validationErrors", value: .string(""))
    }

    // MARK: - Snapshot Capture

    /// Capture and write snapshot to IPC file
    private func captureSnapshot() async {
        let snapshot = Aware.shared.captureSnapshot(format: .compact)
        print("  📊 Snapshot generated: \(snapshot.content.count) chars (~\(snapshot.content.count / 4) tokens)")

        // Write to IPC file
        do {
            let ipcPath = NSString(string: "~/.aware").expandingTildeInPath
            let snapshotPath = "\(ipcPath)/ui-snapshot.json"

            try FileManager.default.createDirectory(
                atPath: ipcPath,
                withIntermediateDirectories: true
            )

            try snapshot.content.write(
                toFile: snapshotPath,
                atomically: true,
                encoding: .utf8
            )
        } catch {
            print("  ⚠️  Failed to write snapshot: \(error)")
        }
    }

    // MARK: - View Navigation

    /// Navigate to a specific view
    public func navigateTo(_ viewName: String) async {
        currentView = viewName
        await captureSnapshot()
    }
}
