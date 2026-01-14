//
//  CoreModifiersRegistry.swift
//  AwareCore
//
//  Registers core framework modifiers for API documentation.
//

import Foundation

// MARK: - Core Modifiers Registry

/// Registers core AwareCore modifiers
@MainActor
public struct CoreModifiersRegistry {

    /// Register all core modifiers
    public static func register() {
        let registry = AwareAPIRegistry.shared

        // Register core modifiers
        registry.registerModifier(awareModifier())
        registry.registerModifier(awareContainerModifier())
        registry.registerModifier(awareButtonModifier())
        registry.registerModifier(awareStateModifier())
        registry.registerModifier(awareTextModifier())

        // Register new enhanced modifiers
        registry.registerModifier(awareToggleModifier())
        registry.registerModifier(awareNavigationModifier())
        registry.registerModifier(awareAnimationModifier())
        registry.registerModifier(awareScrollModifier())
    }

    // MARK: - Modifier Definitions

    private static func awareModifier() -> ModifierMetadata {
        ModifierMetadata(
            name: ".aware",
            fullSignature: "aware(_ id: String, label: String? = nil, captureVisuals: Bool = true, parent: String? = nil)",
            parameters: [
                ParameterMetadata(
                    name: "id",
                    type: "String",
                    required: true,
                    description: "Unique view identifier for testing and snapshots"
                ),
                ParameterMetadata(
                    name: "label",
                    type: "String?",
                    required: false,
                    defaultValue: "nil",
                    description: "Human-readable label for the view"
                ),
                ParameterMetadata(
                    name: "captureVisuals",
                    type: "Bool",
                    required: false,
                    defaultValue: "true",
                    description: "Whether to capture visual properties (frame, opacity, etc.)"
                ),
                ParameterMetadata(
                    name: "parent",
                    type: "String?",
                    required: false,
                    defaultValue: "nil",
                    description: "Parent container ID for establishing view hierarchy"
                )
            ],
            returnType: "some View",
            platform: .all,
            category: .registration,
            description: "Register view for LLM introspection and testing with automatic visual capture",
            examples: [
                CodeExample(
                    code: """
                    Text("Hello, World!")
                        .aware("greeting-text", label: "Greeting")
                    """,
                    description: "Basic view registration"
                ),
                CodeExample(
                    code: """
                    VStack {
                        Text("Child View")
                            .aware("child", parent: "container")
                    }
                    .awareContainer("container", label: "Main Container")
                    """,
                    description: "Hierarchical view registration with parent"
                )
            ],
            tokenCost: 3,
            relatedModifiers: [".awareContainer", ".awareState"],
            since: "1.0.0",
            requiredParameters: ["id"],
            validationPattern: nil,  // Manual validation - check ID uniqueness
            commonMistakes: [
                CommonMistake(
                    pattern: #"\.aware\("[^"]*",\s*label:\s*"[^"]*",\s*captureVisuals:\s*false\)"#,
                    description: "captureVisuals: false may reduce snapshot quality",
                    severity: .info,
                    example: ".aware(\"view\", label: \"View\", captureVisuals: false)"
                )
            ],
            autoFixes: [
                AutoFix(
                    description: "Add .aware() modifier with unique ID",
                    codeTransform: "{ViewType}(...)\n  .aware(\"{id}\", label: \"{description}\")",
                    confidence: 0.85,
                    example: "Text(\"Hello\").aware(\"greeting\", label: \"Greeting\")"
                )
            ]
        )
    }

    private static func awareContainerModifier() -> ModifierMetadata {
        ModifierMetadata(
            name: ".awareContainer",
            fullSignature: "awareContainer(_ id: String, label: String? = nil, parent: String? = nil)",
            parameters: [
                ParameterMetadata(
                    name: "id",
                    type: "String",
                    required: true,
                    description: "Unique container identifier"
                ),
                ParameterMetadata(
                    name: "label",
                    type: "String?",
                    required: false,
                    defaultValue: "nil",
                    description: "Human-readable container label"
                ),
                ParameterMetadata(
                    name: "parent",
                    type: "String?",
                    required: false,
                    defaultValue: "nil",
                    description: "Parent container ID for nested hierarchies"
                )
            ],
            returnType: "some View",
            platform: .all,
            category: .registration,
            description: "Mark view as container for hierarchical snapshot capture and organization",
            examples: [
                CodeExample(
                    code: """
                    VStack {
                        Text("Item 1").aware("item1", parent: "list")
                        Text("Item 2").aware("item2", parent: "list")
                    }
                    .awareContainer("list", label: "Item List")
                    """,
                    description: "Container with child views"
                )
            ],
            tokenCost: 3,
            relatedModifiers: [".aware"],
            since: "1.0.0"
        )
    }

    private static func awareButtonModifier() -> ModifierMetadata {
        ModifierMetadata(
            name: ".awareButton",
            fullSignature: "awareButton(_ id: String, label: String, parent: String? = nil)",
            parameters: [
                ParameterMetadata(
                    name: "id",
                    type: "String",
                    required: true,
                    description: "Unique button identifier"
                ),
                ParameterMetadata(
                    name: "label",
                    type: "String",
                    required: true,
                    description: "Button label text for LLM understanding"
                ),
                ParameterMetadata(
                    name: "parent",
                    type: "String?",
                    required: false,
                    defaultValue: "nil",
                    description: "Parent container ID"
                )
            ],
            returnType: "some View",
            platform: .all,
            category: .action,
            description: "Register tappable button with automatic tap tracking for ghost UI testing",
            examples: [
                CodeExample(
                    code: """
                    Button("Sign In") { signIn() }
                        .awareButton("signin-btn", label: "Sign In")
                    """,
                    description: "Basic button registration"
                ),
                CodeExample(
                    code: """
                    Button("Save") { save() }
                        .awareButton("save-btn", label: "Save Document")
                        .awareMetadata(
                            "save-btn",
                            description: "Saves document to cloud",
                            type: .network
                        )
                    """,
                    description: "Button with action metadata"
                )
            ],
            tokenCost: 4,
            relatedModifiers: [".awareMetadata", ".awareTappable", ".awareAction"],
            since: "1.0.0",
            requiredParameters: ["id", "label"],
            validationPattern: #"Button\([^)]*\)(?=.*\.awareButton)"#,
            commonMistakes: [
                CommonMistake(
                    pattern: #"Button\([^)]*\)(?!.*\.awareButton)"#,
                    description: "Button missing .awareButton() modifier",
                    severity: .warning,
                    example: "Button(\"Tap\") { } // Missing .awareButton()"
                ),
                CommonMistake(
                    pattern: #"\.awareButton\([^,)]+\)"#,
                    description: "Button ID provided but label missing",
                    severity: .error,
                    example: ".awareButton(\"btn\") // Missing label parameter"
                )
            ],
            autoFixes: [
                AutoFix(
                    description: "Add .awareButton() modifier with ID and label",
                    codeTransform: "Button(\"{text}\") { {action} }\n  .awareButton(\"{id}\", label: \"{text}\")",
                    confidence: 0.9,
                    example: "Button(\"Save\") { save() }.awareButton(\"save-btn\", label: \"Save\")"
                )
            ]
        )
    }

    private static func awareStateModifier() -> ModifierMetadata {
        ModifierMetadata(
            name: ".awareState",
            fullSignature: "awareState<T>(_ viewId: String, key: String, value: T)",
            parameters: [
                ParameterMetadata(
                    name: "viewId",
                    type: "String",
                    required: true,
                    description: "View identifier to attach state to"
                ),
                ParameterMetadata(
                    name: "key",
                    type: "String",
                    required: true,
                    description: "State key name (e.g., 'isEnabled', 'count')"
                ),
                ParameterMetadata(
                    name: "value",
                    type: "T",
                    required: true,
                    description: "State value (any type - converted to String)"
                )
            ],
            returnType: "some View",
            platform: .all,
            category: .state,
            description: "Track arbitrary state values with automatic change detection for snapshots",
            examples: [
                CodeExample(
                    code: """
                    Toggle("Dark Mode", isOn: $isDarkMode)
                        .aware("darkmode-toggle", label: "Dark Mode Toggle")
                        .awareState("darkmode-toggle", key: "isOn", value: isDarkMode)
                    """,
                    description: "Track toggle state"
                ),
                CodeExample(
                    code: """
                    Text("Count: \\(count)")
                        .aware("counter", label: "Counter")
                        .awareState("counter", key: "value", value: count)
                    """,
                    description: "Track numeric state"
                )
            ],
            tokenCost: 4,
            relatedModifiers: [".aware"],
            since: "1.0.0"
        )
    }

    private static func awareTextModifier() -> ModifierMetadata {
        ModifierMetadata(
            name: ".awareText",
            fullSignature: "awareText(_ id: String, text: String, parent: String? = nil)",
            parameters: [
                ParameterMetadata(
                    name: "id",
                    type: "String",
                    required: true,
                    description: "Unique text view identifier"
                ),
                ParameterMetadata(
                    name: "text",
                    type: "String",
                    required: true,
                    description: "Text content to track"
                ),
                ParameterMetadata(
                    name: "parent",
                    type: "String?",
                    required: false,
                    defaultValue: "nil",
                    description: "Parent container ID"
                )
            ],
            returnType: "some View",
            platform: .all,
            category: .state,
            description: "Track text content with automatic change detection for content verification",
            examples: [
                CodeExample(
                    code: """
                    Text(displayName)
                        .awareText("username", text: displayName)
                    """,
                    description: "Track dynamic text content"
                )
            ],
            tokenCost: 3,
            relatedModifiers: [".aware", ".awareTextField"],
            since: "1.0.0"
        )
    }

    // MARK: - Enhanced Modifiers (v3.1+)

    private static func awareToggleModifier() -> ModifierMetadata {
        ModifierMetadata(
            name: ".awareToggle",
            fullSignature: "awareToggle(_ id: String, isOn: Binding<Bool>, label: String?)",
            parameters: [
                ParameterMetadata(
                    name: "id",
                    type: "String",
                    required: true,
                    description: "Unique toggle identifier"
                ),
                ParameterMetadata(
                    name: "isOn",
                    type: "Binding<Bool>",
                    required: true,
                    description: "Binding to track toggle state"
                ),
                ParameterMetadata(
                    name: "label",
                    type: "String?",
                    required: false,
                    defaultValue: "nil",
                    description: "Human-readable label for the toggle"
                )
            ],
            returnType: "some View",
            platform: .all,
            category: .action,
            description: "Register toggle with automatic state tracking for on/off testing",
            examples: [
                CodeExample(
                    code: """
                    Toggle("Dark Mode", isOn: $isDarkMode)
                        .awareToggle("dark-mode-toggle", isOn: $isDarkMode, label: "Dark Mode")
                    """,
                    description: "Basic toggle with state tracking"
                ),
                CodeExample(
                    code: """
                    Toggle("Notifications", isOn: $notificationsEnabled)
                        .awareToggle("notifications-toggle", isOn: $notificationsEnabled, label: "Enable Notifications")
                        .awareMetadata("notifications-toggle", description: "Enables push notifications", type: .preference)
                    """,
                    description: "Toggle with metadata for settings"
                )
            ],
            tokenCost: 4,
            relatedModifiers: [".awareState", ".awareMetadata"],
            since: "3.1.0",
            requiredParameters: ["id", "isOn"],
            validationPattern: #"Toggle\([^)]*\)(?=.*\.awareToggle)"#,
            commonMistakes: [
                CommonMistake(
                    pattern: #"Toggle\([^)]*\)(?!.*\.awareToggle)"#,
                    description: "Toggle missing .awareToggle() modifier",
                    severity: .warning,
                    example: "Toggle(\"Enable\", isOn: $enabled) // Missing .awareToggle()"
                )
            ],
            autoFixes: [
                AutoFix(
                    description: "Add .awareToggle() modifier with ID and binding",
                    codeTransform: "Toggle(\"{text}\", isOn: $binding)\n  .awareToggle(\"{id}\", isOn: $binding, label: \"{text}\")",
                    confidence: 0.85,
                    example: "Toggle(\"Dark Mode\", isOn: $dark).awareToggle(\"dark-toggle\", isOn: $dark, label: \"Dark Mode\")"
                )
            ]
        )
    }

    private static func awareNavigationModifier() -> ModifierMetadata {
        ModifierMetadata(
            name: ".awareNavigation",
            fullSignature: "awareNavigation(_ id: String, destination: String?, isActive: Bool = false)",
            parameters: [
                ParameterMetadata(
                    name: "id",
                    type: "String",
                    required: true,
                    description: "Unique navigation identifier"
                ),
                ParameterMetadata(
                    name: "destination",
                    type: "String?",
                    required: false,
                    defaultValue: "nil",
                    description: "Target view or route identifier"
                ),
                ParameterMetadata(
                    name: "isActive",
                    type: "Bool",
                    required: false,
                    defaultValue: "false",
                    description: "Whether navigation is currently active"
                )
            ],
            returnType: "some View",
            platform: .all,
            category: .navigation,
            description: "Track navigation actions and state for multi-screen testing",
            examples: [
                CodeExample(
                    code: """
                    NavigationLink("Settings", destination: SettingsView())
                        .awareNavigation("settings-link", destination: "SettingsView")
                    """,
                    description: "Basic navigation link tracking"
                ),
                CodeExample(
                    code: """
                    Button("Login") { showLogin = true }
                        .awareButton("login-btn", label: "Login")
                        .awareNavigation("login-nav", destination: "LoginView", isActive: showLogin)
                    """,
                    description: "Programmatic navigation with state"
                )
            ],
            tokenCost: 4,
            relatedModifiers: [".awareButton", ".awareContainer"],
            since: "3.1.0",
            requiredParameters: ["id"]
        )
    }

    private static func awareAnimationModifier() -> ModifierMetadata {
        ModifierMetadata(
            name: ".awareAnimation",
            fullSignature: "awareAnimation(_ id: String, type: String? = nil, duration: Double? = nil, isAnimating: Binding<Bool>? = nil)",
            parameters: [
                ParameterMetadata(
                    name: "id",
                    type: "String",
                    required: true,
                    description: "Unique animation identifier"
                ),
                ParameterMetadata(
                    name: "type",
                    type: "String?",
                    required: false,
                    defaultValue: "nil",
                    description: "Animation type (e.g., 'spring', 'easeIn', 'linear')"
                ),
                ParameterMetadata(
                    name: "duration",
                    type: "Double?",
                    required: false,
                    defaultValue: "nil",
                    description: "Animation duration in seconds"
                ),
                ParameterMetadata(
                    name: "isAnimating",
                    type: "Binding<Bool>?",
                    required: false,
                    defaultValue: "nil",
                    description: "Binding to track animation state"
                )
            ],
            returnType: "some View",
            platform: .all,
            category: .animation,
            description: "Track animation state and timing for testing animated transitions",
            examples: [
                CodeExample(
                    code: """
                    Circle()
                        .aware("loading-spinner", label: "Loading Indicator")
                        .awareAnimation("spinner-anim", type: "rotation", duration: 1.0, isAnimating: $isLoading)
                    """,
                    description: "Track loading animation state"
                ),
                CodeExample(
                    code: """
                    VStack {
                        // Content
                    }
                    .awareContainer("modal", label: "Modal Dialog")
                    .awareAnimation("modal-slide", type: "slide", duration: 0.3)
                    """,
                    description: "Track modal slide animation"
                )
            ],
            tokenCost: 5,
            relatedModifiers: [".aware", ".awareState"],
            since: "3.1.0",
            requiredParameters: ["id"]
        )
    }

    private static func awareScrollModifier() -> ModifierMetadata {
        ModifierMetadata(
            name: ".awareScroll",
            fullSignature: "awareScroll(_ id: String, position: Binding<CGPoint>? = nil, isScrolling: Binding<Bool>? = nil)",
            parameters: [
                ParameterMetadata(
                    name: "id",
                    type: "String",
                    required: true,
                    description: "Unique scroll view identifier"
                ),
                ParameterMetadata(
                    name: "position",
                    type: "Binding<CGPoint>?",
                    required: false,
                    defaultValue: "nil",
                    description: "Binding to track scroll position (x, y coordinates)"
                ),
                ParameterMetadata(
                    name: "isScrolling",
                    type: "Binding<Bool>?",
                    required: false,
                    defaultValue: "nil",
                    description: "Binding to track whether actively scrolling"
                )
            ],
            returnType: "some View",
            platform: .all,
            category: .scroll,
            description: "Track scroll position and state for testing scrollable content",
            examples: [
                CodeExample(
                    code: """
                    ScrollView {
                        // Content
                    }
                    .awareScroll("main-scroll", position: $scrollPosition, isScrolling: $isScrolling)
                    """,
                    description: "Track scroll position and state"
                ),
                CodeExample(
                    code: """
                    List(items) { item in
                        ItemRow(item: item)
                    }
                    .awareContainer("items-list", label: "Items List")
                    .awareScroll("items-scroll")
                    """,
                    description: "Track list scrolling"
                )
            ],
            tokenCost: 4,
            relatedModifiers: [".awareContainer", ".awareState"],
            since: "3.1.0",
            requiredParameters: ["id"]
        )
    }
}
