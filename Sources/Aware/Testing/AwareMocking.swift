//
//  AwareMocking.swift
//  Aware
//
//  Mock injection and network simulation for testing.
//

import Foundation
import SwiftUI

// MARK: - Mockable Protocol

/// Protocol for services that can be mocked in tests
public protocol AwareMockable {
    /// Mock a successful response for an endpoint
    func mockResponse(for endpoint: String, response: Any)

    /// Mock an error for an endpoint
    func mockError(for endpoint: String, error: Error)

    /// Mock a delayed response
    func mockDelay(for endpoint: String, seconds: Double)

    /// Clear all mocks
    func clearMocks()
}

// MARK: - Mock Response

/// A mock response configuration
public struct MockResponse {
    public let endpoint: String
    public let response: Any?
    public let error: Error?
    public let delay: TimeInterval

    public init(
        endpoint: String,
        response: Any? = nil,
        error: Error? = nil,
        delay: TimeInterval = 0
    ) {
        self.endpoint = endpoint
        self.response = response
        self.error = error
        self.delay = delay
    }
}

// MARK: - Mock Registry

/// Central registry for mock configurations
@MainActor
public class AwareMockRegistry: ObservableObject {

    public static let shared = AwareMockRegistry()

    // MARK: - State

    @Published public private(set) var isEnabled = false
    @Published public private(set) var activeMocks: [String: MockResponse] = [:]

    /// Network condition simulation
    @Published public var simulatedLatency: TimeInterval = 0
    @Published public var simulateOffline: Bool = false
    @Published public var simulateSlowNetwork: Bool = false

    public init() {}

    // MARK: - Mock Management

    /// Register a mock response
    public func register(_ mock: MockResponse) {
        activeMocks[mock.endpoint] = mock
        isEnabled = true
    }

    /// Register a success response
    public func mockSuccess<T: Encodable>(for endpoint: String, response: T) {
        let mock = MockResponse(endpoint: endpoint, response: response)
        register(mock)
    }

    /// Register an error response
    public func mockError(for endpoint: String, error: Error) {
        let mock = MockResponse(endpoint: endpoint, error: error)
        register(mock)
    }

    /// Register a delayed response
    public func mockDelay(for endpoint: String, seconds: Double, response: Any? = nil) {
        let mock = MockResponse(endpoint: endpoint, response: response, delay: seconds)
        register(mock)
    }

    /// Get mock for an endpoint
    public func getMock(for endpoint: String) -> MockResponse? {
        return activeMocks[endpoint]
    }

    /// Check if an endpoint is mocked
    public func isMocked(_ endpoint: String) -> Bool {
        return activeMocks[endpoint] != nil
    }

    /// Clear a specific mock
    public func clearMock(for endpoint: String) {
        activeMocks.removeValue(forKey: endpoint)
        isEnabled = !activeMocks.isEmpty
    }

    /// Clear all mocks
    public func clearAll() {
        activeMocks.removeAll()
        simulatedLatency = 0
        simulateOffline = false
        simulateSlowNetwork = false
        isEnabled = false
    }

    // MARK: - Network Simulation

    /// Simulate offline mode
    public func setOffline(_ offline: Bool) {
        simulateOffline = offline
        isEnabled = offline || !activeMocks.isEmpty
    }

    /// Simulate slow network (adds 2-5 second random latency)
    public func setSlowNetwork(_ slow: Bool) {
        simulateSlowNetwork = slow
        isEnabled = slow || !activeMocks.isEmpty
    }

    /// Set fixed latency for all requests
    public func setLatency(_ seconds: TimeInterval) {
        simulatedLatency = seconds
        isEnabled = seconds > 0 || !activeMocks.isEmpty
    }

    /// Get effective latency for a request
    public func getEffectiveLatency() -> TimeInterval {
        if simulateSlowNetwork {
            return Double.random(in: 2.0...5.0)
        }
        return simulatedLatency
    }
}

// MARK: - Mock Injector

/// Executes code with mocks in place
@MainActor
public class AwareMockInjector {

    public static let shared = AwareMockInjector()

    private let registry = AwareMockRegistry.shared

    public init() {}

    // MARK: - Execution Context

    /// Execute code with mocks active
    public func withMocks(
        _ mocks: [MockResponse],
        run: () async throws -> Void
    ) async rethrows {
        // Register mocks
        for mock in mocks {
            registry.register(mock)
        }

        defer {
            // Clear mocks after execution
            for mock in mocks {
                registry.clearMock(for: mock.endpoint)
            }
        }

        try await run()
    }

    /// Execute code with offline simulation
    public func withOffline(
        run: () async throws -> Void
    ) async rethrows {
        let wasOffline = registry.simulateOffline
        registry.setOffline(true)

        defer {
            registry.setOffline(wasOffline)
        }

        try await run()
    }

    /// Execute code with slow network simulation
    public func withSlowNetwork(
        run: () async throws -> Void
    ) async rethrows {
        let wasSlow = registry.simulateSlowNetwork
        registry.setSlowNetwork(true)

        defer {
            registry.setSlowNetwork(wasSlow)
        }

        try await run()
    }

    /// Execute code with fixed latency
    public func withLatency(
        _ seconds: TimeInterval,
        run: () async throws -> Void
    ) async rethrows {
        let previousLatency = registry.simulatedLatency
        registry.setLatency(seconds)

        defer {
            registry.setLatency(previousLatency)
        }

        try await run()
    }
}

// MARK: - Mock Errors

/// Common mock errors for testing
public enum MockError: Error, LocalizedError {
    case networkUnavailable
    case timeout
    case serverError(code: Int, message: String)
    case unauthorized
    case notFound
    case rateLimited
    case invalidResponse
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .networkUnavailable: return "Network unavailable (mocked)"
        case .timeout: return "Request timed out (mocked)"
        case .serverError(let code, let message): return "Server error \(code): \(message)"
        case .unauthorized: return "Unauthorized (mocked)"
        case .notFound: return "Not found (mocked)"
        case .rateLimited: return "Rate limited (mocked)"
        case .invalidResponse: return "Invalid response (mocked)"
        case .cancelled: return "Request cancelled (mocked)"
        }
    }
}

// MARK: - MCP Mock Support

/// Mock support for MCP tool calls
@MainActor
public class AwareMCPMocker {

    public static let shared = AwareMCPMocker()

    private var toolMocks: [String: Any] = [:]
    private var toolErrors: [String: Error] = [:]

    public init() {}

    /// Mock an MCP tool response
    public func mockTool(_ toolName: String, response: Any) {
        toolMocks[toolName] = response
    }

    /// Mock an MCP tool error
    public func mockToolError(_ toolName: String, error: Error) {
        toolErrors[toolName] = error
    }

    /// Get mocked response for a tool
    public func getMockedResponse(for toolName: String) -> Any? {
        return toolMocks[toolName]
    }

    /// Get mocked error for a tool
    public func getMockedError(for toolName: String) -> Error? {
        return toolErrors[toolName]
    }

    /// Check if a tool is mocked
    public func isMocked(_ toolName: String) -> Bool {
        return toolMocks[toolName] != nil || toolErrors[toolName] != nil
    }

    /// Clear a tool mock
    public func clearMock(for toolName: String) {
        toolMocks.removeValue(forKey: toolName)
        toolErrors.removeValue(forKey: toolName)
    }

    /// Clear all tool mocks
    public func clearAll() {
        toolMocks.removeAll()
        toolErrors.removeAll()
    }
}

// MARK: - Test Fixtures

/// Common test data fixtures
public struct AwareTestFixtures {

    // MARK: - Generic Fixtures

    public static func item(
        id: String = UUID().uuidString,
        type: String = "item",
        title: String = "Test Item",
        status: String = "active"
    ) -> [String: Any] {
        return [
            "id": id,
            "type": type,
            "title": title,
            "status": status,
            "created_at": ISO8601DateFormatter().string(from: Date())
        ]
    }

    public static func user(
        id: String = UUID().uuidString,
        name: String = "Test User",
        email: String = "test@example.com"
    ) -> [String: Any] {
        return [
            "id": id,
            "name": name,
            "email": email
        ]
    }

    public static func session(
        id: String = UUID().uuidString,
        status: String = "active",
        goal: String = "Test session"
    ) -> [String: Any] {
        return [
            "id": id,
            "status": status,
            "goal": goal,
            "started_at": ISO8601DateFormatter().string(from: Date())
        ]
    }

    public static func project(
        id: String = "test-project",
        name: String = "Test Project",
        path: String = "/tmp/test-project"
    ) -> [String: Any] {
        return [
            "id": id,
            "name": name,
            "path": path
        ]
    }
}

// MARK: - Mock Builder (Fluent API)

/// Fluent API for building mocks
public class MockBuilder {

    private var endpoint: String
    private var response: Any?
    private var error: Error?
    private var delay: TimeInterval = 0

    public init(endpoint: String) {
        self.endpoint = endpoint
    }

    /// Set success response
    public func returns<T>(_ response: T) -> Self {
        self.response = response
        return self
    }

    /// Set error response
    public func throwing(_ error: Error) -> Self {
        self.error = error
        return self
    }

    /// Set delay
    public func delay(_ seconds: TimeInterval) -> Self {
        self.delay = seconds
        return self
    }

    /// Build the mock response
    public func build() -> MockResponse {
        return MockResponse(
            endpoint: endpoint,
            response: response,
            error: error,
            delay: delay
        )
    }

    /// Register with the registry
    @MainActor
    public func register() {
        AwareMockRegistry.shared.register(build())
    }
}

// MARK: - Convenience Extensions

extension AwareMockRegistry {

    /// Create a mock builder for an endpoint
    public func mock(_ endpoint: String) -> MockBuilder {
        return MockBuilder(endpoint: endpoint)
    }
}
