//
//  AwareStalenessModifiers.swift
//  Aware
//
//  Modifiers for detecting stale @State in SwiftUI views.
//  Helps catch the common "stale @State" SwiftUI bug pattern.
//

import SwiftUI

// MARK: - Prop-State Binding Modifier

/// Modifier that tracks a prop → state relationship for staleness detection
struct AwarePropStateModifier<PropValue: Equatable, StateValue: Equatable>: ViewModifier {
    let viewId: String
    let propKey: String
    let stateKey: String
    let propValue: PropValue
    let stateValue: StateValue

    func body(content: Content) -> some View {
        content
            .onAppear {
                MainActor.assumeIsolated {
                    Aware.shared.registerPropStateBinding(
                        viewId,
                        propKey: propKey,
                        stateKey: stateKey,
                        propValue: String(describing: propValue),
                        stateValue: String(describing: stateValue)
                    )
                }
            }
            .onChange(of: propValue) { _, newPropValue in
                MainActor.assumeIsolated {
                    Aware.shared.updatePropValue(
                        viewId,
                        propKey: propKey,
                        newPropValue: String(describing: newPropValue)
                    )
                }
            }
            .onChange(of: stateValue) { _, newStateValue in
                MainActor.assumeIsolated {
                    Aware.shared.updateStateValue(
                        viewId,
                        stateKey: stateKey,
                        newStateValue: String(describing: newStateValue)
                    )
                }
            }
            .onDisappear {
                MainActor.assumeIsolated {
                    Aware.shared.clearPropStateBindings(viewId)
                }
            }
    }
}

// MARK: - Identity Tracking Modifier

/// Modifier that tracks view identity for automatic staleness detection
struct AwareIdentityModifier<IdentityValue: Equatable & CustomStringConvertible>: ViewModifier {
    let viewId: String
    let identityKey: String
    let identityValue: IdentityValue

    func body(content: Content) -> some View {
        content
            .onAppear {
                MainActor.assumeIsolated {
                    Aware.shared.trackIdentity(
                        viewId,
                        identityKey: identityKey,
                        value: identityValue.description
                    )
                }
            }
            .onChange(of: identityValue) { _, newValue in
                MainActor.assumeIsolated {
                    Aware.shared.trackIdentity(
                        viewId,
                        identityKey: identityKey,
                        value: newValue.description
                    )
                }
            }
            .onDisappear {
                MainActor.assumeIsolated {
                    Aware.shared.clearIdentity(viewId)
                }
            }
    }
}

// MARK: - View Extensions

public extension View {
    /// Track a prop → state binding for staleness detection
    ///
    /// Use this to detect the "stale @State" SwiftUI bug pattern where:
    /// - A view receives a prop (e.g., `feature: WorkFeature`)
    /// - The view has @State that should track the prop (e.g., `editableTitle`)
    /// - When SwiftUI reuses the view, @State doesn't re-initialize
    ///
    /// Example:
    /// ```swift
    /// struct FeatureDetailPanel: View {
    ///     let feature: WorkFeature  // Prop
    ///     @State private var editableTitle: String = ""  // State
    ///
    ///     var body: some View {
    ///         TextField("Title", text: $editableTitle)
    ///             .awarePropStateBinding(
    ///                 "featureDetail",
    ///                 propKey: "feature.id",
    ///                 stateKey: "editableTitle",
    ///                 propValue: feature.id,
    ///                 stateValue: editableTitle
    ///             )
    ///     }
    /// }
    /// ```
    func awarePropStateBinding<PropValue: Equatable, StateValue: Equatable>(
        _ viewId: String,
        propKey: String,
        stateKey: String,
        propValue: PropValue,
        stateValue: StateValue
    ) -> some View {
        modifier(AwarePropStateModifier(
            viewId: viewId,
            propKey: propKey,
            stateKey: stateKey,
            propValue: propValue,
            stateValue: stateValue
        ))
    }

    /// Track a view's identity value for automatic staleness detection
    ///
    /// When identity changes but registered state values don't update
    /// within the threshold, a staleness warning is automatically generated.
    ///
    /// Example:
    /// ```swift
    /// struct FeatureDetailPanel: View {
    ///     let feature: WorkFeature
    ///     @State private var editableTitle = ""
    ///
    ///     var body: some View {
    ///         VStack {
    ///             TextField("Title", text: $editableTitle)
    ///         }
    ///         .awareContainer("featureDetail", label: "Feature Detail")
    ///         .awareIdentity("featureDetail", identityValue: feature.id)
    ///         .awareState("featureDetail", key: "title", value: editableTitle)
    ///     }
    /// }
    /// ```
    func awareIdentity<T: Equatable & CustomStringConvertible>(
        _ viewId: String,
        identityKey: String = "id",
        identityValue: T
    ) -> some View {
        modifier(AwareIdentityModifier(
            viewId: viewId,
            identityKey: identityKey,
            identityValue: identityValue
        ))
    }
}

// MARK: - Staleness Overlay (DEBUG only)

#if DEBUG

/// Debug overlay that shows a red border on views with detected staleness
struct AwareStalenessOverlayModifier: ViewModifier {
    let viewId: String

    @State private var hasStaleWarning: Bool = false
    @State private var warningMessage: String = ""

    func body(content: Content) -> some View {
        content
            .overlay {
                if hasStaleWarning {
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.red, lineWidth: 2)

                        Text("STALE")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.red.cornerRadius(4))
                            .padding(4)
                    }
                }
            }
            .onReceive(
                NotificationCenter.default.publisher(for: .awareStalenessDetected)
            ) { notification in
                if let affectedViewId = notification.userInfo?["viewId"] as? String,
                   affectedViewId.hasPrefix(viewId) {
                    hasStaleWarning = true
                    warningMessage = notification.userInfo?["message"] as? String ?? "Stale state"
                }
            }
            .onReceive(
                NotificationCenter.default.publisher(for: .awareStalenessCleared)
            ) { notification in
                if let clearedViewId = notification.userInfo?["viewId"] as? String,
                   clearedViewId.hasPrefix(viewId) {
                    hasStaleWarning = false
                    warningMessage = ""
                }
            }
    }
}

public extension View {
    /// Add debug overlay that shows staleness warnings visually
    /// Only available in DEBUG builds
    func awareStalenessOverlay(_ viewId: String) -> some View {
        modifier(AwareStalenessOverlayModifier(viewId: viewId))
    }
}

#endif
