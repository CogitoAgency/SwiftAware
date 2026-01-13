//
//  AwareAsyncTester.swift
//  AwareCore
//
//  Smart waiting and retry orchestration for LLM-driven UI testing.
//  Handles async operations (loading, errors, retries) with exponential backoff.
//

import Foundation

// MARK: - AwareAsyncTester

/// Orchestrates async operations with smart waiting and retry strategies
@MainActor
public class AwareAsyncTester: ObservableObject {
    public static let shared = AwareAsyncTester()

    // MARK: - Configuration

    /// Default timeout for async operations (3 seconds)
    public var defaultTimeout: TimeInterval = 3.0

    /// Default polling interval (100ms)
    public var pollingInterval: TimeInterval = 0.1

    /// Enable exponential backoff for polling
    public var useExponentialBackoff: Bool = true

    // MARK: - Observable State

    /// Current operation being executed (for LLM monitoring)
    @Published public private(set) var currentOperation: String?

    /// Progress of current operation (0.0 - 1.0)
    @Published public private(set) var progress: Double = 0

    private init() {}

    // MARK: - Smart Waiting

    /// Wait for a condition to become true with smart polling
    ///
    /// **Token Cost:** ~25 tokens per invocation
    /// **Typical Duration:** 100-500ms
    /// **LLM Guidance:** Use for dynamic waits (loading, animations, state changes)
    ///
    /// - Parameters:
    ///   - timeout: Maximum wait time (default: 3.0s)
    ///   - pollingInterval: Initial polling interval (default: 100ms)
    ///   - description: Human-readable description for logging
    ///   - condition: Async closure that returns true when condition is met
    /// - Returns: WaitResult with success status, duration, and attempts
    /// - Throws: AsyncTestError.timeout if condition doesn't become true
    public func waitFor(
        timeout: TimeInterval? = nil,
        pollingInterval: TimeInterval? = nil,
        description: String = "condition",
        condition: @escaping () async -> Bool
    ) async throws -> WaitResult {
        let effectiveTimeout = timeout ?? defaultTimeout
        let effectiveInterval = pollingInterval ?? self.pollingInterval

        currentOperation = "Waiting for: \(description)"
        progress = 0

        let startTime = Date()
        var attempts = 0
        var currentInterval = effectiveInterval

        while Date().timeIntervalSince(startTime) < effectiveTimeout {
            attempts += 1

            // Check condition
            if await condition() {
                let duration = Date().timeIntervalSince(startTime)
                currentOperation = nil
                progress = 1.0

                return WaitResult(
                    success: true,
                    duration: duration,
                    attempts: attempts,
                    message: "'\(description)' became true after \(Int(duration * 1000))ms (\(attempts) attempts)"
                )
            }

            // Update progress
            progress = min(Date().timeIntervalSince(startTime) / effectiveTimeout, 0.99)

            // Wait with backoff
            try await Task.sleep(for: .milliseconds(Int(currentInterval * 1000)))

            // Exponential backoff (up to 1s max)
            if useExponentialBackoff {
                currentInterval = min(currentInterval * 1.5, 1.0)
            }
        }

        // Timeout
        currentOperation = nil
        progress = 0

        throw AsyncTestError.timeout(
            description: description,
            duration: effectiveTimeout
        )
    }

    /// Wait for view state to match expected value
    ///
    /// **Token Cost:** ~30 tokens per invocation
    /// **LLM Guidance:** Use when waiting for specific state changes
    ///
    /// - Parameters:
    ///   - viewId: View identifier
    ///   - key: State key to check
    ///   - value: Expected value
    ///   - timeout: Maximum wait time
    /// - Returns: WaitResult
    /// - Throws: AsyncTestError.timeout
    public func waitForState(
        viewId: String,
        key: String,
        equals value: String,
        timeout: TimeInterval? = nil
    ) async throws -> WaitResult {
        return try await waitFor(
            timeout: timeout,
            description: "state '\(viewId).\(key)' = '\(value)'"
        ) {
            // TODO: Integrate with Aware.shared.getStateValue when available
            // For now, this is a placeholder that will be integrated in v3.0
            return false
        }
    }

    /// Wait for loading state to complete
    ///
    /// **Token Cost:** ~25 tokens per invocation
    /// **LLM Guidance:** Use for any loading operation (network, processing, etc.)
    ///
    /// - Parameters:
    ///   - viewId: View identifier with loading state
    ///   - timeout: Maximum wait time
    /// - Returns: WaitResult
    /// - Throws: AsyncTestError.timeout
    public func waitForLoadingComplete(
        viewId: String,
        timeout: TimeInterval? = nil
    ) async throws -> WaitResult {
        return try await waitFor(
            timeout: timeout,
            description: "loading complete for '\(viewId)'"
        ) {
            // TODO: Integrate with Aware.shared.getStateValue
            // Check if isLoading state is false
            return false
        }
    }

    /// Wait for error state to appear
    ///
    /// **Token Cost:** ~25 tokens per invocation
    /// **LLM Guidance:** Use when expecting an error state to occur
    ///
    /// - Parameters:
    ///   - viewId: View identifier with error state
    ///   - timeout: Maximum wait time
    /// - Returns: WaitResult
    /// - Throws: AsyncTestError.timeout
    public func waitForError(
        viewId: String,
        timeout: TimeInterval? = nil
    ) async throws -> WaitResult {
        return try await waitFor(
            timeout: timeout,
            description: "error state for '\(viewId)'"
        ) {
            // TODO: Integrate with Aware.shared.getStateValue
            // Check if hasError state is true
            return false
        }
    }

    /// Wait for processing state to reach specific step
    ///
    /// **Token Cost:** ~30 tokens per invocation
    /// **LLM Guidance:** Use for multi-step operations (wizards, uploads, etc.)
    ///
    /// - Parameters:
    ///   - viewId: View identifier with processing state
    ///   - step: Expected step name
    ///   - timeout: Maximum wait time
    /// - Returns: WaitResult
    /// - Throws: AsyncTestError.timeout
    public func waitForProcessing(
        viewId: String,
        step: String,
        timeout: TimeInterval? = nil
    ) async throws -> WaitResult {
        return try await waitFor(
            timeout: timeout,
            description: "processing step '\(step)' for '\(viewId)'"
        ) {
            // TODO: Integrate with Aware.shared.getStateValue
            // Check if currentStep matches expected step
            return false
        }
    }

    // MARK: - Retry Orchestration

    /// Retry an action until it succeeds or max attempts reached
    ///
    /// **Token Cost:** ~30 tokens per invocation
    /// **LLM Guidance:** Use for network calls, flaky operations, race conditions
    ///
    /// - Parameters:
    ///   - maxAttempts: Maximum number of attempts (default: 3)
    ///   - delay: Initial delay between attempts (default: 1.0s)
    ///   - backoff: Backoff strategy (default: exponential)
    ///   - description: Human-readable description
    ///   - action: Async action to retry
    /// - Returns: RetryResult with success status and attempt count
    public func retry(
        maxAttempts: Int = 3,
        delay: TimeInterval = 1.0,
        backoff: BackoffStrategy = .exponential,
        description: String = "action",
        action: @escaping () async throws -> Void
    ) async -> RetryResult {
        currentOperation = "Retrying: \(description)"
        progress = 0

        let startTime = Date()
        var lastError: Error?
        var currentDelay = delay

        for attempt in 1...maxAttempts {
            do {
                progress = Double(attempt - 1) / Double(maxAttempts)
                try await action()

                // Success
                let duration = Date().timeIntervalSince(startTime)
                currentOperation = nil
                progress = 1.0

                return RetryResult(
                    success: true,
                    attempts: attempt,
                    totalDuration: duration,
                    lastError: nil,
                    message: "'\(description)' succeeded on attempt \(attempt)/\(maxAttempts)"
                )
            } catch {
                lastError = error

                // Don't delay after last attempt
                if attempt < maxAttempts {
                    try? await Task.sleep(for: .milliseconds(Int(currentDelay * 1000)))

                    // Apply backoff strategy
                    currentDelay = backoff.nextDelay(current: currentDelay, attempt: attempt)
                }
            }
        }

        // All attempts failed
        let duration = Date().timeIntervalSince(startTime)
        currentOperation = nil
        progress = 0

        return RetryResult(
            success: false,
            attempts: maxAttempts,
            totalDuration: duration,
            lastError: lastError,
            message: "'\(description)' failed after \(maxAttempts) attempts. Last error: \(lastError?.localizedDescription ?? "unknown")"
        )
    }

    /// Retry an action until a condition becomes true
    ///
    /// **Token Cost:** ~35 tokens per invocation
    /// **LLM Guidance:** Use when success depends on external state change
    ///
    /// - Parameters:
    ///   - maxAttempts: Maximum number of attempts
    ///   - delay: Initial delay between attempts
    ///   - backoff: Backoff strategy
    ///   - condition: Condition that must be true for success
    ///   - action: Async action to retry
    /// - Returns: RetryResult
    public func retryUntil(
        maxAttempts: Int = 3,
        delay: TimeInterval = 1.0,
        backoff: BackoffStrategy = .exponential,
        condition: @escaping () async -> Bool,
        action: @escaping () async throws -> Void
    ) async -> RetryResult {
        return await retry(
            maxAttempts: maxAttempts,
            delay: delay,
            backoff: backoff,
            description: "action with condition"
        ) {
            try await action()

            // Check condition after action
            if !(await condition()) {
                throw AsyncTestError.conditionNotMet
            }
        }
    }

    // MARK: - Timeout Budgets

    /// Execute operation within time budget
    ///
    /// **Token Cost:** ~30 tokens per invocation
    /// **LLM Guidance:** Use to enforce performance SLAs
    ///
    /// - Parameters:
    ///   - budget: Maximum allowed time
    ///   - description: Human-readable description
    ///   - operation: Async operation to execute
    /// - Returns: BudgetResult with success status and timing
    public func withinBudget(
        _ budget: TimeInterval,
        description: String = "operation",
        operation: @escaping () async throws -> Void
    ) async -> BudgetResult {
        currentOperation = "Budget check: \(description)"
        progress = 0

        let startTime = Date()

        do {
            try await operation()

            let duration = Date().timeIntervalSince(startTime)
            let overrun = duration > budget ? duration - budget : nil

            currentOperation = nil
            progress = 1.0

            return BudgetResult(
                success: overrun == nil,
                duration: duration,
                budget: budget,
                overrun: overrun,
                message: overrun == nil
                    ? "'\(description)' completed in \(Int(duration * 1000))ms (budget: \(Int(budget * 1000))ms)"
                    : "'\(description)' exceeded budget by \(Int(overrun! * 1000))ms (\(Int(duration * 1000))ms vs \(Int(budget * 1000))ms)"
            )
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            currentOperation = nil
            progress = 0

            return BudgetResult(
                success: false,
                duration: duration,
                budget: budget,
                overrun: nil,
                message: "'\(description)' failed: \(error.localizedDescription)"
            )
        }
    }

    /// Execute operation with multiple timeout stages
    ///
    /// **Token Cost:** ~40 tokens per invocation
    /// **LLM Guidance:** Use for multi-phase operations (setup → execute → teardown)
    ///
    /// - Parameters:
    ///   - stages: Array of timeout stages with budgets
    ///   - operation: Async operation to execute
    /// - Returns: BudgetResult for overall execution
    public func withStages(
        stages: [TimeoutStage],
        operation: @escaping () async throws -> Void
    ) async -> BudgetResult {
        currentOperation = "Multi-stage operation"
        progress = 0

        let startTime = Date()
        let totalBudget = stages.reduce(0) { $0 + $1.budget }

        // Execute each stage
        for (index, stage) in stages.enumerated() {
            currentOperation = "Stage \(index + 1)/\(stages.count): \(stage.name)"
            progress = Double(index) / Double(stages.count)

            let result = await withinBudget(stage.budget, description: stage.name) {
                try await stage.action()
            }

            if !result.success {
                currentOperation = nil
                progress = 0

                return BudgetResult(
                    success: false,
                    duration: Date().timeIntervalSince(startTime),
                    budget: totalBudget,
                    overrun: result.overrun,
                    message: "Stage '\(stage.name)' failed: \(result.message)"
                )
            }
        }

        // Execute main operation
        do {
            try await operation()

            let duration = Date().timeIntervalSince(startTime)
            let overrun = duration > totalBudget ? duration - totalBudget : nil

            currentOperation = nil
            progress = 1.0

            return BudgetResult(
                success: overrun == nil,
                duration: duration,
                budget: totalBudget,
                overrun: overrun,
                message: "All stages completed in \(Int(duration * 1000))ms"
            )
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            currentOperation = nil
            progress = 0

            return BudgetResult(
                success: false,
                duration: duration,
                budget: totalBudget,
                overrun: nil,
                message: "Operation failed: \(error.localizedDescription)"
            )
        }
    }
}

// MARK: - Supporting Types

/// Result of a wait operation
public struct WaitResult: Sendable {
    /// Whether the condition became true within timeout
    public let success: Bool

    /// How long it took (seconds)
    public let duration: TimeInterval

    /// Number of polling attempts
    public let attempts: Int

    /// Human-readable message (~15 tokens)
    public let message: String

    public init(success: Bool, duration: TimeInterval, attempts: Int, message: String) {
        self.success = success
        self.duration = duration
        self.attempts = attempts
        self.message = message
    }
}

/// Result of a retry operation
public struct RetryResult: Sendable {
    /// Whether the action eventually succeeded
    public let success: Bool

    /// Number of attempts made
    public let attempts: Int

    /// Total duration of all attempts (seconds)
    public let totalDuration: TimeInterval

    /// Last error encountered (if failed)
    public let lastError: Error?

    /// Human-readable message (~20 tokens)
    public let message: String

    public init(success: Bool, attempts: Int, totalDuration: TimeInterval, lastError: Error?, message: String) {
        self.success = success
        self.attempts = attempts
        self.totalDuration = totalDuration
        self.lastError = lastError
        self.message = message
    }
}

/// Result of a budget check
public struct BudgetResult: Sendable {
    /// Whether operation completed within budget
    public let success: Bool

    /// Actual duration (seconds)
    public let duration: TimeInterval

    /// Allocated budget (seconds)
    public let budget: TimeInterval

    /// How much over budget (if any)
    public let overrun: TimeInterval?

    /// Human-readable message (~20 tokens)
    public let message: String

    public init(success: Bool, duration: TimeInterval, budget: TimeInterval, overrun: TimeInterval?, message: String) {
        self.success = success
        self.duration = duration
        self.budget = budget
        self.overrun = overrun
        self.message = message
    }
}

/// Backoff strategy for retries
public enum BackoffStrategy: Sendable {
    /// Same delay each time (e.g., 1s, 1s, 1s)
    case fixed

    /// Increases linearly (e.g., 1s, 2s, 3s)
    case linear

    /// Doubles each time (e.g., 1s, 2s, 4s, 8s)
    case exponential

    /// Fibonacci sequence (e.g., 1s, 1s, 2s, 3s, 5s)
    case fibonacci

    func nextDelay(current: TimeInterval, attempt: Int) -> TimeInterval {
        switch self {
        case .fixed:
            return current
        case .linear:
            return current + current
        case .exponential:
            return current * 2
        case .fibonacci:
            // Approximate: multiply by golden ratio
            return current * 1.618
        }
    }
}

/// Timeout stage with budget
public struct TimeoutStage: Sendable {
    /// Stage name for logging
    public let name: String

    /// Time budget for this stage (seconds)
    public let budget: TimeInterval

    /// Action to execute in this stage
    public let action: @Sendable () async throws -> Void

    public init(name: String, budget: TimeInterval, action: @escaping @Sendable () async throws -> Void) {
        self.name = name
        self.budget = budget
        self.action = action
    }
}

// MARK: - Async Test Errors

/// Errors that can occur during async testing
public enum AsyncTestError: Error, LocalizedError, Sendable {
    /// Operation timed out
    case timeout(description: String, duration: TimeInterval)

    /// Max retry attempts exceeded
    case maxRetriesExceeded(attempts: Int, lastError: Error?)

    /// Budget time exceeded
    case budgetExceeded(budget: TimeInterval, actual: TimeInterval)

    /// Condition not met after action
    case conditionNotMet

    public var errorDescription: String? {
        switch self {
        case .timeout(let desc, let dur):
            return "Timeout: '\(desc)' exceeded \(String(format: "%.1f", dur))s"
        case .maxRetriesExceeded(let attempts, let error):
            if let error = error {
                return "Max retries (\(attempts)) exceeded. Last error: \(error.localizedDescription)"
            }
            return "Max retries (\(attempts)) exceeded"
        case .budgetExceeded(let budget, let actual):
            return "Budget exceeded: \(String(format: "%.1f", actual))s > \(String(format: "%.1f", budget))s"
        case .conditionNotMet:
            return "Condition not met after action execution"
        }
    }

    /// Whether this error is retryable
    public var isRetryable: Bool {
        switch self {
        case .timeout, .conditionNotMet:
            return true
        case .maxRetriesExceeded, .budgetExceeded:
            return false
        }
    }
}
