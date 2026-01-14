//
//  AwareLLMSnapshot.swift
//  AwareCore
//
//  LLM-optimized snapshot format for AI-driven UI testing.
//  Self-describing, intent-aware, actionable.
//

import Foundation

// MARK: - Root Snapshot

/// LLM-optimized snapshot containing full UI state with guidance
public struct AwareLLMSnapshot: Codable, Sendable {
    public let view: ViewDescriptor
    public let meta: SnapshotMeta

    public init(view: ViewDescriptor, meta: SnapshotMeta) {
        self.view = view
        self.meta = meta
    }
}

// MARK: - View Descriptor

/// Complete view description with intent and guidance
public struct ViewDescriptor: Codable, Sendable {
    // Identity
    public let id: String
    public let type: String

    // Semantics
    public let intent: String
    public let state: ViewState

    // Hierarchy
    public let elements: [ElementDescriptor]

    // LLM Guidance
    public let testSuggestions: [String]
    public let commonErrors: [String]?

    // Navigation
    public let canNavigateBack: Bool?
    public let previousView: String?
    public let modalPresentation: Bool?

    public init(
        id: String,
        type: String,
        intent: String,
        state: ViewState,
        elements: [ElementDescriptor],
        testSuggestions: [String],
        commonErrors: [String]? = nil,
        canNavigateBack: Bool? = nil,
        previousView: String? = nil,
        modalPresentation: Bool? = nil
    ) {
        self.id = id
        self.type = type
        self.intent = intent
        self.state = state
        self.elements = elements
        self.testSuggestions = testSuggestions
        self.commonErrors = commonErrors
        self.canNavigateBack = canNavigateBack
        self.previousView = previousView
        self.modalPresentation = modalPresentation
    }
}

/// View state for LLM understanding
public enum ViewState: String, Codable, Sendable {
    case ready      // Ready for interaction
    case loading    // Waiting for data/action
    case error      // Error state
    case success    // Action succeeded
    case disabled   // Interaction disabled
}

// MARK: - Element Descriptor

/// Complete element description with validation and guidance
public struct ElementDescriptor: Codable, Sendable {
    // Identity
    public let id: String
    public let type: ElementType
    public let label: String

    // Current State
    public let value: String
    public let state: ElementState
    public let enabled: Bool
    public let visible: Bool
    public let focused: Bool?

    // Validation
    public let required: Bool?
    public let validation: String?
    public let errorMessage: String?
    public let placeholder: String?

    // LLM Guidance
    public let nextAction: String
    public let exampleValue: String?

    // Behavior (for buttons/actions)
    public let action: String?
    public let nextView: String?
    public let failureView: String?
    public let dependencies: [String]?

    // Accessibility
    public let accessibilityLabel: String?
    public let accessibilityHint: String?

    // Position (optional)
    public let frame: FrameDescriptor?

    public init(
        id: String,
        type: ElementType,
        label: String,
        value: String,
        state: ElementState,
        enabled: Bool,
        visible: Bool,
        focused: Bool? = nil,
        required: Bool? = nil,
        validation: String? = nil,
        errorMessage: String? = nil,
        placeholder: String? = nil,
        nextAction: String,
        exampleValue: String? = nil,
        action: String? = nil,
        nextView: String? = nil,
        failureView: String? = nil,
        dependencies: [String]? = nil,
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        frame: FrameDescriptor? = nil
    ) {
        self.id = id
        self.type = type
        self.label = label
        self.value = value
        self.state = state
        self.enabled = enabled
        self.visible = visible
        self.focused = focused
        self.required = required
        self.validation = validation
        self.errorMessage = errorMessage
        self.placeholder = placeholder
        self.nextAction = nextAction
        self.exampleValue = exampleValue
        self.action = action
        self.nextView = nextView
        self.failureView = failureView
        self.dependencies = dependencies
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.frame = frame
    }
}

/// Element types understood by LLMs
public enum ElementType: String, Codable, Sendable {
    case textField = "TextField"
    case secureField = "SecureField"
    case button = "Button"
    case toggle = "Toggle"
    case picker = "Picker"
    case slider = "Slider"
    case text = "Text"
    case image = "Image"
    case link = "Link"
    case container = "Container"
    case list = "List"
    case navigationBar = "NavigationBar"
    case tabBar = "TabBar"
    case activityIndicator = "ActivityIndicator"
}

/// Element state for LLM understanding
public enum ElementState: String, Codable, Sendable {
    case empty      // No value
    case filled     // Has value
    case valid      // Value passes validation
    case invalid    // Value fails validation
    case focused    // Currently focused
    case disabled   // Interaction disabled
    case loading    // Action in progress
    case error      // Error occurred
}

/// Frame information (optional)
public struct FrameDescriptor: Codable, Sendable {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

// MARK: - Snapshot Metadata

/// Metadata about the snapshot
public struct SnapshotMeta: Codable, Sendable {
    public let timestamp: String
    public let tokenCount: Int
    public let format: String
    public let version: String
    public let app: String?
    public let device: String?

    public init(
        timestamp: String,
        tokenCount: Int,
        format: String = "llm",
        version: String = "1.0.0",
        app: String? = nil,
        device: String? = nil
    ) {
        self.timestamp = timestamp
        self.tokenCount = tokenCount
        self.format = format
        self.version = version
        self.app = app
        self.device = device
    }
}

// MARK: - Encoding Extensions

extension AwareLLMSnapshot {
    /// Encode to pretty-printed JSON string
    public func toJSON() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self)
        guard let json = String(data: data, encoding: .utf8) else {
            throw AwareError.snapshotGenerationFailed(
                reason: "Failed to encode snapshot to UTF-8",
                format: "llm"
            )
        }
        return json
    }

    /// Calculate approximate token count (chars / 4)
    public func estimateTokens() -> Int {
        guard let json = try? self.toJSON() else { return 0 }
        return json.count / 4
    }
}

// MARK: - Helper Extensions

extension ElementType {
    /// Initialize from string with fallback
    public init(from string: String) {
        switch string.lowercased() {
        case "textfield": self = .textField
        case "securefield": self = .secureField
        case "button": self = .button
        case "toggle": self = .toggle
        case "picker": self = .picker
        case "slider": self = .slider
        case "text": self = .text
        case "image": self = .image
        case "link": self = .link
        case "list": self = .list
        case "navigationbar": self = .navigationBar
        case "tabbar": self = .tabBar
        case "activityindicator": self = .activityIndicator
        default: self = .container
        }
    }
}
