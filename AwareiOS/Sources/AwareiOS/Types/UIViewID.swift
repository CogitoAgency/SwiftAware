//
//  UIViewID.swift
//  AwareiOS
//
//  Stable view identifiers to prevent ID drift across codebase.
//  Inspired by AetherSing's successful pattern for maintaining consistent IDs.
//

#if os(iOS)
import Foundation

// MARK: - UIViewID Protocol

/// Protocol for type-safe view identifiers
public protocol UIViewIdentifier: RawRepresentable, Hashable, Sendable where RawValue == String {
    var rawValue: String { get }
}

// MARK: - Default UIViewID Enum

/// Common view identifiers used across typical iOS apps
public enum UIViewID: String, UIViewIdentifier {
    // MARK: - Authentication
    case signInView = "signInView"
    case signUpView = "signUpView"
    case emailField = "emailField"
    case passwordField = "passwordField"
    case confirmPasswordField = "confirmPasswordField"
    case signInButton = "signInButton"
    case signUpButton = "signUpButton"
    case forgotPasswordButton = "forgotPasswordButton"
    case socialSignInButton = "socialSignInButton"

    // MARK: - Navigation
    case tabBar = "tabBar"
    case homeTab = "homeTab"
    case searchTab = "searchTab"
    case profileTab = "profileTab"
    case settingsTab = "settingsTab"
    case navigationBar = "navigationBar"
    case backButton = "backButton"
    case closeButton = "closeButton"

    // MARK: - Home/Dashboard
    case homeView = "homeView"
    case dashboardView = "dashboardView"
    case mainContent = "mainContent"
    case headerView = "headerView"
    case footerView = "footerView"

    // MARK: - Lists and Collections
    case listView = "listView"
    case collectionView = "collectionView"
    case tableView = "tableView"
    case searchBar = "searchBar"
    case filterButton = "filterButton"
    case sortButton = "sortButton"
    case refreshControl = "refreshControl"

    // MARK: - Detail Views
    case detailView = "detailView"
    case titleLabel = "titleLabel"
    case subtitleLabel = "subtitleLabel"
    case descriptionText = "descriptionText"
    case imageView = "imageView"
    case actionButton = "actionButton"

    // MARK: - Forms
    case formView = "formView"
    case textField = "textField"
    case textArea = "textArea"
    case submitButton = "submitButton"
    case cancelButton = "cancelButton"
    case saveButton = "saveButton"
    case deleteButton = "deleteButton"

    // MARK: - Settings
    case settingsView = "settingsView"
    case profileSection = "profileSection"
    case preferencesSection = "preferencesSection"
    case notificationsToggle = "notificationsToggle"
    case darkModeToggle = "darkModeToggle"
    case logoutButton = "logoutButton"

    // MARK: - Modals and Alerts
    case modalView = "modalView"
    case alertView = "alertView"
    case confirmButton = "confirmButton"
    case dismissButton = "dismissButton"

    // MARK: - Loading and Error States
    case loadingView = "loadingView"
    case errorView = "errorView"
    case retryButton = "retryButton"
    case emptyStateView = "emptyStateView"

    // MARK: - Media
    case videoPlayer = "videoPlayer"
    case audioPlayer = "audioPlayer"
    case playButton = "playButton"
    case pauseButton = "pauseButton"
    case volumeSlider = "volumeSlider"

    // MARK: - Search
    case searchView = "searchView"
    case searchResultsList = "searchResultsList"
    case filterView = "filterView"
    case clearSearchButton = "clearSearchButton"
}

// MARK: - Custom ViewID Support

/// Extension to allow custom view IDs beyond the predefined enum
extension UIViewIdentifier {
    /// Create a custom view ID from a string
    public static func custom(_ id: String) -> String {
        return id
    }
}

// MARK: - Convenience Extensions

extension UIViewIdentifier {
    /// Generate a scoped ID by combining parent and child
    /// Example: UIViewID.homeView.scoped("header") -> "homeView.header"
    public func scoped(_ child: String) -> String {
        return "\(rawValue).\(child)"
    }

    /// Generate an indexed ID for items in collections
    /// Example: UIViewID.listView.indexed(0) -> "listView[0]"
    public func indexed(_ index: Int) -> String {
        return "\(rawValue)[\(index)]"
    }

    /// Generate a suffixed ID for variations
    /// Example: UIViewID.signInButton.suffixed("primary") -> "signInButton-primary"
    public func suffixed(_ suffix: String) -> String {
        return "\(rawValue)-\(suffix)"
    }
}

#endif // os(iOS)
