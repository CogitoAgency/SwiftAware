//
//  AwareIOSPlatform.swift
//  AwareiOS
//
//  iOS platform implementation of Aware framework.
//  Provides iOS-specific gesture handling, action callbacks, and IPC.
//
//  Based on AetherSing's successful iOS integration patterns.
//

#if os(iOS)
import UIKit
import SwiftUI
import AwareCore

// MARK: - iOS Platform Implementation

/// iOS platform service implementing AwarePlatform protocol
@MainActor
public final class AwareIOSPlatform: AwarePlatform {
    public static let shared = AwareIOSPlatform()

    // MARK: - AwarePlatform Protocol

    public let platformName: String = "iOS"

    // MARK: - State

    private var actionCallbacks: [String: @Sendable @MainActor () async -> Void] = [:]
    private var gestureCallbacks: [String: [String: () async -> Void]] = [:]
    private var ipcService: AwareIPCService?
    private var isConfigured = false

    private init() {
        // Auto-register with Aware.shared on initialization
        // Aware.shared.configurePlatform(self) // TODO: Uncomment when AwareService supports this
    }

    // MARK: - Configuration

    /// Configure iOS platform with IPC settings
    /// - Parameters:
    ///   - options: Configuration options ("ipcPath": String)
    public func configure(options: [String: Any]) {
        guard !isConfigured else { return }

        let ipcPath = options["ipcPath"] as? String ?? "~/.aware"

        // Initialize IPC service
        ipcService = AwareIPCService(ipcPath: ipcPath)
        ipcService?.startHeartbeat()

        isConfigured = true

        #if DEBUG
        print("AwareIOS: Platform configured with IPC path: \(ipcPath)")
        #endif
    }

    // MARK: - Action Registration

    /// Register an action callback for ghost UI testing
    public func registerAction(_ viewId: String, callback: @escaping @Sendable @MainActor () async -> Void) {
        actionCallbacks[viewId] = callback

        #if DEBUG
        print("AwareIOS: Registered action for view: \(viewId)")
        #endif
    }

    /// Execute a registered action
    public func executeAction(_ viewId: String) async -> Bool {
        guard let callback = actionCallbacks[viewId] else {
            #if DEBUG
            print("AwareIOS: No action callback registered for view: \(viewId)")
            #endif
            return false
        }

        #if DEBUG
        print("AwareIOS: Executing action for view: \(viewId)")
        #endif

        await callback()
        return true
    }

    // MARK: - Gesture Registration

    /// Register a gesture callback
    public func registerGesture(_ viewId: String, type: String, callback: @escaping () async -> Void) {
        if gestureCallbacks[viewId] == nil {
            gestureCallbacks[viewId] = [:]
        }
        gestureCallbacks[viewId]?[type] = callback

        #if DEBUG
        print("AwareIOS: Registered gesture '\(type)' for view: \(viewId)")
        #endif
    }

    // MARK: - Input Simulation

    /// Simulate input command (iOS uses direct callbacks, not CGEvents)
    public func simulateInput(_ command: AwareInputCommand) async -> AwareInputResult {
        switch command.type {
        case .tap:
            let success = await executeAction(command.target)
            return AwareInputResult(
                success: success,
                message: success ? "Tapped '\(command.target)'" : "No action registered for '\(command.target)'"
            )

        case .longPress:
            // TODO: Implement long press simulation
            return AwareInputResult(success: false, message: "Long press not yet implemented on iOS")

        case .swipe, .scroll:
            // TODO: Implement swipe/scroll simulation
            return AwareInputResult(success: false, message: "Swipe/scroll not yet implemented on iOS")

        case .type:
            // TODO: Implement text input simulation via textBindings
            return AwareInputResult(success: false, message: "Text input simulation not yet implemented")

        default:
            return AwareInputResult(success: false, message: "Unsupported input type: \(command.type.rawValue)")
        }
    }

    // MARK: - Snapshot Enhancement

    /// Enhance snapshot with iOS-specific metadata
    public func enhanceSnapshot(_ snapshot: AwareSnapshot) -> AwareSnapshot {
        // iOS-specific enhancements could include:
        // - Safe area insets
        // - Dynamic type scaling
        // - Accessibility traits
        // For now, return snapshot unchanged
        return snapshot
    }

    // MARK: - Convenience

    /// Get registered view IDs with action callbacks
    public var actionableViewIds: [String] {
        Array(actionCallbacks.keys)
    }
}

// MARK: - Public Configuration Extension

public extension Aware {
    /// Configure Aware for iOS platform
    /// Sets up iOS-specific features and IPC communication
    /// - Parameter ipcPath: Path to IPC directory (default: ~/.aware)
    static func configureForIOS(ipcPath: String = "~/.aware") {
        AwareIOSPlatform.shared.configure(options: ["ipcPath": ipcPath])

        #if DEBUG
        print("Aware: Configured for iOS platform")
        #endif
    }
}

#endif // os(iOS)
