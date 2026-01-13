//
//  AwareInputPlaceholders.swift
//  AwareCore
//
//  Placeholder input classes for compilation.
//  Real implementations will be in platform-specific packages.
//

import Foundation
import CoreGraphics

#if os(macOS)
/// Placeholder for macOS mouse input (real implementation in AwareMacOS)
public struct AwareMouseInput {
    public static func click(at point: CGPoint) async -> Bool {
        // TODO: Move to AwareMacOS package
        return false
    }

    public static func longPress(at point: CGPoint, duration: TimeInterval) async -> Bool {
        // TODO: Move to AwareMacOS package
        return false
    }
}

/// Placeholder for text input (real implementation in AwareMacOS)
public struct AwareTextInput {
    public static func type(_ text: String) async {
        // TODO: Move to AwareMacOS package
    }
}
#endif
