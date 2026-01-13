//
//  AwareElementQuery.swift
//  Aware
//
//  Chainable query builder for finding UI elements in Aware snapshots.
//

import Foundation

// MARK: - Element Query (Chainable)

/// Chainable query builder for finding UI elements
public struct AwareElementQuery: Sendable {
    private var snapshots: [AwareViewSnapshot]
    private let stateRegistry: [String: [String: String]]

    public init(snapshots: [AwareViewSnapshot], stateRegistry: [String: [String: String]]) {
        self.snapshots = snapshots
        self.stateRegistry = stateRegistry
    }

    // MARK: - Filters

    /// Filter to visible elements only
    public func visible() -> AwareElementQuery {
        AwareElementQuery(snapshots: snapshots.filter { $0.isVisible }, stateRegistry: stateRegistry)
    }

    /// Filter by label containing text (case-insensitive)
    public func labelContains(_ text: String) -> AwareElementQuery {
        let lowered = text.lowercased()
        return AwareElementQuery(
            snapshots: snapshots.filter { $0.label?.lowercased().contains(lowered) == true },
            stateRegistry: stateRegistry
        )
    }

    /// Filter by exact label match
    public func label(_ text: String) -> AwareElementQuery {
        AwareElementQuery(
            snapshots: snapshots.filter { $0.label == text },
            stateRegistry: stateRegistry
        )
    }

    /// Filter by text content containing substring
    public func textContains(_ text: String) -> AwareElementQuery {
        let lowered = text.lowercased()
        return AwareElementQuery(
            snapshots: snapshots.filter { $0.visual?.text?.lowercased().contains(lowered) == true },
            stateRegistry: stateRegistry
        )
    }

    /// Filter by state key-value
    public func state(_ key: String, equals value: String) -> AwareElementQuery {
        AwareElementQuery(
            snapshots: snapshots.filter { stateRegistry[$0.id]?[key] == value },
            stateRegistry: stateRegistry
        )
    }

    /// Filter by state key existing
    public func hasState(_ key: String) -> AwareElementQuery {
        AwareElementQuery(
            snapshots: snapshots.filter { stateRegistry[$0.id]?[key] != nil },
            stateRegistry: stateRegistry
        )
    }

    /// Filter to tappable elements
    public func tappable() -> AwareElementQuery {
        AwareElementQuery(
            snapshots: snapshots.filter { $0.action != nil },
            stateRegistry: stateRegistry
        )
    }

    /// Filter by action type
    public func actionType(_ type: AwareActionMetadata.ActionType) -> AwareElementQuery {
        AwareElementQuery(
            snapshots: snapshots.filter { $0.action?.actionType == type },
            stateRegistry: stateRegistry
        )
    }

    /// Filter to enabled actions only
    public func enabled() -> AwareElementQuery {
        AwareElementQuery(
            snapshots: snapshots.filter { $0.action?.isEnabled != false },
            stateRegistry: stateRegistry
        )
    }

    /// Filter to destructive actions
    public func destructive() -> AwareElementQuery {
        AwareElementQuery(
            snapshots: snapshots.filter { $0.action?.isDestructive == true },
            stateRegistry: stateRegistry
        )
    }

    /// Filter by frame intersecting rect
    public func inRect(_ rect: CGRect) -> AwareElementQuery {
        AwareElementQuery(
            snapshots: snapshots.filter { $0.frame?.intersects(rect) == true },
            stateRegistry: stateRegistry
        )
    }

    /// Filter to animating elements
    public func animating() -> AwareElementQuery {
        AwareElementQuery(
            snapshots: snapshots.filter { $0.animation?.isAnimating == true },
            stateRegistry: stateRegistry
        )
    }

    /// Filter to focused elements
    public func focused() -> AwareElementQuery {
        AwareElementQuery(
            snapshots: snapshots.filter { $0.visual?.isFocused == true },
            stateRegistry: stateRegistry
        )
    }

    /// Filter by custom predicate
    public func `where`(_ predicate: (AwareViewSnapshot) -> Bool) -> AwareElementQuery {
        AwareElementQuery(snapshots: snapshots.filter(predicate), stateRegistry: stateRegistry)
    }

    // MARK: - Results

    /// Get all matching elements
    public func all() -> [AwareViewSnapshot] {
        snapshots
    }

    /// Get first matching element
    public func first() -> AwareViewSnapshot? {
        snapshots.first
    }

    /// Get count of matching elements
    public var count: Int {
        snapshots.count
    }

    /// Check if any elements match
    public var exists: Bool {
        !snapshots.isEmpty
    }

    /// Get IDs of matching elements
    public var ids: [String] {
        snapshots.map { $0.id }
    }
}
