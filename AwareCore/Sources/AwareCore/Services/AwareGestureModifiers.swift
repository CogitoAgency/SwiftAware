//
//  AwareGestureModifiers.swift
//  Aware
//
//  View modifiers for registering gesture callbacks on iOS.
//  Enables LLM control of swipe, long press, double tap, and pinch gestures.
//

import SwiftUI

// MARK: - Swipeable Modifier

/// View modifier that registers swipe gesture callbacks for LLM control
struct AwareSwipeableModifier: ViewModifier {
    let viewId: String
    let directions: Set<AwareSwipeDirection>
    let onSwipe: (AwareSwipeDirection) async -> Void

    func body(content: Content) -> some View {
        content
            .onAppear {
                MainActor.assumeIsolated {
                    for direction in directions {
                        let gestureType: AwareGestureType
                        switch direction {
                        case .up: gestureType = .swipeUp
                        case .down: gestureType = .swipeDown
                        case .left: gestureType = .swipeLeft
                        case .right: gestureType = .swipeRight
                        }

                        let capturedDirection = direction
                        Aware.shared.registerGesture(viewId, type: gestureType) {
                            await onSwipe(capturedDirection)
                        }
                    }
                }
            }
            .onDisappear {
                MainActor.assumeIsolated {
                    Aware.shared.unregisterGestures(viewId)
                }
            }
    }
}

// MARK: - Long Pressable Modifier

/// View modifier that registers long press callback for LLM control
struct AwareLongPressableModifier: ViewModifier {
    let viewId: String
    let onLongPress: () async -> Void

    func body(content: Content) -> some View {
        content
            .onAppear {
                MainActor.assumeIsolated {
                    Aware.shared.registerGesture(viewId, type: .longPress) {
                        await onLongPress()
                    }
                }
            }
            .onDisappear {
                MainActor.assumeIsolated {
                    // Only unregister long press, not other gestures
                    Aware.shared.registerGesture(viewId, type: .longPress) { }
                }
            }
    }
}

// MARK: - Double Tappable Modifier

/// View modifier that registers double tap callback for LLM control
struct AwareDoubleTappableModifier: ViewModifier {
    let viewId: String
    let onDoubleTap: () async -> Void

    func body(content: Content) -> some View {
        content
            .onAppear {
                MainActor.assumeIsolated {
                    Aware.shared.registerGesture(viewId, type: .doubleTap) {
                        await onDoubleTap()
                    }
                }
            }
            .onDisappear {
                MainActor.assumeIsolated {
                    // Only unregister double tap
                    Aware.shared.registerGesture(viewId, type: .doubleTap) { }
                }
            }
    }
}

// MARK: - Pinchable Modifier

/// View modifier that registers pinch callbacks for LLM control
struct AwarePinchableModifier: ViewModifier {
    let viewId: String
    let onPinch: (CGFloat) async -> Void

    func body(content: Content) -> some View {
        content
            .onAppear {
                MainActor.assumeIsolated {
                    Aware.shared.registerParameterizedGesture(viewId, type: .pinchIn) { params in
                        await onPinch(params.scale ?? 0.5)
                    }
                    Aware.shared.registerParameterizedGesture(viewId, type: .pinchOut) { params in
                        await onPinch(params.scale ?? 2.0)
                    }
                }
            }
            .onDisappear {
                MainActor.assumeIsolated {
                    Aware.shared.unregisterGestures(viewId)
                }
            }
    }
}

// MARK: - Draggable Modifier

/// View modifier that registers drag/pan callbacks for LLM control
struct AwareDraggableModifier: ViewModifier {
    let viewId: String
    let onDrag: (CGPoint) async -> Void

    func body(content: Content) -> some View {
        content
            .onAppear {
                MainActor.assumeIsolated {
                    Aware.shared.registerParameterizedGesture(viewId, type: .pan) { params in
                        await onDrag(params.translation ?? .zero)
                    }
                    Aware.shared.registerParameterizedGesture(viewId, type: .drag) { params in
                        await onDrag(params.translation ?? .zero)
                    }
                }
            }
            .onDisappear {
                MainActor.assumeIsolated {
                    Aware.shared.unregisterGestures(viewId)
                }
            }
    }
}

// MARK: - Complete Gesture Modifier

/// View modifier that registers multiple gesture types at once
struct AwareGesturesModifier: ViewModifier {
    let viewId: String
    let onTap: (() async -> Void)?
    let onLongPress: (() async -> Void)?
    let onDoubleTap: (() async -> Void)?
    let onSwipe: ((AwareSwipeDirection) async -> Void)?

    func body(content: Content) -> some View {
        content
            .onAppear {
                MainActor.assumeIsolated {
                    if let onTap = onTap {
                        Aware.shared.registerAction(viewId, callback: onTap)
                    }

                    if let onLongPress = onLongPress {
                        Aware.shared.registerGesture(viewId, type: .longPress) {
                            await onLongPress()
                        }
                    }

                    if let onDoubleTap = onDoubleTap {
                        Aware.shared.registerGesture(viewId, type: .doubleTap) {
                            await onDoubleTap()
                        }
                    }

                    if let onSwipe = onSwipe {
                        for direction in [AwareSwipeDirection.up, .down, .left, .right] {
                            let gestureType: AwareGestureType
                            switch direction {
                            case .up: gestureType = .swipeUp
                            case .down: gestureType = .swipeDown
                            case .left: gestureType = .swipeLeft
                            case .right: gestureType = .swipeRight
                            }

                            let capturedDirection = direction
                            Aware.shared.registerGesture(viewId, type: gestureType) {
                                await onSwipe(capturedDirection)
                            }
                        }
                    }
                }
            }
            .onDisappear {
                MainActor.assumeIsolated {
                    Aware.shared.unregisterAction(viewId)
                    Aware.shared.unregisterGestures(viewId)
                }
            }
    }
}

// MARK: - View Extensions

public extension View {
    /// Register swipe gesture callbacks for LLM control
    /// - Parameters:
    ///   - id: View identifier
    ///   - directions: Set of directions to register (default: all four)
    ///   - onSwipe: Callback when swipe gesture is triggered
    func awareSwipeable(
        _ id: String,
        directions: Set<AwareSwipeDirection> = [.up, .down, .left, .right],
        onSwipe: @escaping (AwareSwipeDirection) async -> Void
    ) -> some View {
        modifier(AwareSwipeableModifier(viewId: id, directions: directions, onSwipe: onSwipe))
    }

    /// Register long press callback for LLM control
    /// - Parameters:
    ///   - id: View identifier
    ///   - action: Callback when long press is triggered
    func awareLongPressable(
        _ id: String,
        action: @escaping () async -> Void
    ) -> some View {
        modifier(AwareLongPressableModifier(viewId: id, onLongPress: action))
    }

    /// Register double tap callback for LLM control
    /// - Parameters:
    ///   - id: View identifier
    ///   - action: Callback when double tap is triggered
    func awareDoubleTappable(
        _ id: String,
        action: @escaping () async -> Void
    ) -> some View {
        modifier(AwareDoubleTappableModifier(viewId: id, onDoubleTap: action))
    }

    /// Register pinch callbacks for LLM control
    /// - Parameters:
    ///   - id: View identifier
    ///   - onPinch: Callback with scale factor (< 1 for pinch in, > 1 for pinch out)
    func awarePinchable(
        _ id: String,
        onPinch: @escaping (CGFloat) async -> Void
    ) -> some View {
        modifier(AwarePinchableModifier(viewId: id, onPinch: onPinch))
    }

    /// Register drag/pan callbacks for LLM control
    /// - Parameters:
    ///   - id: View identifier
    ///   - onDrag: Callback with translation point
    func awareDraggable(
        _ id: String,
        onDrag: @escaping (CGPoint) async -> Void
    ) -> some View {
        modifier(AwareDraggableModifier(viewId: id, onDrag: onDrag))
    }

    /// Register multiple gesture callbacks at once for LLM control
    /// - Parameters:
    ///   - id: View identifier
    ///   - onTap: Optional tap callback
    ///   - onLongPress: Optional long press callback
    ///   - onDoubleTap: Optional double tap callback
    ///   - onSwipe: Optional swipe callback (all directions)
    func awareGestures(
        _ id: String,
        onTap: (() async -> Void)? = nil,
        onLongPress: (() async -> Void)? = nil,
        onDoubleTap: (() async -> Void)? = nil,
        onSwipe: ((AwareSwipeDirection) async -> Void)? = nil
    ) -> some View {
        modifier(AwareGesturesModifier(
            viewId: id,
            onTap: onTap,
            onLongPress: onLongPress,
            onDoubleTap: onDoubleTap,
            onSwipe: onSwipe
        ))
    }
}
