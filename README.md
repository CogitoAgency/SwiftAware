# Aware

**SwiftUI instrumentation framework for LLM-driven UI testing**

[![Swift Version](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2017%2B%20%7C%20macOS%2014%2B-blue.svg)](https://developer.apple.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Why Aware?

Testing UIs with LLMs is expensive and slow:
- **Screenshots**: 10,000-20,000 tokens per test (💸 $$$)
- **Accessibility Tree**: 1,000-2,000 tokens (📊 structure only, no state)
- **Aware**: **100-120 tokens** (✨ full state + hierarchy)

**Result**: 99.3% token reduction vs screenshots. Test faster, spend less.

## Key Features

🎯 **Ghost UI** - LLMs test without moving your mouse
📊 **Rich State** - Exact values, not visual appearance
⚡ **Token Efficient** - 80% reduction vs traditional methods
🔍 **Staleness Detection** - Know when @State fails to update
♿ **WCAG Auditing** - Built-in accessibility compliance checking
📈 **Performance Budgeting** - Assert action speeds (lenient/standard/strict)
🎨 **Visual Regression** - Detect unintended UI changes

## Quick Start

### Installation

Add Aware to your Swift package dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/cogitolabs/Aware", from: "2.0.0")
]
```

### Basic Usage

```swift
import Aware

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack {
            TextField("Email", text: $email)
                .awareTextField("email-field", text: $email, label: "Email", isFocused: $focused)

            SecureField("Password", text: $password)
                .awareSecureField("password-field", text: $password, label: "Password")

            Button("Login") { login() }
                .awareButton("login-btn", label: "Login")
        }
        .awareContainer("login-form", label: "Login Form")
    }
}
```

### Get Snapshot

```swift
let snapshot = await Aware.shared.snapshot(format: .compact)
// Returns: ~100 tokens with full UI state
```

### Ghost UI Testing

```swift
// LLM tests without moving mouse!
await Aware.shared.typeText(viewId: "email-field", text: "user@example.com")
await Aware.shared.typeText(viewId: "password-field", text: "secure123")

// Verify state
let emailValue = Aware.shared.getState("email-field", key: "value")
assert(emailValue == "user@example.com")
```

## Token Efficiency

For a typical login form:

| Method | Tokens | Cost (per test) |
|--------|--------|-----------------|
| Screenshot (2048×1536) | ~15,000 | $0.045 |
| Accessibility Tree | ~1,500 | $0.0045 |
| **Aware Compact** | **~110** | **$0.00033** |

**Run 10,000 tests**:
- Screenshots: $450 💸
- Accessibility: $45
- **Aware: $3.30** ✨

## Documentation

- 📖 [Full Documentation (CLAUDE.md)](CLAUDE.md) - Comprehensive guide
- 🎯 [API Reference](CLAUDE.md#api-reference) - All methods and modifiers
- 💡 [Examples](/Examples) - Sample implementations
- 🐛 [Troubleshooting](CLAUDE.md#build-troubleshooting) - Common issues

## Use Cases

### 1. Automated UI Testing
```swift
// Test complete flows without screenshots
let snapshot1 = await Aware.shared.snapshot(format: .compact)
// Verify login form visible

await Aware.shared.typeText(viewId: "email-field", text: "test@example.com")
await Aware.shared.typeText(viewId: "password-field", text: "password")

let snapshot2 = await Aware.shared.snapshot(format: .compact)
// Verify fields populated

// LLM can now click login button via ghost UI
```

### 2. Accessibility Auditing
```swift
let audit = await AwareAccessibilityAuditor.shared.audit(level: .AA)
if !audit.passed {
    print("Accessibility issues:")
    for issue in audit.issues {
        print("- [\(issue.severity)] \(issue.description)")
    }
}
```

### 3. Performance Monitoring
```swift
let metrics = await AwarePerformanceMonitor.shared.measure {
    await Aware.shared.typeText(viewId: "search-field", text: "query")
}
await AwarePerformanceAsserter.shared.assertWithinBudget(metrics, budget: .standard)
```

### 4. Visual Regression Testing
```swift
// Capture baseline
await AwareVisualTest.shared.captureBaseline(name: "settings-view")

// Later, after changes
let regression = await AwareVisualTest.shared.detectRegression(name: "settings-view")
if regression != nil {
    print("⚠️ UI changed unexpectedly!")
}
```

## Breathe Integration

Aware is the core framework powering [Breathe IDE](https://breathe.cogito.cv), an AI-native development environment. Breathe adds:

- **MCP Tools**: 13+ tools for Claude Code integration
- **Multi-App Testing**: Test any macOS app or iOS Simulator
- **Intelligence Features**: Auto-diagnosis, error recovery, test generation
- **Cost Tracking**: Monitor AI development costs
- **Overnight Execution**: Queue multi-day work sprints

## Requirements

- Swift 5.9+
- iOS 17+ / macOS 14+
- Xcode 15.2+

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

Aware is released under the MIT License. See [LICENSE](LICENSE) for details.

## Links

- [GitHub Repository](https://github.com/cogitolabs/Aware)
- [Documentation](CLAUDE.md)
- [Breathe IDE](https://breathe.cogito.cv)
- [Issue Tracker](https://github.com/cogitolabs/Aware/issues)
- [Cogito Labs](https://cogito.cv)

---

**Save 40%+ on AI development costs. Test smarter with Aware.**
