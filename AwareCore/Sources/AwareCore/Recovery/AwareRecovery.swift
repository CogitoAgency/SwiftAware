//  AwareRecovery.swift
//  Aware
//
//  Error recovery mechanisms and retry logic for Aware operations.
//

import Foundation

/// Recovery strategies for different types of operations
public enum RecoveryStrategy {
    /// Retry the operation with exponential backoff
    case retry(maxAttempts: Int, baseDelay: TimeInterval)

    /// Use a fallback value or alternative approach
    case fallback(() -> Void)

    /// Skip the operation and continue
    case skip

    /// Fail immediately without recovery
    case fail
}

/// Protocol for operations that support recovery
public protocol RecoverableOperation {
    associatedtype Success
    associatedtype Failure: Error

    /// Execute the operation
    func execute() async throws -> Success

    /// Get recovery strategy for a specific error
    func recoveryStrategy(for error: Failure) -> RecoveryStrategy
}

/// Error recovery manager
@MainActor
public final class AwareRecoveryManager {
    public static let shared = AwareRecoveryManager()

    private init() {}

    /// Execute an operation with automatic recovery
    public func execute<T: RecoverableOperation>(
        _ operation: T
    ) async throws -> T.Success {
        var lastError: T.Failure?

        for attempt in 0..<10 { // Maximum attempts
            do {
                return try await operation.execute()
            } catch let error as T.Failure {
                lastError = error

                let strategy = operation.recoveryStrategy(for: error)

                switch strategy {
                case .retry(let maxAttempts, let baseDelay):
                    if attempt < maxAttempts {
                        let delay = baseDelay * pow(2.0, Double(attempt))
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    }

                case .fallback(let fallbackAction):
                    fallbackAction()
                    throw error

                case .skip:
                    return try await operation.execute() // Try one more time

                case .fail:
                    break
                }
            }
        }

        throw lastError ?? AwareError.internalError("Recovery failed after all attempts")
    }

    /// Execute a simple retryable operation
    public func withRetry<T>(
        maxAttempts: Int = 3,
        operation: () async throws -> T
    ) async throws -> T {
        var lastError: Error?

        for attempt in 0..<maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error

                if attempt < maxAttempts - 1 {
                    let delay = TimeInterval(attempt + 1) * 0.5 // Progressive delay
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }

        throw lastError ?? AwareError.internalError("Retry failed")
    }
}

/// Extension to add recovery capabilities to common operations
public extension AwareRecoveryManager {
    /// Execute snapshot generation with recovery
    func generateSnapshot(
        format: AwareSnapshotFormat = .compact,
        includeHidden: Bool = false,
        maxDepth: Int = 10
    ) async -> AwareSnapshotResult {
        do {
            return try await withRetry {
                Aware.shared.captureSnapshot(
                    format: format,
                    includeHidden: includeHidden,
                    maxDepth: maxDepth
                )
            }
        } catch {
            // Return error snapshot on failure
            return AwareSnapshotResult(
                format: format,
                content: "Error generating snapshot: \(error.localizedDescription)",
                viewCount: 0
            )
        }
    }

    /// Execute view registration with recovery
    func registerView(
        _ id: String,
        label: String? = nil,
        isContainer: Bool = false,
        parentId: String? = nil
    ) async {
        do {
            try await withRetry {
                Aware.shared.registerView(id, label: label, isContainer: isContainer, parentId: parentId)
            }
        } catch {
            // Log error but don't throw for view registration
            AwareError.viewRegistrationFailed(reason: error.localizedDescription, viewId: id).log()
        }
    }
}

/// Extension for custom recovery handlers
public extension AwareRecoveryManager {
    func withRetry<T>(
        maxAttempts: Int = 3,
        operation: () async throws -> T,
        recoveryHandler: (Error) throws -> T
    ) async throws -> T {
        var lastError: Error?

        for _ in 0..<maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error

                do {
                    return try recoveryHandler(error)
                } catch {
                    // Recovery failed, continue to retry
                    continue
                }
            }
        }

        throw lastError ?? AwareError.internalError("All recovery attempts failed")
    }
}