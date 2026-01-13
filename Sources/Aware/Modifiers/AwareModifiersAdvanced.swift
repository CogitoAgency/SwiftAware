//
//  AwareModifiersAdvanced.swift
//  Aware
//
//  Advanced view modifiers for scroll, focus, overflow, animation tracking.
//

import SwiftUI

// MARK: - Scroll Tracking Modifier

/// Tracks scroll position for scrollable views
struct AwareScrollModifier: ViewModifier {
    let viewId: String

    @State private var scrollOffset: CGPoint = .zero

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(
                            key: AwareScrollOffsetKey.self,
                            value: geo.frame(in: .named("scroll")).origin
                        )
                }
            )
            .onPreferenceChange(AwareScrollOffsetKey.self) { offset in
                scrollOffset = offset
                Task { @MainActor in
                    Aware.shared.updateScrollState(
                        viewId,
                        offset: offset,
                        contentSize: .zero,
                        visibleRect: .zero
                    )
                }
            }
    }
}

/// Internal preference key for scroll tracking
private struct AwareScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
        value = nextValue()
    }
}

// MARK: - Focus Tracking Modifier

/// Tracks focus and hover state for interactive views
struct AwareFocusModifier: ViewModifier {
    let viewId: String

    @FocusState private var isFocused: Bool
    @State private var isHovered: Bool = false

    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            #if os(macOS)
            .onHover { hovering in
                isHovered = hovering
                Task { @MainActor in
                    Aware.shared.updateFocusState(viewId, isFocused: isFocused, isHovered: hovering)
                }
            }
            #endif
            .onChange(of: isFocused) { _, newValue in
                Task { @MainActor in
                    Aware.shared.updateFocusState(viewId, isFocused: newValue, isHovered: isHovered)
                }
            }
    }
}

// MARK: - Text Overflow Tracking Modifier

/// Tracks text truncation/overflow for Text views
struct AwareOverflowModifier: ViewModifier {
    let viewId: String
    let text: String
    let maxLines: Int
    let font: Font

    @State private var isTruncated: Bool = false
    @State private var intrinsicSize: CGSize = .zero
    @State private var actualLineCount: Int = 0

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            measureOverflow(in: geo.size)
                        }
                        .onChange(of: geo.size) { _, newSize in
                            measureOverflow(in: newSize)
                        }
                }
            )
    }

    private func measureOverflow(in size: CGSize) {
        #if os(macOS)
        let nsFont = NSFont.systemFont(ofSize: 14)
        let attributes: [NSAttributedString.Key: Any] = [.font: nsFont]
        let boundingRect = (text as NSString).boundingRect(
            with: CGSize(width: size.width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )

        intrinsicSize = boundingRect.size
        let lineHeight = nsFont.ascender - nsFont.descender + nsFont.leading
        actualLineCount = max(1, Int(ceil(boundingRect.height / lineHeight)))
        #elseif os(iOS)
        let uiFont = UIFont.systemFont(ofSize: 14)
        let attributes: [NSAttributedString.Key: Any] = [.font: uiFont]
        let boundingRect = (text as NSString).boundingRect(
            with: CGSize(width: size.width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )

        intrinsicSize = boundingRect.size
        let lineHeight = uiFont.lineHeight
        actualLineCount = max(1, Int(ceil(boundingRect.height / lineHeight)))
        #endif

        isTruncated = maxLines > 0 && actualLineCount > maxLines

        Task { @MainActor in
            Aware.shared.updateTextOverflow(
                viewId,
                isTruncated: isTruncated,
                intrinsicSize: intrinsicSize,
                lineCount: actualLineCount,
                maxLines: maxLines
            )
        }
    }
}

// MARK: - Animation Tracking Modifier

/// Tracks animation state for animated views
struct AwareAnimationModifier: ViewModifier {
    let viewId: String
    let animationType: String
    let duration: Double
    let isAnimating: Binding<Bool>

    func body(content: Content) -> some View {
        content
            .onChange(of: isAnimating.wrappedValue) { _, animating in
                Task { @MainActor in
                    let state = AwareAnimationState(
                        isAnimating: animating,
                        animationType: animationType,
                        duration: duration
                    )
                    if animating {
                        Aware.shared.registerAnimation(viewId, animation: state)
                    } else {
                        Aware.shared.clearAnimation(viewId)
                    }
                }
            }
    }
}

// MARK: - Action Metadata Modifier

/// Registers action metadata for buttons/interactive elements
struct AwareMetadataModifier: ViewModifier {
    let viewId: String
    let action: AwareActionMetadata

    func body(content: Content) -> some View {
        content
            .onAppear {
                Task { @MainActor in
                    Aware.shared.registerAction(viewId, action: action)
                }
            }
            .onChange(of: action.actionDescription) { _, _ in
                Task { @MainActor in
                    Aware.shared.registerAction(viewId, action: action)
                }
            }
    }
}

// MARK: - Behavior Metadata Modifier

/// Registers backend behavior metadata for data-bound views
struct AwareBehaviorModifier: ViewModifier {
    let viewId: String
    let behavior: AwareBehaviorMetadata

    func body(content: Content) -> some View {
        content
            .onAppear {
                Task { @MainActor in
                    Aware.shared.registerBehavior(viewId, behavior: behavior)
                }
            }
    }
}

// MARK: - Enhanced View Extensions

public extension View {
    /// Track scroll position for this scrollable view
    func awareScroll(_ id: String) -> some View {
        modifier(AwareScrollModifier(viewId: id))
    }

    /// Track focus and hover state for this view
    func awareFocus(_ id: String) -> some View {
        modifier(AwareFocusModifier(viewId: id))
    }

    /// Track text overflow/truncation
    func awareOverflow(
        _ id: String,
        text: String,
        maxLines: Int = 0,
        font: Font = .body
    ) -> some View {
        modifier(AwareOverflowModifier(
            viewId: id,
            text: text,
            maxLines: maxLines,
            font: font
        ))
    }

    /// Track animation state for this view
    func awareAnimation(
        _ id: String,
        type: String,
        duration: Double,
        isAnimating: Binding<Bool>
    ) -> some View {
        modifier(AwareAnimationModifier(
            viewId: id,
            animationType: type,
            duration: duration,
            isAnimating: isAnimating
        ))
    }

    /// Register action metadata for a button/interactive element
    func awareMetadata(
        _ id: String,
        description: String,
        type: AwareActionMetadata.ActionType = .unknown,
        isEnabled: Bool = true,
        isDestructive: Bool = false,
        requiresConfirmation: Bool = false,
        shortcut: String? = nil,
        apiEndpoint: String? = nil,
        sideEffects: [String]? = nil
    ) -> some View {
        modifier(AwareMetadataModifier(
            viewId: id,
            action: AwareActionMetadata(
                actionDescription: description,
                actionType: type,
                isEnabled: isEnabled,
                isDestructive: isDestructive,
                requiresConfirmation: requiresConfirmation,
                shortcutKey: shortcut,
                apiEndpoint: apiEndpoint,
                sideEffects: sideEffects
            )
        ))
    }

    /// Register backend behavior metadata for a data-bound view
    func awareBehavior(
        _ id: String,
        dataSource: String? = nil,
        refreshTrigger: String? = nil,
        cacheDuration: String? = nil,
        errorHandling: String? = nil,
        loadingBehavior: String? = nil,
        validationRules: [String]? = nil,
        boundModel: String? = nil,
        dependencies: [String]? = nil
    ) -> some View {
        modifier(AwareBehaviorModifier(
            viewId: id,
            behavior: AwareBehaviorMetadata(
                dataSource: dataSource,
                refreshTrigger: refreshTrigger,
                cacheDuration: cacheDuration,
                errorHandling: errorHandling,
                loadingBehavior: loadingBehavior,
                validationRules: validationRules,
                boundModel: boundModel,
                dependencies: dependencies
            )
        ))
    }
}
