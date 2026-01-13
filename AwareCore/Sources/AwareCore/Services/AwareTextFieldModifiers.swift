//
//  AwareTextFieldModifiers.swift
//  Aware
//
//  View modifiers for text field binding registration.
//  Enables LLM control of text input through direct binding manipulation.
//

import SwiftUI

// MARK: - Text Binding Modifier

/// View modifier that registers a text binding for direct LLM text manipulation
struct AwareTextBindingModifier: ViewModifier {
    let viewId: String
    @Binding var text: String
    let label: String

    func body(content: Content) -> some View {
        content
            .onAppear {
                MainActor.assumeIsolated {
                    // Register text binding for direct manipulation
                    Aware.shared.registerTextBinding(
                        viewId,
                        binding: AwareTextBinding(
                            get: { text },
                            set: { text = $0 }
                        )
                    )

                    // Register state for snapshot visibility
                    Aware.shared.registerState(viewId, key: "value", value: text)
                    Aware.shared.registerState(viewId, key: "label", value: label)
                    Aware.shared.registerState(viewId, key: "type", value: "textField")
                }
            }
            .onChange(of: text) { _, newValue in
                MainActor.assumeIsolated {
                    Aware.shared.registerState(viewId, key: "value", value: newValue)
                }
            }
            .onDisappear {
                MainActor.assumeIsolated {
                    Aware.shared.unregisterTextBinding(viewId)
                    Aware.shared.clearState(viewId)
                }
            }
    }
}

// MARK: - Focusable Text Field Modifier

/// View modifier for text fields with focus management
struct AwareFocusableTextFieldModifier<FocusValue: Hashable>: ViewModifier {
    let viewId: String
    @Binding var text: String
    let label: String
    let focusBinding: FocusState<FocusValue>.Binding
    let focusValue: FocusValue
    let focusOrder: Int?

    func body(content: Content) -> some View {
        content
            .focused(focusBinding, equals: focusValue)
            .modifier(AwareTextBindingModifier(viewId: viewId, text: $text, label: label))
            .onAppear {
                MainActor.assumeIsolated {
                    // Register focus binding
                    let binding = Binding<Bool>(
                        get: { focusBinding.wrappedValue == focusValue },
                        set: { newValue in
                            if newValue {
                                focusBinding.wrappedValue = focusValue
                            } else if focusBinding.wrappedValue == focusValue {
                                // Can't directly unfocus with FocusState, but we track it
                            }
                        }
                    )
                    AwareFocusManager.shared.registerFocus(viewId, binding: binding, order: focusOrder)
                }
            }
            .onChange(of: focusBinding.wrappedValue) { _, newValue in
                MainActor.assumeIsolated {
                    let isFocused = newValue == focusValue
                    Aware.shared.updateFocusState(viewId, isFocused: isFocused)
                    AwareFocusManager.shared.notifyFocusChanged(viewId, isFocused: isFocused)
                }
            }
            .onDisappear {
                MainActor.assumeIsolated {
                    AwareFocusManager.shared.unregisterFocus(viewId)
                }
            }
    }
}

// MARK: - Simple Bool Focus Modifier

/// Simplified modifier for Bool-based focus state
struct AwareSimpleFocusTextFieldModifier: ViewModifier {
    let viewId: String
    @Binding var text: String
    let label: String
    @FocusState.Binding var isFocused: Bool
    let focusOrder: Int?

    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .modifier(AwareTextBindingModifier(viewId: viewId, text: $text, label: label))
            .onAppear {
                MainActor.assumeIsolated {
                    let binding = Binding<Bool>(
                        get: { isFocused },
                        set: { isFocused = $0 }
                    )
                    AwareFocusManager.shared.registerFocus(viewId, binding: binding, order: focusOrder)
                }
            }
            .onChange(of: isFocused) { _, newValue in
                MainActor.assumeIsolated {
                    Aware.shared.updateFocusState(viewId, isFocused: newValue)
                    AwareFocusManager.shared.notifyFocusChanged(viewId, isFocused: newValue)
                }
            }
            .onDisappear {
                MainActor.assumeIsolated {
                    AwareFocusManager.shared.unregisterFocus(viewId)
                }
            }
    }
}

// MARK: - Secure Text Field Modifier

/// View modifier for secure text fields (passwords)
struct AwareSecureFieldModifier: ViewModifier {
    let viewId: String
    @Binding var text: String
    let label: String

    func body(content: Content) -> some View {
        content
            .onAppear {
                MainActor.assumeIsolated {
                    // Register text binding
                    Aware.shared.registerTextBinding(
                        viewId,
                        binding: AwareTextBinding(
                            get: { text },
                            set: { text = $0 }
                        )
                    )

                    // Register state (without exposing actual value for security)
                    Aware.shared.registerState(viewId, key: "label", value: label)
                    Aware.shared.registerState(viewId, key: "type", value: "secureField")
                    Aware.shared.registerState(viewId, key: "hasValue", value: text.isEmpty ? "false" : "true")
                }
            }
            .onChange(of: text) { _, newValue in
                MainActor.assumeIsolated {
                    Aware.shared.registerState(viewId, key: "hasValue", value: newValue.isEmpty ? "false" : "true")
                }
            }
            .onDisappear {
                MainActor.assumeIsolated {
                    Aware.shared.unregisterTextBinding(viewId)
                    Aware.shared.clearState(viewId)
                }
            }
    }
}

// MARK: - View Extensions

public extension View {
    /// Register a text binding for direct LLM text manipulation
    /// - Parameters:
    ///   - id: View identifier
    ///   - text: Binding to the text value
    ///   - label: Human-readable label for the field
    func awareTextBinding(
        _ id: String,
        text: Binding<String>,
        label: String
    ) -> some View {
        modifier(AwareTextBindingModifier(viewId: id, text: text, label: label))
    }

    /// Complete text field registration with focus management (Bool focus)
    /// - Parameters:
    ///   - id: View identifier
    ///   - text: Binding to the text value
    ///   - label: Human-readable label for the field
    ///   - isFocused: Focus state binding
    ///   - focusOrder: Optional position in tab order
    func awareTextField(
        _ id: String,
        text: Binding<String>,
        label: String,
        isFocused: FocusState<Bool>.Binding,
        focusOrder: Int? = nil
    ) -> some View {
        modifier(AwareSimpleFocusTextFieldModifier(
            viewId: id,
            text: text,
            label: label,
            isFocused: isFocused,
            focusOrder: focusOrder
        ))
    }

    /// Complete text field registration with enum-based focus management
    /// - Parameters:
    ///   - id: View identifier
    ///   - text: Binding to the text value
    ///   - label: Human-readable label for the field
    ///   - focus: Focus state binding
    ///   - focusValue: The focus value that indicates this field is focused
    ///   - focusOrder: Optional position in tab order
    func awareTextField<FocusValue: Hashable>(
        _ id: String,
        text: Binding<String>,
        label: String,
        focus: FocusState<FocusValue>.Binding,
        equals focusValue: FocusValue,
        focusOrder: Int? = nil
    ) -> some View {
        modifier(AwareFocusableTextFieldModifier(
            viewId: id,
            text: text,
            label: label,
            focusBinding: focus,
            focusValue: focusValue,
            focusOrder: focusOrder
        ))
    }

    /// Register a secure text field for LLM control
    /// Note: The actual password value is not exposed in snapshots for security
    /// - Parameters:
    ///   - id: View identifier
    ///   - text: Binding to the password value
    ///   - label: Human-readable label for the field
    func awareSecureField(
        _ id: String,
        text: Binding<String>,
        label: String
    ) -> some View {
        modifier(AwareSecureFieldModifier(viewId: id, text: text, label: label))
    }
}
