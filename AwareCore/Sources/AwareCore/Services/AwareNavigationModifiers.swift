//
//  AwareNavigationModifiers.swift
//  Aware
//
//  View modifiers for navigation context registration.
//  Enables LLM control of back navigation, modal dismissal, and routing.
//

import SwiftUI

// MARK: - Navigation Context Modifier

/// View modifier that registers navigation context for back/dismiss support
struct AwareNavigationContextModifier: ViewModifier {
    let contextId: String
    let parentContext: String?
    let onBack: (() async -> Void)?
    let onDismiss: (() async -> Void)?

    func body(content: Content) -> some View {
        content
            .onAppear {
                MainActor.assumeIsolated {
                    // Set this as current context
                    AwareNavigationManager.shared.setContext(contextId, parent: parentContext)

                    // Register navigation callbacks
                    if let onBack = onBack {
                        AwareNavigationManager.shared.registerBack(contextId, callback: onBack)
                    }

                    if let onDismiss = onDismiss {
                        AwareNavigationManager.shared.registerDismiss(contextId, callback: onDismiss)
                    }

                    // Register context state for snapshots
                    Aware.shared.registerState(contextId, key: "type", value: "navigationContext")
                    Aware.shared.registerState(contextId, key: "canGoBack", value: onBack != nil ? "true" : "false")
                    Aware.shared.registerState(contextId, key: "canDismiss", value: onDismiss != nil ? "true" : "false")
                }
            }
            .onDisappear {
                MainActor.assumeIsolated {
                    AwareNavigationManager.shared.clearContext(contextId)
                    Aware.shared.clearState(contextId)
                }
            }
    }
}

// MARK: - Navigation Path Modifier

/// View modifier that registers a NavigationPath for programmatic navigation
struct AwareNavigationPathModifier: ViewModifier {
    let contextId: String
    @Binding var path: NavigationPath

    func body(content: Content) -> some View {
        content
            .onAppear {
                MainActor.assumeIsolated {
                    AwareNavigationManager.shared.registerNavigationPath(contextId, path: $path)
                    Aware.shared.registerState(contextId, key: "stackDepth", value: "\(path.count)")
                }
            }
            .onChange(of: path.count) { _, newCount in
                MainActor.assumeIsolated {
                    Aware.shared.registerState(contextId, key: "stackDepth", value: "\(newCount)")
                }
            }
    }
}

// MARK: - Modal Modifier

/// View modifier for modal/sheet presentations
struct AwareModalModifier: ViewModifier {
    let modalId: String
    let onDismiss: () async -> Void

    func body(content: Content) -> some View {
        content
            .onAppear {
                MainActor.assumeIsolated {
                    // Set modal as current context
                    AwareNavigationManager.shared.setContext(modalId)

                    // Register dismiss callback
                    AwareNavigationManager.shared.registerDismiss(modalId, callback: onDismiss)

                    // Register state
                    Aware.shared.registerState(modalId, key: "type", value: "modal")
                    Aware.shared.registerState(modalId, key: "canDismiss", value: "true")
                }
            }
            .onDisappear {
                MainActor.assumeIsolated {
                    AwareNavigationManager.shared.clearContext(modalId)
                    Aware.shared.clearState(modalId)
                }
            }
    }
}

// MARK: - Screen Modifier

/// View modifier for screen-level registration (combines container + navigation context)
struct AwareScreenModifier: ViewModifier {
    let screenId: String
    let title: String
    let parentContext: String?
    let onBack: (() async -> Void)?

    func body(content: Content) -> some View {
        content
            .awareContainer(screenId, label: title)
            .modifier(AwareNavigationContextModifier(
                contextId: screenId,
                parentContext: parentContext,
                onBack: onBack,
                onDismiss: nil
            ))
            .onAppear {
                MainActor.assumeIsolated {
                    Aware.shared.registerState(screenId, key: "screenTitle", value: title)
                }
            }
    }
}

// MARK: - Tab Bar Context Modifier

/// View modifier for tab bar navigation tracking
struct AwareTabContextModifier: ViewModifier {
    let tabBarId: String
    @Binding var selectedTab: Int
    let tabLabels: [String]

    func body(content: Content) -> some View {
        content
            .onAppear {
                MainActor.assumeIsolated {
                    Aware.shared.registerState(tabBarId, key: "type", value: "tabBar")
                    Aware.shared.registerState(tabBarId, key: "selectedTab", value: "\(selectedTab)")
                    Aware.shared.registerState(tabBarId, key: "tabCount", value: "\(tabLabels.count)")
                    Aware.shared.registerState(tabBarId, key: "tabLabels", value: tabLabels.joined(separator: ","))
                }
            }
            .onChange(of: selectedTab) { _, newTab in
                MainActor.assumeIsolated {
                    Aware.shared.registerState(tabBarId, key: "selectedTab", value: "\(newTab)")
                }
            }
    }
}

// MARK: - View Extensions

public extension View {
    /// Register navigation context for back/dismiss support
    /// - Parameters:
    ///   - id: Context identifier
    ///   - parent: Optional parent context ID
    ///   - onBack: Callback for back navigation
    ///   - onDismiss: Callback for modal dismissal
    func awareNavigationContext(
        _ id: String,
        parent: String? = nil,
        onBack: (() async -> Void)? = nil,
        onDismiss: (() async -> Void)? = nil
    ) -> some View {
        modifier(AwareNavigationContextModifier(
            contextId: id,
            parentContext: parent,
            onBack: onBack,
            onDismiss: onDismiss
        ))
    }

    /// Register NavigationPath for programmatic navigation
    /// - Parameters:
    ///   - id: Context identifier
    ///   - path: Binding to the NavigationPath
    func awareNavigationPath(
        _ id: String,
        path: Binding<NavigationPath>
    ) -> some View {
        modifier(AwareNavigationPathModifier(contextId: id, path: path))
    }

    /// Register as a modal/sheet
    /// - Parameters:
    ///   - id: Modal identifier
    ///   - onDismiss: Callback when modal should dismiss
    func awareModal(
        _ id: String,
        onDismiss: @escaping () async -> Void
    ) -> some View {
        modifier(AwareModalModifier(modalId: id, onDismiss: onDismiss))
    }

    /// Register as a screen with navigation support
    /// - Parameters:
    ///   - id: Screen identifier
    ///   - title: Screen title
    ///   - parent: Optional parent context
    ///   - onBack: Callback for back navigation
    func awareScreen(
        _ id: String,
        title: String,
        parent: String? = nil,
        onBack: (() async -> Void)? = nil
    ) -> some View {
        modifier(AwareScreenModifier(
            screenId: id,
            title: title,
            parentContext: parent,
            onBack: onBack
        ))
    }

    /// Register tab bar navigation context
    /// - Parameters:
    ///   - id: Tab bar identifier
    ///   - selectedTab: Binding to selected tab index
    ///   - tabLabels: Labels for each tab
    func awareTabBar(
        _ id: String,
        selectedTab: Binding<Int>,
        tabLabels: [String]
    ) -> some View {
        modifier(AwareTabContextModifier(
            tabBarId: id,
            selectedTab: selectedTab,
            tabLabels: tabLabels
        ))
    }
}
