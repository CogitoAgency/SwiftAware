//
//  AwareAccessibility.swift
//  Aware
//
//  Accessibility auditing for Aware-instrumented views.
//

import Foundation
import SwiftUI

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

// MARK: - WCAG Level

/// Web Content Accessibility Guidelines conformance levels
public enum WCAGLevel: String, Codable, CaseIterable {
    case A = "A"
    case AA = "AA"
    case AAA = "AAA"

    public var displayName: String {
        switch self {
        case .A: return "Level A (Minimum)"
        case .AA: return "Level AA (Standard)"
        case .AAA: return "Level AAA (Enhanced)"
        }
    }
}

// MARK: - Accessibility Issue

/// An accessibility issue found during audit
public struct AccessibilityIssue: Identifiable, Codable {
    public let id: String
    public let viewId: String?
    public let type: AccessibilityIssueType
    public let severity: AccessibilitySeverity
    public let message: String
    public let suggestion: String?
    public let wcagCriteria: String?

    public init(
        id: String = UUID().uuidString,
        viewId: String? = nil,
        type: AccessibilityIssueType,
        severity: AccessibilitySeverity,
        message: String,
        suggestion: String? = nil,
        wcagCriteria: String? = nil
    ) {
        self.id = id
        self.viewId = viewId
        self.type = type
        self.severity = severity
        self.message = message
        self.suggestion = suggestion
        self.wcagCriteria = wcagCriteria
    }
}

// MARK: - Issue Type

/// Types of accessibility issues
public enum AccessibilityIssueType: String, Codable {
    case missingLabel = "missing_label"
    case emptyLabel = "empty_label"
    case lowContrast = "low_contrast"
    case smallTouchTarget = "small_touch_target"
    case missingHint = "missing_hint"
    case nonDescriptiveLabel = "non_descriptive_label"
    case missingTraits = "missing_traits"
    case focusNotManaged = "focus_not_managed"
    case animationNotReduced = "animation_not_reduced"
    case textTooSmall = "text_too_small"
    case colorOnly = "color_only"
    case noKeyboardAccess = "no_keyboard_access"
    case missingHeading = "missing_heading"
    case imageWithoutAlt = "image_without_alt"

    public var description: String {
        switch self {
        case .missingLabel: return "Missing accessibility label"
        case .emptyLabel: return "Empty accessibility label"
        case .lowContrast: return "Insufficient color contrast"
        case .smallTouchTarget: return "Touch target too small"
        case .missingHint: return "Missing accessibility hint"
        case .nonDescriptiveLabel: return "Label is not descriptive"
        case .missingTraits: return "Missing accessibility traits"
        case .focusNotManaged: return "Focus not properly managed"
        case .animationNotReduced: return "Animation not reduced for accessibility"
        case .textTooSmall: return "Text size too small"
        case .colorOnly: return "Information conveyed by color only"
        case .noKeyboardAccess: return "No keyboard access"
        case .missingHeading: return "Missing heading structure"
        case .imageWithoutAlt: return "Image without alternative text"
        }
    }
}

// MARK: - Severity

/// Severity of accessibility issues
public enum AccessibilitySeverity: String, Codable, Comparable {
    case critical = "critical"  // Blocks access
    case serious = "serious"    // Significant barrier
    case moderate = "moderate"  // Difficulty using
    case minor = "minor"        // Minor inconvenience

    public static func < (lhs: AccessibilitySeverity, rhs: AccessibilitySeverity) -> Bool {
        let order: [AccessibilitySeverity] = [.minor, .moderate, .serious, .critical]
        return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
    }
}

// MARK: - Accessibility Audit Result

/// Result of an accessibility audit
public struct AccessibilityAudit: Codable {
    public let timestamp: Date
    public let viewsAudited: Int
    public let issues: [AccessibilityIssue]
    public let wcagLevel: WCAGLevel
    public let passed: Bool
    public let score: Double  // 0-100

    public init(
        timestamp: Date = Date(),
        viewsAudited: Int,
        issues: [AccessibilityIssue],
        wcagLevel: WCAGLevel,
        passed: Bool,
        score: Double
    ) {
        self.timestamp = timestamp
        self.viewsAudited = viewsAudited
        self.issues = issues
        self.wcagLevel = wcagLevel
        self.passed = passed
        self.score = score
    }

    // MARK: - Issue Counts

    public var criticalCount: Int {
        issues.filter { $0.severity == .critical }.count
    }

    public var seriousCount: Int {
        issues.filter { $0.severity == .serious }.count
    }

    public var moderateCount: Int {
        issues.filter { $0.severity == .moderate }.count
    }

    public var minorCount: Int {
        issues.filter { $0.severity == .minor }.count
    }

    // MARK: - Reporting

    public func toMarkdown() -> String {
        var lines: [String] = []
        lines.append("# Accessibility Audit Report")
        lines.append("")
        lines.append("**Date:** \(ISO8601DateFormatter().string(from: timestamp))")
        lines.append("**WCAG Level:** \(wcagLevel.rawValue)")
        lines.append("**Result:** \(passed ? "PASSED" : "FAILED")")
        lines.append("**Score:** \(String(format: "%.0f", score))%")
        lines.append("")
        lines.append("## Summary")
        lines.append("- Views Audited: \(viewsAudited)")
        lines.append("- Total Issues: \(issues.count)")
        lines.append("  - Critical: \(criticalCount)")
        lines.append("  - Serious: \(seriousCount)")
        lines.append("  - Moderate: \(moderateCount)")
        lines.append("  - Minor: \(minorCount)")
        lines.append("")

        if !issues.isEmpty {
            lines.append("## Issues")
            lines.append("")
            lines.append("| Severity | Type | View | Message |")
            lines.append("|----------|------|------|---------|")

            for issue in issues.sorted(by: { $0.severity > $1.severity }) {
                lines.append("| \(issue.severity.rawValue) | \(issue.type.rawValue) | \(issue.viewId ?? "-") | \(issue.message) |")
            }
        }

        return lines.joined(separator: "\n")
    }
}

// MARK: - Accessibility Auditor

/// Performs accessibility audits on Aware-instrumented views
@MainActor
public class AwareAccessibilityAuditor: ObservableObject {

    public static let shared = AwareAccessibilityAuditor()

    // MARK: - State

    @Published public private(set) var isAuditing = false
    @Published public private(set) var lastAudit: AccessibilityAudit?

    // MARK: - Configuration

    /// Minimum touch target size (44x44 per Apple HIG)
    public var minTouchTargetSize: CGFloat = 44

    /// Minimum contrast ratio for normal text (4.5:1 for WCAG AA)
    public var minContrastRatioNormal: Double = 4.5

    /// Minimum contrast ratio for large text (3:1 for WCAG AA)
    public var minContrastRatioLarge: Double = 3.0

    /// Minimum text size
    public var minTextSize: CGFloat = 11

    public init() {}

    // MARK: - Audit

    /// Run a full accessibility audit
    public func audit(level: WCAGLevel = .AA) -> AccessibilityAudit {
        isAuditing = true
        defer { isAuditing = false }

        var issues: [AccessibilityIssue] = []
        let aware = Aware.shared
        let viewIds = aware.registeredViewIds

        // Audit each registered view
        for viewId in viewIds {
            issues.append(contentsOf: auditView(viewId: viewId, level: level))
        }

        // Check overall accessibility
        issues.append(contentsOf: auditGlobalAccessibility(level: level))

        // Calculate score
        let criticalWeight = 10.0
        let seriousWeight = 5.0
        let moderateWeight = 2.0
        let minorWeight = 1.0

        let totalWeight = Double(issues.count > 0 ? issues.count : 1) * criticalWeight
        let issueWeight = issues.reduce(0.0) { sum, issue in
            switch issue.severity {
            case .critical: return sum + criticalWeight
            case .serious: return sum + seriousWeight
            case .moderate: return sum + moderateWeight
            case .minor: return sum + minorWeight
            }
        }

        let score = max(0, 100 - (issueWeight / totalWeight * 100))
        let passed = !issues.contains { $0.severity == .critical || $0.severity == .serious }

        let audit = AccessibilityAudit(
            viewsAudited: viewIds.count,
            issues: issues,
            wcagLevel: level,
            passed: passed,
            score: score
        )

        lastAudit = audit
        return audit
    }

    // MARK: - View Audit

    private func auditView(viewId: String, level: WCAGLevel) -> [AccessibilityIssue] {
        var issues: [AccessibilityIssue] = []
        let aware = Aware.shared

        // Check for accessibility label
        let label = aware.getLabel(viewId)
        if label == nil || label?.isEmpty == true {
            issues.append(AccessibilityIssue(
                viewId: viewId,
                type: .missingLabel,
                severity: .serious,
                message: "View '\(viewId)' has no accessibility label",
                suggestion: "Add an accessibility label using .accessibilityLabel()",
                wcagCriteria: "1.1.1"
            ))
        } else if let labelText = label, isNonDescriptive(labelText) {
            issues.append(AccessibilityIssue(
                viewId: viewId,
                type: .nonDescriptiveLabel,
                severity: .moderate,
                message: "Label '\(labelText)' may not be descriptive enough",
                suggestion: "Use a more descriptive label that explains the element's purpose",
                wcagCriteria: "2.4.6"
            ))
        }

        // Check if tappable elements have proper size
        if aware.hasDirectAction(viewId) {
            issues.append(AccessibilityIssue(
                viewId: viewId,
                type: .smallTouchTarget,
                severity: .moderate,
                message: "Verify touch target is at least \(Int(minTouchTargetSize))x\(Int(minTouchTargetSize)) points",
                suggestion: "Ensure minimum touch target of 44x44 points",
                wcagCriteria: "2.5.5"
            ))
        }

        // Check for hints on complex interactions
        if aware.hasDirectAction(viewId) && !hasHint(viewId) {
            if level == .AAA {
                issues.append(AccessibilityIssue(
                    viewId: viewId,
                    type: .missingHint,
                    severity: .minor,
                    message: "Interactive element has no accessibility hint",
                    suggestion: "Add an accessibility hint to describe the result of the action",
                    wcagCriteria: "3.3.2"
                ))
            }
        }

        return issues
    }

    // MARK: - Global Audit

    private func auditGlobalAccessibility(level: WCAGLevel) -> [AccessibilityIssue] {
        var issues: [AccessibilityIssue] = []

        // Check for keyboard navigation
        if !isKeyboardNavigable() {
            issues.append(AccessibilityIssue(
                type: .noKeyboardAccess,
                severity: .critical,
                message: "Application may not be fully keyboard navigable",
                suggestion: "Ensure all interactive elements can be reached via keyboard",
                wcagCriteria: "2.1.1"
            ))
        }

        // Check for heading structure (AAA)
        if level == .AAA && !hasHeadingStructure() {
            issues.append(AccessibilityIssue(
                type: .missingHeading,
                severity: .minor,
                message: "No heading structure detected",
                suggestion: "Use accessibility traits to mark headings",
                wcagCriteria: "2.4.10"
            ))
        }

        return issues
    }

    // MARK: - Helpers

    private func isNonDescriptive(_ label: String) -> Bool {
        let nonDescriptive = ["button", "image", "icon", "view", "text", "label", "tap", "click", "here"]
        return nonDescriptive.contains(label.lowercased())
    }

    private func hasHint(_ viewId: String) -> Bool {
        // Check if view has registered accessibility hint in state
        let hint = Aware.shared.getStateValue(viewId, key: "accessibilityHint")
        return hint != nil && !(hint?.isEmpty ?? true)
    }

    private func isKeyboardNavigable() -> Bool {
        // Check if any views have focus tracking enabled
        let aware = Aware.shared
        let viewIds = aware.registeredViewIds

        // Count views with focus state
        let focusableCount = viewIds.filter { viewId in
            aware.getStateValue(viewId, key: "isFocusable") == "true" ||
            aware.getStateValue(viewId, key: "canBecomeFocused") == "true"
        }.count

        // At least 2 focusable elements suggests keyboard navigation
        return focusableCount >= 2
    }

    private func hasHeadingStructure() -> Bool {
        // Check for views with heading traits
        let aware = Aware.shared
        let viewIds = aware.registeredViewIds

        let headingCount = viewIds.filter { viewId in
            aware.getStateValue(viewId, key: "accessibilityTraits")?.contains("heading") == true ||
            aware.getStateValue(viewId, key: "isHeading") == "true"
        }.count

        // At least 1 heading suggests structure
        return headingCount >= 1
    }
}

// MARK: - Contrast Checker

/// Checks color contrast ratios
public struct ContrastChecker {

    #if os(macOS)
    /// Calculate contrast ratio between two colors (macOS)
    public static func contrastRatio(foreground: NSColor, background: NSColor) -> Double {
        let fgLuminance = relativeLuminance(foreground)
        let bgLuminance = relativeLuminance(background)

        let lighter = max(fgLuminance, bgLuminance)
        let darker = min(fgLuminance, bgLuminance)

        return (lighter + 0.05) / (darker + 0.05)
    }

    /// Calculate relative luminance of a color (macOS)
    private static func relativeLuminance(_ color: NSColor) -> Double {
        guard let rgb = color.usingColorSpace(.sRGB) else { return 0 }

        let r = adjustGamma(rgb.redComponent)
        let g = adjustGamma(rgb.greenComponent)
        let b = adjustGamma(rgb.blueComponent)

        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    /// Check if contrast meets WCAG requirements (macOS)
    public static func meetsWCAG(
        foreground: NSColor,
        background: NSColor,
        level: WCAGLevel,
        isLargeText: Bool
    ) -> Bool {
        let ratio = contrastRatio(foreground: foreground, background: background)

        switch level {
        case .A:
            return true
        case .AA:
            return isLargeText ? ratio >= 3.0 : ratio >= 4.5
        case .AAA:
            return isLargeText ? ratio >= 4.5 : ratio >= 7.0
        }
    }
    #endif

    #if os(iOS)
    /// Calculate contrast ratio between two colors (iOS)
    public static func contrastRatio(foreground: UIColor, background: UIColor) -> Double {
        let fgLuminance = relativeLuminance(foreground)
        let bgLuminance = relativeLuminance(background)

        let lighter = max(fgLuminance, bgLuminance)
        let darker = min(fgLuminance, bgLuminance)

        return (lighter + 0.05) / (darker + 0.05)
    }

    /// Calculate relative luminance of a color (iOS)
    private static func relativeLuminance(_ color: UIColor) -> Double {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        color.getRed(&r, green: &g, blue: &b, alpha: &a)

        return 0.2126 * adjustGamma(r) + 0.7152 * adjustGamma(g) + 0.0722 * adjustGamma(b)
    }

    /// Check if contrast meets WCAG requirements (iOS)
    public static func meetsWCAG(
        foreground: UIColor,
        background: UIColor,
        level: WCAGLevel,
        isLargeText: Bool
    ) -> Bool {
        let ratio = contrastRatio(foreground: foreground, background: background)

        switch level {
        case .A:
            return true
        case .AA:
            return isLargeText ? ratio >= 3.0 : ratio >= 4.5
        case .AAA:
            return isLargeText ? ratio >= 4.5 : ratio >= 7.0
        }
    }
    #endif

    private static func adjustGamma(_ value: CGFloat) -> Double {
        let v = Double(value)
        return v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
    }
}

// MARK: - Accessibility Assertion

/// Result of an accessibility assertion
public struct AccessibilityAssertionResult {
    public let passed: Bool
    public let message: String
    public let issues: [AccessibilityIssue]

    public init(passed: Bool, message: String, issues: [AccessibilityIssue] = []) {
        self.passed = passed
        self.message = message
        self.issues = issues
    }
}

// MARK: - Aware Extension

extension Aware {

    /// Get accessibility label for a view
    public func getLabel(_ viewId: String) -> String? {
        return Aware.shared.getStateValue(viewId, key: "label")
    }

    /// Assert view is accessible
    public func assertAccessible(_ viewId: String) -> AccessibilityAssertionResult {
        let label = getLabel(viewId)
        if label == nil || label?.isEmpty == true {
            return AccessibilityAssertionResult(
                passed: false,
                message: "View '\(viewId)' has no accessibility label",
                issues: [AccessibilityIssue(
                    viewId: viewId,
                    type: .missingLabel,
                    severity: .serious,
                    message: "Missing accessibility label"
                )]
            )
        }
        return AccessibilityAssertionResult(
            passed: true,
            message: "View '\(viewId)' is accessible"
        )
    }

    /// Assert accessibility label equals expected
    public func assertLabel(_ viewId: String, equals expected: String) -> AccessibilityAssertionResult {
        let actual = getLabel(viewId)
        if actual == expected {
            return AccessibilityAssertionResult(
                passed: true,
                message: "Label matches: '\(expected)'"
            )
        }
        return AccessibilityAssertionResult(
            passed: false,
            message: "Label mismatch: expected '\(expected)', got '\(actual ?? "nil")'"
        )
    }

    /// Run accessibility audit and assert passing
    @MainActor
    public func assertAccessibilityPasses(level: WCAGLevel = .AA) -> AccessibilityAssertionResult {
        let audit = AwareAccessibilityAuditor.shared.audit(level: level)
        if audit.passed {
            return AccessibilityAssertionResult(
                passed: true,
                message: "Accessibility audit passed (\(String(format: "%.0f", audit.score))% score)"
            )
        }
        return AccessibilityAssertionResult(
            passed: false,
            message: "Accessibility audit failed: \(audit.criticalCount) critical, \(audit.seriousCount) serious issues",
            issues: audit.issues
        )
    }
}
