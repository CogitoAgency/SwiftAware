//
//  AwareIOSModifiers.swift
//  AwareiOS
//
//  iOS-specific SwiftUI modifiers for enhanced LLM UI awareness.
//  Based on AetherSing's UIAware modifier system.
//
//  Provides specialized modifiers for different iOS view types.
//  Note: Requires AwareCore API extensions (registerView with type enum, addMetadata, etc.)
//

#if os(iOS)
import SwiftUI
import AwareCore

// MARK: - iOS-Specific View Modifiers

extension View {
    /// Enhanced button modifier with action callback registration
    /// - Parameters:
    ///   - id: Unique identifier for the view
    ///   - label: Human-readable label
    ///   - action: Action to execute on tap (enables ghost UI testing)
    /// - Returns: Modified view
    public func uiButton(
        _ id: String,
        label: String,
        action: (@Sendable @MainActor () async -> Void)? = nil
    ) -> some View {
        self.modifier(UIButtonModifier(id: id, label: label, action: action))
    }

    /// Enhanced text field modifier with focus tracking
    /// - Parameters:
    ///   - id: Unique identifier for the view
    ///   - text: Binding to the text value
    ///   - label: Human-readable label
    ///   - placeholder: Placeholder text
    ///   - isFocused: Optional binding for focus state
    /// - Returns: Modified view
    public func uiTextField(
        _ id: String,
        text: Binding<String>,
        label: String,
        placeholder: String? = nil,
        isFocused: Binding<Bool>? = nil
    ) -> some View {
        self.modifier(UITextFieldModifier(
            id: id,
            text: text,
            label: label,
            placeholder: placeholder,
            isFocused: isFocused
        ))
    }

    /// Enhanced secure field modifier
    /// - Parameters:
    ///   - id: Unique identifier for the view
    ///   - text: Binding to the text value
    ///   - label: Human-readable label
    ///   - placeholder: Placeholder text
    /// - Returns: Modified view
    public func uiSecureField(
        _ id: String,
        text: Binding<String>,
        label: String,
        placeholder: String? = nil
    ) -> some View {
        self.modifier(UISecureFieldModifier(
            id: id,
            text: text,
            label: label,
            placeholder: placeholder
        ))
    }

    /// Enhanced toggle modifier with state tracking
    /// - Parameters:
    ///   - id: Unique identifier for the view
    ///   - isOn: Binding to the toggle state
    ///   - label: Human-readable label
    /// - Returns: Modified view
    public func uiToggle(
        _ id: String,
        isOn: Binding<Bool>,
        label: String
    ) -> some View {
        self.modifier(UIToggleModifier(
            id: id,
            isOn: isOn,
            label: label
        ))
    }

    /// Enhanced picker modifier with selection tracking
    /// - Parameters:
    ///   - id: Unique identifier for the view
    ///   - selection: Binding to the selected value
    ///   - label: Human-readable label
    ///   - options: Array of selectable options
    /// - Returns: Modified view
    public func uiPicker<T: Hashable>(
        _ id: String,
        selection: Binding<T>,
        label: String,
        options: [T]
    ) -> some View {
        self.modifier(UIPickerModifier(
            id: id,
            selection: selection,
            label: label,
            options: options
        ))
    }

    /// Enhanced slider modifier with value tracking
    /// - Parameters:
    ///   - id: Unique identifier for the view
    ///   - value: Binding to the slider value
    ///   - range: Closed range for the slider
    ///   - label: Human-readable label
    /// - Returns: Modified view
    public func uiSlider(
        _ id: String,
        value: Binding<Double>,
        in range: ClosedRange<Double> = 0...1,
        label: String
    ) -> some View {
        self.modifier(UISliderModifier(
            id: id,
            value: value,
            range: range,
            label: label
        ))
    }
}

// MARK: - Button Modifier

struct UIButtonModifier: ViewModifier {
    let id: String
    let label: String
    let action: (@Sendable @MainActor () async -> Void)?

    @State private var frame: CGRect = .zero

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            frame = geo.frame(in: .global)
                            registerButton()
                        }
                        .onChange(of: geo.frame(in: .global)) { _, newFrame in
                            frame = newFrame
                            updateFrame()
                        }
                }
            )
            .onDisappear {
                Task { @MainActor in
                    await Aware.shared.unregisterView(id)
                }
            }
    }

    private func registerButton() {
        Task { @MainActor in
            // Register with main Aware service
            await Aware.shared.registerView(id, label: label, isContainer: false, parentId: nil)

            // Register action callback for ghost UI testing
            if let action = action {
                AwareIOSPlatform.shared.registerAction(id, callback: action)
            }

            // Add state tracking
            await Aware.shared.registerState(id, key: "type", value: "button")
            await Aware.shared.registerState(id, key: "actionable", value: "true")
            if action != nil {
                await Aware.shared.registerState(id, key: "hasCallback", value: "true")
            }
        }
    }

    private func updateFrame() {
        Task { @MainActor in
            // TODO: Add updateFrame method to Aware service
            // Aware.shared.updateFrame(id, frame: frame)
        }
    }
}

// MARK: - Text Field Modifier

struct UITextFieldModifier: ViewModifier {
    let id: String
    let text: Binding<String>
    let label: String
    let placeholder: String?
    let isFocused: Binding<Bool>?

    @State private var frame: CGRect = .zero
    @FocusState private var focused: Bool

    init(
        id: String,
        text: Binding<String>,
        label: String,
        placeholder: String?,
        isFocused: Binding<Bool>?
    ) {
        self.id = id
        self.text = text
        self.label = label
        self.placeholder = placeholder
        self.isFocused = isFocused
        if let isFocused = isFocused {
            self._focused = FocusState(initialValue: isFocused.wrappedValue)
        }
    }

    func body(content: Content) -> some View {
        content
            .focused($focused)
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            frame = geo.frame(in: .global)
                            registerTextField()
                        }
                        .onChange(of: geo.frame(in: .global)) { _, newFrame in
                            frame = newFrame
                        }
                }
            )
            .onChange(of: text.wrappedValue) { _, newValue in
                updateTextState(newValue)
            }
            .onChange(of: focused) { _, newValue in
                updateFocusState(newValue)
                isFocused?.wrappedValue = newValue
            }
            .onDisappear {
                Task { @MainActor in
                    await Aware.shared.unregisterView(id)
                }
            }
    }

    private func registerTextField() {
        Task { @MainActor in
            await Aware.shared.registerView(id, label: label, isContainer: false, parentId: nil)

            await Aware.shared.registerState(id, key: "text", value: text.wrappedValue)
            await Aware.shared.registerState(id, key: "isEmpty", value: String(text.wrappedValue.isEmpty))
            await Aware.shared.registerState(id, key: "charCount", value: String(text.wrappedValue.count))
            await Aware.shared.registerState(id, key: "isFocused", value: String(focused))
            await Aware.shared.registerState(id, key: "type", value: "textField")

            if let placeholder = placeholder {
                await Aware.shared.registerState(id, key: "placeholder", value: placeholder)
            }
        }
    }

    private func updateTextState(_ newValue: String) {
        Task { @MainActor in
            await Aware.shared.registerState(id, key: "text", value: newValue)
            await Aware.shared.registerState(id, key: "isEmpty", value: String(newValue.isEmpty))
            await Aware.shared.registerState(id, key: "charCount", value: String(newValue.count))
        }
    }

    private func updateFocusState(_ newValue: Bool) {
        Task { @MainActor in
            await Aware.shared.registerState(id, key: "isFocused", value: String(newValue))
        }
    }
}

// MARK: - Secure Field Modifier

struct UISecureFieldModifier: ViewModifier {
    let id: String
    let text: Binding<String>
    let label: String
    let placeholder: String?

    @State private var frame: CGRect = .zero

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            frame = geo.frame(in: .global)
                            registerSecureField()
                        }
                }
            )
            .onChange(of: text.wrappedValue) { _, newValue in
                updateTextState(newValue)
            }
            .onDisappear {
                Task { @MainActor in
                    await Aware.shared.unregisterView(id)
                }
            }
    }

    private func registerSecureField() {
        Task { @MainActor in
            await Aware.shared.registerView(id, label: label, isContainer: false, parentId: nil)

            await Aware.shared.registerState(id, key: "isEmpty", value: String(text.wrappedValue.isEmpty))
            await Aware.shared.registerState(id, key: "charCount", value: String(text.wrappedValue.count))
            await Aware.shared.registerState(id, key: "type", value: "secureField")
            await Aware.shared.registerState(id, key: "secure", value: "true")

            if let placeholder = placeholder {
                await Aware.shared.registerState(id, key: "placeholder", value: placeholder)
            }
        }
    }

    private func updateTextState(_ newValue: String) {
        Task { @MainActor in
            await Aware.shared.registerState(id, key: "isEmpty", value: String(newValue.isEmpty))
            await Aware.shared.registerState(id, key: "charCount", value: String(newValue.count))
        }
    }
}

// MARK: - Toggle Modifier

struct UIToggleModifier: ViewModifier {
    let id: String
    let isOn: Binding<Bool>
    let label: String

    @State private var frame: CGRect = .zero

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            frame = geo.frame(in: .global)
                            registerToggle()
                        }
                }
            )
            .onChange(of: isOn.wrappedValue) { _, newValue in
                updateToggleState(newValue)
            }
            .onDisappear {
                Task { @MainActor in
                    await Aware.shared.unregisterView(id)
                }
            }
    }

    private func registerToggle() {
        Task { @MainActor in
            await Aware.shared.registerView(id, label: label, isContainer: false, parentId: nil)

            await Aware.shared.registerState(id, key: "isOn", value: String(isOn.wrappedValue))
            await Aware.shared.registerState(id, key: "type", value: "toggle")
        }
    }

    private func updateToggleState(_ newValue: Bool) {
        Task { @MainActor in
            await Aware.shared.registerState(id, key: "isOn", value: String(newValue))
        }
    }
}

// MARK: - Picker Modifier

struct UIPickerModifier<T: Hashable>: ViewModifier {
    let id: String
    let selection: Binding<T>
    let label: String
    let options: [T]

    @State private var frame: CGRect = .zero

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            frame = geo.frame(in: .global)
                            registerPicker()
                        }
                }
            )
            .onChange(of: selection.wrappedValue) { _, newValue in
                updateSelectionState(newValue)
            }
            .onDisappear {
                Task { @MainActor in
                    await Aware.shared.unregisterView(id)
                }
            }
    }

    private func registerPicker() {
        Task { @MainActor in
            await Aware.shared.registerView(id, label: label, isContainer: false, parentId: nil)

            let index = options.firstIndex(of: selection.wrappedValue) ?? 0
            await Aware.shared.registerState(id, key: "selection", value: String(describing: selection.wrappedValue))
            await Aware.shared.registerState(id, key: "selectedIndex", value: String(index))
            await Aware.shared.registerState(id, key: "optionCount", value: String(options.count))
            await Aware.shared.registerState(id, key: "type", value: "picker")
            await Aware.shared.registerState(id, key: "options", value: options.map { String(describing: $0) }.joined(separator: ","))
        }
    }

    private func updateSelectionState(_ newValue: T) {
        Task { @MainActor in
            let index = options.firstIndex(of: newValue) ?? 0
            await Aware.shared.registerState(id, key: "selection", value: String(describing: newValue))
            await Aware.shared.registerState(id, key: "selectedIndex", value: String(index))
        }
    }
}

// MARK: - Slider Modifier

struct UISliderModifier: ViewModifier {
    let id: String
    let value: Binding<Double>
    let range: ClosedRange<Double>
    let label: String

    @State private var frame: CGRect = .zero

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            frame = geo.frame(in: .global)
                            registerSlider()
                        }
                }
            )
            .onChange(of: value.wrappedValue) { _, newValue in
                updateValueState(newValue)
            }
            .onDisappear {
                Task { @MainActor in
                    await Aware.shared.unregisterView(id)
                }
            }
    }

    private func registerSlider() {
        Task { @MainActor in
            await Aware.shared.registerView(id, label: label, isContainer: false, parentId: nil)

            let normalized = (value.wrappedValue - range.lowerBound) / (range.upperBound - range.lowerBound)
            await Aware.shared.registerState(id, key: "value", value: String(format: "%.2f", value.wrappedValue))
            await Aware.shared.registerState(id, key: "normalized", value: String(format: "%.2f", normalized))
            await Aware.shared.registerState(id, key: "min", value: String(format: "%.2f", range.lowerBound))
            await Aware.shared.registerState(id, key: "max", value: String(format: "%.2f", range.upperBound))
            await Aware.shared.registerState(id, key: "type", value: "slider")
        }
    }

    private func updateValueState(_ newValue: Double) {
        Task { @MainActor in
            let normalized = (newValue - range.lowerBound) / (range.upperBound - range.lowerBound)
            await Aware.shared.registerState(id, key: "value", value: String(format: "%.2f", newValue))
            await Aware.shared.registerState(id, key: "normalized", value: String(format: "%.2f", normalized))
        }
    }
}

#endif // os(iOS)
