//
//  Aware.swift
//  Aware
//
//  Umbrella module for backward compatibility.
//  Re-exports platform-specific modules based on compilation target.
//

// MARK: - Core Re-Exports

/// Re-export everything from AwareCore
@_exported import AwareCore

// MARK: - Platform-Specific Re-Exports

#if os(iOS)
/// Re-export iOS platform module
@_exported import AwareiOS

/// Convenience typealias for backward compatibility
public typealias AwareShared = Aware
#elseif os(macOS)
/// Re-export macOS platform module
@_exported import AwareMacOS

/// Convenience typealias for backward compatibility
public typealias AwareShared = Aware
#endif
