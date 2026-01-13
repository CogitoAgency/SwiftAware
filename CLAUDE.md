# Aware Framework

SwiftUI instrumentation framework for LLM-driven UI testing.

## Core Philosophy
- **Ghost UI**: LLM tests without moving mouse
- **80% Token Reduction**: 100-120 tokens vs 500-600 for screenshots
- **Rich State**: Exact values, not visual appearance
- **Staleness Detection**: Know when @State fails to update

## Installation

### Swift Package Manager
```swift
dependencies: [
    .package(url: "https://github.com/cogitolabs/Aware", from: "2.0.0")
]
```

## Quick Start

### Basic Instrumentation
```swift
import Aware

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack {
            TextField("Email", text: $email)
                .awareTextField("email-field", text: $email, label: "Email", isFocused: $focusedField)

            SecureField("Password", text: $password)
                .awareSecureField("password-field", text: $password, label: "Password")

            Button("Login") { login() }
                .awareButton("login-btn", label: "Login")
                .awareMetadata(
                    "login-btn",
                    description: "Authenticates user with email/password",
                    type: .network,
                    apiEndpoint: "/auth/login"
                )
        }
        .awareContainer("login-form", label: "Login Form")
    }
}
```

### Getting Snapshots
```swift
let snapshot = await Aware.shared.snapshot(format: .compact)
// Returns: ~100 tokens with all UI state
```

### Ghost UI Testing
```swift
// Test text input without moving mouse
await Aware.shared.typeText(viewId: "email-field", text: "user@example.com")

// Verify state
let emailState = Aware.shared.getState("email-field", key: "value")
assert(emailState == "user@example.com")
```

## Available Modifiers

| Modifier | Use Case | Example |
|----------|----------|---------|
| `.aware()` | Basic view registration | `.aware("view-id", label: "My View")` |
| `.awareContainer()` | Group related elements | `.awareContainer("form", label: "Login Form")` |
| `.awareButton()` | Track button taps | `.awareButton("save-btn", label: "Save")` |
| `.awareTextField()` | Track text input with focus | `.awareTextField("email", text: $email, label: "Email", isFocused: $focused)` |
| `.awareSecureField()` | Track password input (secure) | `.awareSecureField("pwd", text: $password, label: "Password")` |
| `.awareState()` | Track any state | `.awareState("view-id", key: "isEnabled", value: enabled)` |
| `.awareMetadata()` | Add action semantics | `.awareMetadata("btn-id", description: "Saves file", type: .fileSystem)` |
| `.awareBehavior()` | Add backend behavior | `.awareBehavior("list", dataSource: "REST API", refreshTrigger: "onAppear")` |
| `.awareFocus()` | Track focus/hover state | `.awareFocus("input-id")` |
| `.awareScroll()` | Track scroll position | `.awareScroll("scrollview-id")` |
| `.awareAnimation()` | Track animation state | `.awareAnimation("view-id", type: "spring", duration: 0.3, isAnimating: $animating)` |

## Testing Features

### Performance Budgeting
```swift
let metrics = await AwarePerformanceMonitor.shared.measure {
    await Aware.shared.typeText(viewId: "search-field", text: "query")
}
await AwarePerformanceAsserter.shared.assertWithinBudget(metrics, budget: .standard)
```

**Budget Levels**:
- `.lenient`: 500ms (good for complex operations)
- `.standard`: 250ms (recommended for most actions)
- `.strict`: 100ms (for instant feedback)

### WCAG Accessibility Auditing
```swift
let audit = await AwareAccessibilityAuditor.shared.audit(level: .AA)
// Checks: Color contrast, touch targets, label requirements
```

**Audit Levels**:
- `.A`: Minimum compliance
- `.AA`: Recommended (WCAG 2.1 Level AA)
- `.AAA`: Enhanced accessibility

### Visual Regression Testing
```swift
// Capture baseline
let baseline = await AwareVisualTest.shared.captureBaseline(name: "login-view")

// Later, detect changes
let regression = await AwareVisualTest.shared.detectRegression(name: "login-view")
if let regression = regression {
    print("Regression detected: \(regression.changedElements)")
}
```

### Coverage Tracking
```swift
let coverage = await AwareCoverage.shared.getCoverage()
print("Views visited: \(coverage.visitedViews.count)/\(coverage.totalViews)")
print("Actions taken: \(coverage.actionsCovered.count)/\(coverage.totalActions)")
```

## Snapshot Formats

| Format | Token Count | Use Case |
|--------|-------------|----------|
| `compact` | 100-120 | LLM consumption (recommended) |
| `text` | 200-300 | Human-readable tree |
| `json` | 300-500 | Programmatic parsing |
| `markdown` | 250-400 | Documentation |

```swift
// Get compact snapshot for LLM
let compact = await Aware.shared.snapshot(format: .compact)

// Get JSON for programmatic use
let json = await Aware.shared.snapshot(format: .json)
```

## Advanced Features

### Focus Management
```swift
// Navigate focus programmatically
await AwareFocusManager.shared.focusNext() // Tab to next field
await AwareFocusManager.shared.focusPrevious() // Shift+Tab
await AwareFocusManager.shared.focus("email-field") // Focus specific field
```

### Action Metadata
Action metadata helps LLMs understand what buttons do before clicking them:

```swift
Button("Delete Account") { deleteAccount() }
    .awareButton("delete-btn", label: "Delete Account")
    .awareMetadata(
        "delete-btn",
        description: "Permanently deletes user account and all data",
        type: .destructive,
        isDestructive: true,
        requiresConfirmation: true,
        sideEffects: ["deletes data", "logs out", "sends email"]
    )
```

### Behavior Metadata
Behavior metadata describes data flow and backend integration:

```swift
List(users) { user in
    UserRow(user: user)
}
.awareContainer("user-list", label: "Users")
.awareBehavior(
    "user-list",
    dataSource: "REST API",
    refreshTrigger: "onAppear",
    cacheDuration: "5m",
    errorHandling: "retry(3)",
    loadingBehavior: "skeleton",
    boundModel: "User"
)
```

## Breathe Integration

This is the **standalone** Aware framework. For **Breathe IDE users**, additional features are available:
- **MCP Integration**: 13+ tools for Claude Code (`ui_snapshot`, `ui_action`, `ui_wait`)
- **Multi-App Control**: Test any macOS app or iOS Simulator
- **Intelligence Features**: Blocker diagnostics, error recovery, test generation
- **Instrumentation Guidance**: Code analysis suggestions

See Breathe's CLAUDE.md for ecosystem-specific features.

## Token Efficiency Comparison

| Method | Tokens | Accuracy | Speed |
|--------|--------|----------|-------|
| Screenshots | 10,000-20,000 | Visual only | Slow (encoding) |
| Accessibility Tree | 1,000-2,000 | Structure only | Fast |
| **Aware Compact** | **100-120** | **Full state** | **Instant** |

### Example Token Savings
For a typical login form:
- **Screenshot**: ~15,000 tokens (2048×1536 PNG)
- **Accessibility Tree**: ~1,500 tokens (structure only, no state)
- **Aware Compact**: ~110 tokens (full state + hierarchy)

**Result**: 99.3% reduction vs screenshots, 93% reduction vs accessibility.

## Examples

See `/Examples` directory for:
- **SimpleLogin**: Login form with validation
- **SettingsPanel**: Settings with toggles and pickers
- **DataTable**: Sortable table with pagination
- **MultiStepWizard**: Wizard with navigation and state

## Build Troubleshooting

### Common Issues

#### SPM Cache Corruption
If you encounter build errors or missing dependencies:

```bash
# 1. Close Xcode
# 2. Clear all SPM caches
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf .build
rm -rf *.xcodeproj
rm -rf Package.resolved

# 3. Rebuild
swift build
```

#### Xcode Project Issues
If using xcodegen and encountering project issues:

```bash
# Regenerate Xcode project
xcodegen generate
xcodebuild -scheme Aware -configuration Debug build
```

#### Verify Package Health
```bash
swift package show-dependencies
swift package dump-package
swift test  # Run all tests
```

### Build Before Test
**Always verify build succeeds before running tests.** Failed tests due to build issues waste time and tokens.

## API Reference

### AwareService (Singleton)

Main service for view registration and snapshot generation.

```swift
// Registration
await Aware.shared.registerView(_ id: String, label: String?, isContainer: Bool, parentId: String?)
await Aware.shared.unregisterView(_ id: String)

// State tracking
await Aware.shared.registerState(_ viewId: String, key: String, value: String)
await Aware.shared.getState(_ viewId: String, key: String) -> String?

// Text binding (for ghost UI typing)
await Aware.shared.registerTextBinding(_ viewId: String, binding: AwareTextBinding)
await Aware.shared.typeText(viewId: String, text: String)

// Snapshots
await Aware.shared.snapshot(format: AwareSnapshotFormat) -> String

// Metadata
await Aware.shared.registerAction(_ viewId: String, action: AwareActionMetadata)
await Aware.shared.registerBehavior(_ viewId: String, behavior: AwareBehaviorMetadata)
```

### AwareFocusManager (Singleton)

Manages keyboard focus navigation.

```swift
await AwareFocusManager.shared.registerFocus(_ viewId: String, binding: Binding<Bool>, order: Int?)
await AwareFocusManager.shared.focus(_ viewId: String)
await AwareFocusManager.shared.focusNext()
await AwareFocusManager.shared.focusPrevious()
```

### AwareLogger (Singleton)

Lifecycle event logging for debugging.

```swift
await AwareLogger.shared.appeared(_ viewId: String, _ label: String?)
await AwareLogger.shared.disappeared(_ viewId: String)
await AwareLogger.shared.tapped(_ viewId: String)
await AwareLogger.shared.stateChanged(_ viewId: String, key: String, value: String)
```

## Best Practices

### 1. Instrument Early
Add `.aware*()` modifiers during development, not as an afterthought. This enables continuous testing.

### 2. Use Semantic IDs
```swift
// Good: Describes what it is
.awareButton("save-document-btn", label: "Save")

// Bad: Generic or cryptic
.awareButton("btn1", label: "Save")
```

### 3. Add Metadata to Actions
Help LLMs understand intent:
```swift
Button("Sync") { sync() }
    .awareButton("sync-btn", label: "Sync")
    .awareMetadata(
        "sync-btn",
        description: "Synchronizes local data with remote server",
        type: .network,
        apiEndpoint: "/api/sync"
    )
```

### 4. Track Important State
```swift
Toggle("Dark Mode", isOn: $darkMode)
    .awareState("settings-darkmode", key: "enabled", value: darkMode)
```

### 5. Container Hierarchy
Organize views with containers for better snapshot structure:
```swift
VStack {
    headerView
    contentView
    footerView
}
.awareContainer("main-screen", label: "Main Screen")
```

## Migration from 1.x to 2.0

### Breaking Changes
- `awareTextBinding()` renamed to `awareTextField()` for consistency
- Focus management now uses `AwareFocusManager` singleton

### New Features
- `.awareSecureField()` for password fields
- `.awareMetadata()` for action semantics
- `.awareBehavior()` for backend metadata
- Performance budgeting
- WCAG auditing
- Visual regression testing

### Migration Steps
```swift
// Old (1.x)
TextField("Email", text: $email)
    .awareTextBinding("email", text: $email, label: "Email")

// New (2.0)
TextField("Email", text: $email)
    .awareTextField("email", text: $email, label: "Email", isFocused: $focused)
```

## Contributing

Contributions welcome! See CONTRIBUTING.md for guidelines.

## License

MIT License - see LICENSE file for details.

## Links

- [GitHub Repository](https://github.com/cogitolabs/Aware)
- [Documentation](https://docs.cogito.cv/aware)
- [Breathe IDE](https://breathe.cogito.cv) - Full ecosystem integration
- [Issue Tracker](https://github.com/cogitolabs/Aware/issues)

---

**Version**: 2.0.0
**Last Updated**: 2026-01-12
**Minimum Requirements**: iOS 17+, macOS 14+
