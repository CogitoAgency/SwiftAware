//
//  BreatheMCPAdapter.swift
//  AwareBridge
//
//  High-level adapter for Breathe IDE integration with Aware apps.
//  Provides MCP tool implementations (ui_snapshot, ui_action, ui_wait, etc.)
//

import Foundation
import AwareCore

// MARK: - Breathe MCP Adapter

/// Adapter for Breathe IDE MCP tools
@MainActor
public final class BreatheMCPAdapter: @unchecked Sendable {
    // MARK: - Singleton

    public static let shared = BreatheMCPAdapter()

    // MARK: - Dependencies

    private let bridge: WebSocketBridge
    private var pendingResults: [String: CheckedContinuation<AwareMCPResult, Never>] = [:]

    // MARK: - Initialization

    private init(bridge: WebSocketBridge = .shared) {
        self.bridge = bridge

        // Register handlers
        bridge.onCommand { [weak self] command in
            await self?.handleCommand(command) ?? AwareMCPResult.failure(
                commandId: command.id,
                error: AwareMCPError(code: "ADAPTER_ERROR", message: "Adapter not available")
            )
        }

        bridge.onBatch { [weak self] batch in
            await self?.handleBatch(batch) ?? MCPBatchResult(
                batchId: batch.id,
                results: batch.commands.map { cmd in
                    AwareMCPResult.failure(commandId: cmd.id, error: AwareMCPError(code: "ADAPTER_ERROR", message: "Adapter not available"))
                }
            )
        }
    }

    // MARK: - Lifecycle

    /// Start adapter (starts WebSocket server)
    public func start() async throws {
        try await bridge.start()
    }

    /// Stop adapter
    public func stop() async {
        await bridge.stop()
    }

    // MARK: - MCP Tool Implementations

    /// ui_snapshot - Get current UI state
    public func snapshot(format: AwareSnapshotFormat = .compact) async -> String {
        let command = MCPCommand(action: .snapshot, parameters: ["format": format.rawValue])
        let result = await executeCommand(command)

        if result.success, let snapshot = result.data?["snapshot"] {
            return snapshot
        }

        return "Error: \(result.error?.message ?? "Unknown error")"
    }

    /// ui_action - Perform UI action (tap, type, swipe, etc.)
    public func action(type: String, viewId: String, parameters: [String: String] = [:]) async -> Bool {
        var params = parameters
        params["viewId"] = viewId

        let action: MCPAction
        switch type.lowercased() {
        case "tap": action = .tap
        case "type": action = .type
        case "swipe": action = .swipe
        case "scroll": action = .scroll
        case "longpress": action = .longPress
        case "doubletap": action = .doubleTap
        default: return false
        }

        let command = MCPCommand(action: action, parameters: params)
        let result = await executeCommand(command)
        return result.success
    }

    /// ui_find - Find element by criteria
    public func find(label: String? = nil, type: String? = nil, state: [String: String]? = nil) async -> [String] {
        var parameters: [String: String] = [:]
        if let label = label { parameters["label"] = label }
        if let type = type { parameters["type"] = type }
        if let state = state {
            // Encode state as JSON string
            if let data = try? JSONSerialization.data(withJSONObject: state),
               let stateJson = String(data: data, encoding: .utf8) {
                parameters["state"] = stateJson
            }
        }

        let command = MCPCommand(action: .find, parameters: parameters)
        let result = await executeCommand(command)

        if result.success, let viewIds = result.data?["viewIds"] {
            return viewIds.split(separator: ",").map(String.init)
        }

        return []
    }

    /// ui_wait - Wait for condition
    public func wait(viewId: String, stateKey: String, expectedValue: String, timeout: TimeInterval = 5.0) async -> Bool {
        let parameters: [String: String] = [
            "viewId": viewId,
            "stateKey": stateKey,
            "expectedValue": expectedValue,
            "timeout": "\(timeout)"
        ]

        let command = MCPCommand(action: .wait, parameters: parameters)
        let result = await executeCommand(command)
        return result.success
    }

    /// ui_assert - Assert condition
    public func assert(viewId: String, condition: String, expectedValue: String) async -> Bool {
        let parameters: [String: String] = [
            "viewId": viewId,
            "condition": condition,
            "expectedValue": expectedValue
        ]

        let command = MCPCommand(action: .assert, parameters: parameters)
        let result = await executeCommand(command)
        return result.success
    }

    /// ui_test - Run batch test
    public func test(commands: [(action: String, viewId: String, parameters: [String: String])]) async -> Bool {
        let mcpCommands = commands.map { cmd -> MCPCommand in
            var params = cmd.parameters
            params["viewId"] = cmd.viewId

            let action: MCPAction
            switch cmd.action.lowercased() {
            case "tap": action = .tap
            case "type": action = .type
            case "wait": action = .wait
            case "assert": action = .assert
            default: action = .tap
            }

            return MCPCommand(action: action, parameters: params)
        }

        let batch = MCPBatch(commands: mcpCommands, atomic: true)
        let result = await executeBatch(batch)
        return result.allSucceeded
    }

    // MARK: - Focus Management

    /// Focus specific element
    public func focus(viewId: String) async -> Bool {
        let command = MCPCommand(action: .focus, parameters: ["viewId": viewId])
        let result = await executeCommand(command)
        return result.success
    }

    /// Tab to next field
    public func focusNext() async -> Bool {
        let command = MCPCommand(action: .focusNext)
        let result = await executeCommand(command)
        return result.success
    }

    /// Shift+Tab to previous field
    public func focusPrevious() async -> Bool {
        let command = MCPCommand(action: .focusPrevious)
        let result = await executeCommand(command)
        return result.success
    }

    // MARK: - Health

    /// Ping server
    public func ping() async -> Bool {
        let command = MCPCommand(action: .ping)
        let result = await executeCommand(command)
        return result.success
    }

    /// Check connection status
    public var isConnected: Bool {
        bridge.isConnected
    }

    // MARK: - Command Execution

    private func executeCommand(_ command: MCPCommand) async -> AwareMCPResult {
        // This will be handled by the command handler which forwards to Aware
        return await withCheckedContinuation { continuation in
            pendingResults[command.id] = continuation
            Task {
                await bridge.sendEvent(MCPEvent(type: .actionCompleted, viewId: nil, data: ["commandId": command.id]))
            }
        }
    }

    private func executeBatch(_ batch: MCPBatch) async -> MCPBatchResult {
        // Execute commands sequentially
        var results: [AwareMCPResult] = []

        for command in batch.commands {
            let result = await executeCommand(command)
            results.append(result)

            // If atomic and failed, stop
            if batch.atomic && !result.success {
                break
            }
        }

        return MCPBatchResult(batchId: batch.id, results: results)
    }

    // MARK: - Command Handlers

    private func handleCommand(_ command: MCPCommand) async -> AwareMCPResult {
        // This is called when bridge receives a command
        // Forward to Aware for execution

        switch command.action {
        case .snapshot:
            let formatStr = command.parameters?["format"] ?? "compact"
            let format: AwareSnapshotFormat
            switch formatStr {
            case "text": format = .text
            case "json": format = .json
            case "markdown": format = .markdown
            default: format = .compact
            }
            let snapshot = Aware.shared.captureSnapshot(format: format)
            return AwareMCPResult.success(
                commandId: command.id,
                data: [
                    "snapshot": snapshot.content,
                    "viewCount": "\(snapshot.viewCount)",
                    "format": snapshot.format
                ]
            )

        case .tap:
            guard let viewId = command.parameters?["viewId"] else {
                return AwareMCPResult.failure(
                    commandId: command.id,
                    error: AwareMCPError(code: "INVALID_PARAMETERS", message: "tap requires viewId parameter")
                )
            }
            let awareCommand = AwareCommand(action: "tap", viewId: viewId)
            let result = await Aware.shared.executeAction(awareCommand)
            return result.status == "success"
                ? AwareMCPResult.success(commandId: command.id, data: ["message": result.message ?? "Tapped"])
                : AwareMCPResult.failure(commandId: command.id, error: AwareMCPError(code: "ACTION_FAILED", message: result.message ?? "Tap failed"))

        case .type:
            guard let viewId = command.parameters?["viewId"],
                  let text = command.parameters?["text"] else {
                return AwareMCPResult.failure(
                    commandId: command.id,
                    error: AwareMCPError(code: "INVALID_PARAMETERS", message: "type requires viewId and text parameters")
                )
            }
            let awareCommand = AwareCommand(action: "type", viewId: viewId, value: text)
            let result = await Aware.shared.executeAction(awareCommand)
            return result.status == "success"
                ? AwareMCPResult.success(commandId: command.id, data: ["message": result.message ?? "Typed"])
                : AwareMCPResult.failure(commandId: command.id, error: AwareMCPError(code: "ACTION_FAILED", message: result.message ?? "Type failed"))

        case .swipe:
            guard let viewId = command.parameters?["viewId"],
                  let direction = command.parameters?["direction"] else {
                return AwareMCPResult.failure(
                    commandId: command.id,
                    error: AwareMCPError(code: "INVALID_PARAMETERS", message: "swipe requires viewId and direction parameters")
                )
            }
            let awareCommand = AwareCommand(action: "swipe", viewId: viewId, value: direction)
            let result = await Aware.shared.executeAction(awareCommand)
            return result.status == "success"
                ? AwareMCPResult.success(commandId: command.id, data: ["message": result.message ?? "Swiped"])
                : AwareMCPResult.failure(commandId: command.id, error: AwareMCPError(code: "ACTION_FAILED", message: result.message ?? "Swipe failed"))

        case .scroll:
            guard let viewId = command.parameters?["viewId"],
                  let direction = command.parameters?["direction"] else {
                return AwareMCPResult.failure(
                    commandId: command.id,
                    error: AwareMCPError(code: "INVALID_PARAMETERS", message: "scroll requires viewId and direction parameters")
                )
            }
            // Scroll is implemented as swipe in the opposite direction
            let scrollDirection: String
            switch direction {
            case "up": scrollDirection = "down"
            case "down": scrollDirection = "up"
            case "left": scrollDirection = "right"
            case "right": scrollDirection = "left"
            default: scrollDirection = direction
            }
            let awareCommand = AwareCommand(action: "swipe", viewId: viewId, value: scrollDirection)
            let result = await Aware.shared.executeAction(awareCommand)
            return result.status == "success"
                ? AwareMCPResult.success(commandId: command.id, data: ["message": result.message ?? "Scrolled"])
                : AwareMCPResult.failure(commandId: command.id, error: AwareMCPError(code: "ACTION_FAILED", message: result.message ?? "Scroll failed"))

        case .longPress:
            guard let viewId = command.parameters?["viewId"] else {
                return AwareMCPResult.failure(
                    commandId: command.id,
                    error: AwareMCPError(code: "INVALID_PARAMETERS", message: "longPress requires viewId parameter")
                )
            }
            let awareCommand = AwareCommand(action: "longPress", viewId: viewId)
            let result = await Aware.shared.executeAction(awareCommand)
            return result.status == "success"
                ? AwareMCPResult.success(commandId: command.id, data: ["message": result.message ?? "Long pressed"])
                : AwareMCPResult.failure(commandId: command.id, error: AwareMCPError(code: "ACTION_FAILED", message: result.message ?? "Long press failed"))

        case .doubleTap:
            guard let viewId = command.parameters?["viewId"] else {
                return AwareMCPResult.failure(
                    commandId: command.id,
                    error: AwareMCPError(code: "INVALID_PARAMETERS", message: "doubleTap requires viewId parameter")
                )
            }
            let awareCommand = AwareCommand(action: "doubleTap", viewId: viewId)
            let result = await Aware.shared.executeAction(awareCommand)
            return result.status == "success"
                ? AwareMCPResult.success(commandId: command.id, data: ["message": result.message ?? "Double tapped"])
                : AwareMCPResult.failure(commandId: command.id, error: AwareMCPError(code: "ACTION_FAILED", message: result.message ?? "Double tap failed"))

        case .find:
            let label = command.parameters?["label"]
            let viewId = command.parameters?["viewId"]
            let searchTerm = label ?? viewId ?? ""
            let matches = Aware.shared.viewRegistry.keys.filter { $0.contains(searchTerm) }
            return AwareMCPResult.success(
                commandId: command.id,
                data: [
                    "viewIds": matches.joined(separator: ","),
                    "count": "\(matches.count)"
                ]
            )

        case .getState:
            guard let viewId = command.parameters?["viewId"] else {
                return AwareMCPResult.failure(
                    commandId: command.id,
                    error: AwareMCPError(code: "INVALID_PARAMETERS", message: "getState requires viewId parameter")
                )
            }
            let stateKey = command.parameters?["key"]
            if let key = stateKey {
                let value = Aware.shared.stateRegistry[viewId]?[key]
                return AwareMCPResult.success(
                    commandId: command.id,
                    data: ["value": value ?? ""]
                )
            } else {
                // Return all state for the view
                let states = Aware.shared.stateRegistry[viewId] ?? [:]
                return AwareMCPResult.success(
                    commandId: command.id,
                    data: states
                )
            }

        case .focus:
            guard let viewId = command.parameters?["viewId"] else {
                return AwareMCPResult.failure(
                    commandId: command.id,
                    error: AwareMCPError(code: "INVALID_PARAMETERS", message: "focus requires viewId parameter")
                )
            }
            let awareCommand = AwareCommand(action: "focus", viewId: viewId)
            let result = await Aware.shared.executeAction(awareCommand)
            return result.status == "success"
                ? AwareMCPResult.success(commandId: command.id, data: ["message": result.message ?? "Focused"])
                : AwareMCPResult.failure(commandId: command.id, error: AwareMCPError(code: "ACTION_FAILED", message: result.message ?? "Focus failed"))

        case .focusNext:
            let awareCommand = AwareCommand(action: "focusNext", viewId: nil)
            let result = await Aware.shared.executeAction(awareCommand)
            return result.status == "success"
                ? AwareMCPResult.success(commandId: command.id, data: ["message": result.message ?? "Focused next"])
                : AwareMCPResult.failure(commandId: command.id, error: AwareMCPError(code: "ACTION_FAILED", message: result.message ?? "Focus next failed"))

        case .focusPrevious:
            let awareCommand = AwareCommand(action: "focusPrevious", viewId: nil)
            let result = await Aware.shared.executeAction(awareCommand)
            return result.status == "success"
                ? AwareMCPResult.success(commandId: command.id, data: ["message": result.message ?? "Focused previous"])
                : AwareMCPResult.failure(commandId: command.id, error: AwareMCPError(code: "ACTION_FAILED", message: result.message ?? "Focus previous failed"))

        case .wait:
            guard let viewId = command.parameters?["viewId"],
                  let stateKey = command.parameters?["stateKey"],
                  let expectedValue = command.parameters?["expectedValue"] else {
                return AwareMCPResult.failure(
                    commandId: command.id,
                    error: AwareMCPError(code: "INVALID_PARAMETERS", message: "wait requires viewId, stateKey, and expectedValue parameters")
                )
            }
            let timeoutStr = command.parameters?["timeout"] ?? "5.0"
            let timeout = TimeInterval(timeoutStr) ?? 5.0

            // Poll for expected state
            let startTime = Date()
            while Date().timeIntervalSince(startTime) < timeout {
                if let currentValue = Aware.shared.stateRegistry[viewId]?[stateKey],
                   currentValue == expectedValue {
                    return AwareMCPResult.success(commandId: command.id, data: ["message": "Condition met"])
                }
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            }
            return AwareMCPResult.failure(
                commandId: command.id,
                error: AwareMCPError(code: "TIMEOUT", message: "Timed out waiting for \(stateKey)=\(expectedValue)")
            )

        case .assert:
            guard let viewId = command.parameters?["viewId"],
                  let condition = command.parameters?["condition"],
                  let expectedValue = command.parameters?["expectedValue"] else {
                return AwareMCPResult.failure(
                    commandId: command.id,
                    error: AwareMCPError(code: "INVALID_PARAMETERS", message: "assert requires viewId, condition, and expectedValue parameters")
                )
            }
            let awareCommand = AwareCommand(action: "assert", viewId: viewId, value: expectedValue, key: condition)
            let result = await Aware.shared.executeAction(awareCommand)
            return result.status == "success"
                ? AwareMCPResult.success(commandId: command.id, data: ["message": result.message ?? "Assert passed", "actual": result.actual ?? ""])
                : AwareMCPResult.failure(commandId: command.id, error: AwareMCPError(code: "ASSERTION_FAILED", message: result.message ?? "Assert failed"))

        case .test:
            // Batch test handled separately
            return AwareMCPResult.success(commandId: command.id, data: ["status": "use batch API for tests"])

        case .ping:
            return AwareMCPResult.success(
                commandId: command.id,
                data: [
                    "status": "ok",
                    "viewCount": "\(Aware.shared.viewRegistry.count)",
                    "timestamp": ISO8601DateFormatter().string(from: Date())
                ]
            )

        case .configure:
            // Configuration handled at bridge level
            return AwareMCPResult.success(commandId: command.id, data: ["status": "configured"])
        }
    }

    private func handleBatch(_ batch: MCPBatch) async -> MCPBatchResult {
        var results: [AwareMCPResult] = []

        for command in batch.commands {
            let result = await handleCommand(command)
            results.append(result)

            if batch.atomic && !result.success {
                break
            }
        }

        return MCPBatchResult(batchId: batch.id, results: results)
    }

    // MARK: - Event Handling

    /// Register event handler for Breathe IDE
    public func onEvent(_ handler: @escaping (MCPEvent) -> Void) {
        // Events are already broadcast via bridge
        // This just provides a convenience hook
    }
}
