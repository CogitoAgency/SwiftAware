# LLM-Optimized Snapshot Format Specification

**Version:** 1.0.0
**Date:** 2026-01-14
**Target:** Claude Code, GPT-4, and other LLMs
**Goal:** Self-describing UI state in ~200 tokens

---

## Design Principles

1. **Natural Language First** - LLMs understand English better than code
2. **Self-Describing** - No external docs needed
3. **Intent-Aware** - Explain *why* elements exist, not just *what* they are
4. **Actionable** - Tell LLM what to do next
5. **Causality-Aware** - Show relationships between elements

---

## Format Comparison

### Current "Compact" Format (110 tokens)

```
LoginView#main
  TextField#email[value="", label="Email"]
  SecureField#password[value="", label="Password"]
  Button#login[enabled, label="Login"]
```

**Good**:
- ✅ Token efficient (110 tokens)
- ✅ Hierarchical structure

**Bad**:
- ❌ No context (why does this view exist?)
- ❌ No guidance (what should LLM do?)
- ❌ No validation rules (what's required?)
- ❌ No next steps (what happens after?)

---

### New "LLM" Format (200 tokens)

```json
{
  "view": {
    "id": "main",
    "type": "LoginView",
    "intent": "Authenticate user with email and password",
    "state": "ready",
    "elements": [
      {
        "id": "email",
        "type": "TextField",
        "label": "Email",
        "value": "",
        "state": "empty",
        "required": true,
        "validation": "Must be valid email format",
        "placeholder": "your@email.com",
        "nextAction": "Enter email address",
        "errorIfInvalid": "Invalid email format"
      },
      {
        "id": "password",
        "type": "SecureField",
        "label": "Password",
        "value": "",
        "state": "empty",
        "required": true,
        "validation": "Minimum 8 characters",
        "nextAction": "Enter password",
        "secure": true
      },
      {
        "id": "login",
        "type": "Button",
        "label": "Login",
        "enabled": true,
        "state": "ready",
        "action": "Submit login credentials",
        "nextView": "DashboardView",
        "failureView": "LoginView with error",
        "dependencies": ["email must be filled", "password must be filled"]
      }
    ],
    "testSuggestions": [
      "Fill email field with valid email",
      "Fill password field with valid password",
      "Tap login button",
      "Expect navigation to DashboardView",
      "Test invalid email format",
      "Test empty password"
    ]
  },
  "meta": {
    "timestamp": "2026-01-14T10:30:00Z",
    "tokenCount": 195
  }
}
```

**Better**:
- ✅ Intent explained ("Authenticate user...")
- ✅ Validation rules ("Must be valid email format")
- ✅ Next actions ("Enter email address")
- ✅ Expected outcomes ("Navigation to DashboardView")
- ✅ Test suggestions (6 scenarios)
- ✅ Still efficient (195 tokens vs 15,000 screenshot)

---

## Detailed Schema

### Root Object

```typescript
interface AwareLLMSnapshot {
  view: ViewDescriptor
  meta: SnapshotMeta
}
```

---

### ViewDescriptor

```typescript
interface ViewDescriptor {
  // Identity
  id: string                    // "main"
  type: string                  // "LoginView"

  // Semantics
  intent: string                // "Authenticate user with email and password"
  state: ViewState              // "ready" | "loading" | "error" | "success"

  // Hierarchy
  elements: ElementDescriptor[]

  // LLM Guidance
  testSuggestions: string[]     // What to test
  commonErrors?: string[]       // What usually goes wrong

  // Navigation
  canNavigateBack?: boolean
  previousView?: string
  modalPresentation?: boolean
}

type ViewState =
  | "ready"           // Ready for interaction
  | "loading"         // Waiting for data/action
  | "error"           // Error state
  | "success"         // Action succeeded
  | "disabled"        // Interaction disabled
```

---

### ElementDescriptor

```typescript
interface ElementDescriptor {
  // Identity
  id: string                    // "email"
  type: ElementType             // "TextField"
  label: string                 // "Email"

  // Current State
  value: string                 // ""
  state: ElementState           // "empty"
  enabled: boolean              // true
  visible: boolean              // true
  focused?: boolean             // false

  // Validation
  required?: boolean            // true
  validation?: string           // "Must be valid email format"
  errorMessage?: string         // Current error (if any)
  placeholder?: string          // "your@email.com"

  // LLM Guidance
  nextAction: string            // "Enter email address"
  exampleValue?: string         // "test@example.com"

  // Behavior (for buttons/actions)
  action?: string               // "Submit login credentials"
  nextView?: string             // "DashboardView"
  failureView?: string          // "LoginView with error"
  dependencies?: string[]       // ["email must be filled"]

  // Accessibility
  accessibilityLabel?: string
  accessibilityHint?: string

  // Position (optional, for layout understanding)
  frame?: {
    x: number
    y: number
    width: number
    height: number
  }
}

type ElementType =
  | "TextField"
  | "SecureField"
  | "Button"
  | "Toggle"
  | "Picker"
  | "Slider"
  | "Text"
  | "Image"
  | "Link"
  | "Container"
  | "List"
  | "NavigationBar"
  | "TabBar"

type ElementState =
  | "empty"           // No value
  | "filled"          // Has value
  | "valid"           // Value passes validation
  | "invalid"         // Value fails validation
  | "focused"         // Currently focused
  | "disabled"        // Interaction disabled
  | "loading"         // Action in progress
  | "error"           // Error occurred
```

---

### SnapshotMeta

```typescript
interface SnapshotMeta {
  timestamp: string             // ISO 8601
  tokenCount: number            // Actual tokens used
  format: "llm"                 // Format identifier
  version: "1.0.0"              // Schema version
  app?: string                  // "MyApp"
  device?: string               // "iPhone 15 Pro"
}
```

---

## Examples

### Example 1: Login View (Empty)

```json
{
  "view": {
    "id": "main",
    "type": "LoginView",
    "intent": "Authenticate user with email and password",
    "state": "ready",
    "elements": [
      {
        "id": "email",
        "type": "TextField",
        "label": "Email",
        "value": "",
        "state": "empty",
        "enabled": true,
        "visible": true,
        "required": true,
        "validation": "Must be valid email format",
        "placeholder": "your@email.com",
        "nextAction": "Enter email address",
        "exampleValue": "test@example.com"
      },
      {
        "id": "password",
        "type": "SecureField",
        "label": "Password",
        "value": "",
        "state": "empty",
        "enabled": true,
        "visible": true,
        "required": true,
        "validation": "Minimum 8 characters",
        "nextAction": "Enter password"
      },
      {
        "id": "login",
        "type": "Button",
        "label": "Login",
        "enabled": false,
        "visible": true,
        "state": "disabled",
        "action": "Submit login credentials",
        "dependencies": ["email must be valid", "password must be filled"]
      }
    ],
    "testSuggestions": [
      "Fill email with 'test@example.com'",
      "Fill password with 'password123'",
      "Verify login button becomes enabled",
      "Tap login button",
      "Expect navigation to Dashboard"
    ]
  },
  "meta": {
    "timestamp": "2026-01-14T10:30:00Z",
    "tokenCount": 178,
    "format": "llm",
    "version": "1.0.0"
  }
}
```

**LLM understands**:
- This is a login screen (intent)
- Email and password are required
- Login button disabled until both filled
- Validation rules for each field
- What to do next (test suggestions)

---

### Example 2: Login View (Filled, Validation Error)

```json
{
  "view": {
    "id": "main",
    "type": "LoginView",
    "intent": "Authenticate user with email and password",
    "state": "error",
    "elements": [
      {
        "id": "email",
        "type": "TextField",
        "label": "Email",
        "value": "invalid-email",
        "state": "invalid",
        "enabled": true,
        "visible": true,
        "focused": true,
        "required": true,
        "validation": "Must be valid email format",
        "errorMessage": "Invalid email format",
        "nextAction": "Enter valid email address"
      },
      {
        "id": "password",
        "type": "SecureField",
        "label": "Password",
        "value": "••••••••",
        "state": "filled",
        "enabled": true,
        "visible": true
      },
      {
        "id": "login",
        "type": "Button",
        "label": "Login",
        "enabled": false,
        "visible": true,
        "state": "disabled",
        "dependencies": ["email must be valid"]
      },
      {
        "id": "error-message",
        "type": "Text",
        "label": "Invalid email format",
        "visible": true,
        "state": "error"
      }
    ],
    "testSuggestions": [
      "Fix email to valid format",
      "Verify error message disappears",
      "Verify login button becomes enabled"
    ],
    "commonErrors": [
      "User entered email without @ symbol",
      "User forgot domain (.com, .net, etc.)"
    ]
  },
  "meta": {
    "timestamp": "2026-01-14T10:31:00Z",
    "tokenCount": 165,
    "format": "llm",
    "version": "1.0.0"
  }
}
```

**LLM understands**:
- View is in error state
- Email field has validation error
- Specific error message shown
- Login button disabled because email invalid
- How to fix (enter valid email)

---

### Example 3: Login View (Loading)

```json
{
  "view": {
    "id": "main",
    "type": "LoginView",
    "intent": "Authenticate user with email and password",
    "state": "loading",
    "elements": [
      {
        "id": "email",
        "type": "TextField",
        "label": "Email",
        "value": "test@example.com",
        "state": "filled",
        "enabled": false,
        "visible": true
      },
      {
        "id": "password",
        "type": "SecureField",
        "label": "Password",
        "value": "••••••••",
        "state": "filled",
        "enabled": false,
        "visible": true
      },
      {
        "id": "login",
        "type": "Button",
        "label": "Logging in...",
        "enabled": false,
        "visible": true,
        "state": "loading",
        "action": "Waiting for authentication response"
      },
      {
        "id": "spinner",
        "type": "ActivityIndicator",
        "visible": true,
        "state": "animating"
      }
    ],
    "testSuggestions": [
      "Wait for loading to complete",
      "Expect navigation to Dashboard on success",
      "Expect error message on failure",
      "Test network timeout scenario"
    ]
  },
  "meta": {
    "timestamp": "2026-01-14T10:32:00Z",
    "tokenCount": 142,
    "format": "llm",
    "version": "1.0.0"
  }
}
```

**LLM understands**:
- Authentication in progress
- All inputs disabled (loading state)
- Should wait for completion
- Two possible outcomes (success or error)

---

### Example 4: Dashboard (After Login)

```json
{
  "view": {
    "id": "main",
    "type": "DashboardView",
    "intent": "Show user dashboard after successful login",
    "state": "success",
    "previousView": "LoginView",
    "elements": [
      {
        "id": "greeting",
        "type": "Text",
        "label": "Welcome, test@example.com",
        "visible": true,
        "state": "success"
      },
      {
        "id": "logout",
        "type": "Button",
        "label": "Logout",
        "enabled": true,
        "visible": true,
        "action": "End user session",
        "nextView": "LoginView"
      },
      {
        "id": "profile",
        "type": "Button",
        "label": "Profile",
        "enabled": true,
        "visible": true,
        "action": "View user profile",
        "nextView": "ProfileView"
      }
    ],
    "testSuggestions": [
      "Verify user email shown in greeting",
      "Tap logout button",
      "Expect navigation back to LoginView",
      "Verify session cleared"
    ]
  },
  "meta": {
    "timestamp": "2026-01-14T10:33:00Z",
    "tokenCount": 125,
    "format": "llm",
    "version": "1.0.0"
  }
}
```

**LLM understands**:
- Login succeeded (state: success)
- User info displayed (email in greeting)
- Available actions (logout, profile)
- Can verify end-to-end flow

---

## Token Efficiency Analysis

### Comparison

| Format | Tokens | Contains |
|--------|--------|----------|
| **Screenshot** | 15,000 | Visual pixels |
| **Accessibility Tree** | 1,500 | Element hierarchy |
| **Aware Compact** | 110 | IDs + states |
| **Aware LLM** | 200 | Everything above + intent + guidance |

### Token Breakdown (LLM Format)

```
View metadata:     30 tokens
  - id, type, intent, state

Elements (3):      140 tokens
  - Email field:     50 tokens
  - Password field:  45 tokens
  - Login button:    45 tokens

Test suggestions:  25 tokens
  - 5 suggestions

Meta:              5 tokens
  - timestamp, token count

Total:             200 tokens
```

### ROI

**Cost per snapshot**:
- Screenshot: 15,000 tokens × $3/M = $0.045
- LLM format: 200 tokens × $3/M = $0.0006

**Savings**: 98.7% reduction, still self-describing

---

## Implementation Guide

### Step 1: Define Swift Types

```swift
// AwareCore/Sources/AwareCore/Snapshots/AwareLLMSnapshot.swift

public struct AwareLLMSnapshot: Codable {
    public let view: ViewDescriptor
    public let meta: SnapshotMeta
}

public struct ViewDescriptor: Codable {
    public let id: String
    public let type: String
    public let intent: String
    public let state: ViewState
    public let elements: [ElementDescriptor]
    public let testSuggestions: [String]
    public let commonErrors: [String]?
    public let canNavigateBack: Bool?
    public let previousView: String?
    public let modalPresentation: Bool?
}

public enum ViewState: String, Codable {
    case ready
    case loading
    case error
    case success
    case disabled
}

public struct ElementDescriptor: Codable {
    // Identity
    public let id: String
    public let type: ElementType
    public let label: String

    // State
    public let value: String
    public let state: ElementState
    public let enabled: Bool
    public let visible: Bool
    public let focused: Bool?

    // Validation
    public let required: Bool?
    public let validation: String?
    public let errorMessage: String?
    public let placeholder: String?

    // Guidance
    public let nextAction: String
    public let exampleValue: String?

    // Behavior
    public let action: String?
    public let nextView: String?
    public let failureView: String?
    public let dependencies: [String]?

    // Accessibility
    public let accessibilityLabel: String?
    public let accessibilityHint: String?

    // Position
    public let frame: CGRect?
}

public enum ElementType: String, Codable {
    case textField = "TextField"
    case secureField = "SecureField"
    case button = "Button"
    case toggle = "Toggle"
    case picker = "Picker"
    case slider = "Slider"
    case text = "Text"
    case image = "Image"
    case link = "Link"
    case container = "Container"
    case list = "List"
    case navigationBar = "NavigationBar"
    case tabBar = "TabBar"
}

public enum ElementState: String, Codable {
    case empty
    case filled
    case valid
    case invalid
    case focused
    case disabled
    case loading
    case error
}

public struct SnapshotMeta: Codable {
    public let timestamp: String
    public let tokenCount: Int
    public let format: String
    public let version: String
    public let app: String?
    public let device: String?
}
```

---

### Step 2: Update AwareService

```swift
// AwareCore/Sources/AwareCore/Services/AwareService.swift

extension Aware {
    public func snapshot(format: AwareSnapshotFormat) async -> String {
        switch format {
        case .compact:
            return generateCompactSnapshot()
        case .llm:
            return generateLLMSnapshot()  // NEW
        case .text, .json, .markdown, .accessibility:
            // Existing formats
        }
    }

    private func generateLLMSnapshot() -> String {
        // 1. Get current view
        let currentView = getCurrentView()

        // 2. Build view descriptor
        let viewDescriptor = ViewDescriptor(
            id: currentView.id,
            type: currentView.typeName,
            intent: inferIntent(from: currentView),  // NEW: Infer intent
            state: inferState(from: currentView),    // NEW: Infer state
            elements: currentView.children.map { buildElementDescriptor($0) },
            testSuggestions: generateTestSuggestions(for: currentView),  // NEW
            commonErrors: getCommonErrors(for: currentView),
            canNavigateBack: currentView.canNavigateBack,
            previousView: navigationStack.last,
            modalPresentation: currentView.isModal
        )

        // 3. Build meta
        let meta = SnapshotMeta(
            timestamp: ISO8601DateFormatter().string(from: Date()),
            tokenCount: 0,  // Calculate after encoding
            format: "llm",
            version: "1.0.0",
            app: Bundle.main.bundleIdentifier,
            device: UIDevice.current.model
        )

        // 4. Create snapshot
        let snapshot = AwareLLMSnapshot(view: viewDescriptor, meta: meta)

        // 5. Encode to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try! encoder.encode(snapshot)
        let json = String(data: data, encoding: .utf8)!

        // 6. Calculate actual token count (rough estimate: chars / 4)
        let tokenCount = json.count / 4

        return json
    }

    // NEW: Infer intent from view type
    private func inferIntent(from view: AwareViewSnapshot) -> String {
        // Simple heuristics (can be improved with ML)
        let name = view.typeName.lowercased()

        if name.contains("login") {
            return "Authenticate user with email and password"
        } else if name.contains("signup") || name.contains("register") {
            return "Create new user account"
        } else if name.contains("dashboard") || name.contains("home") {
            return "Show main user dashboard"
        } else if name.contains("profile") {
            return "Display and edit user profile"
        } else if name.contains("settings") {
            return "Configure app settings"
        } else {
            return "Display \(view.typeName) content"
        }
    }

    // NEW: Infer view state
    private func inferState(from view: AwareViewSnapshot) -> ViewState {
        // Check for loading indicators
        if view.children.contains(where: { $0.type == "ActivityIndicator" }) {
            return .loading
        }

        // Check for error messages
        if view.children.contains(where: {
            $0.type == "Text" && $0.label?.lowercased().contains("error") == true
        }) {
            return .error
        }

        // Check for success indicators
        if view.children.contains(where: {
            $0.type == "Text" && ($0.label?.lowercased().contains("success") == true ||
                                  $0.label?.lowercased().contains("welcome") == true)
        }) {
            return .success
        }

        // Default to ready
        return .ready
    }

    // NEW: Generate test suggestions
    private func generateTestSuggestions(for view: AwareViewSnapshot) -> [String] {
        var suggestions: [String] = []

        // Find text fields
        let textFields = view.children.filter { $0.type == "TextField" || $0.type == "SecureField" }
        for field in textFields {
            suggestions.append("Fill \(field.label ?? field.id) with valid value")
        }

        // Find buttons
        let buttons = view.children.filter { $0.type == "Button" && $0.enabled }
        for button in buttons {
            suggestions.append("Tap \(button.label ?? button.id) button")
        }

        // Add navigation expectations
        if !buttons.isEmpty {
            suggestions.append("Expect navigation or state change")
        }

        // Add validation tests
        if !textFields.isEmpty {
            suggestions.append("Test with invalid input")
            suggestions.append("Test with empty input")
        }

        return suggestions
    }

    // NEW: Build element descriptor with guidance
    private func buildElementDescriptor(_ snapshot: AwareViewSnapshot) -> ElementDescriptor {
        ElementDescriptor(
            id: snapshot.id,
            type: ElementType(rawValue: snapshot.type) ?? .container,
            label: snapshot.label ?? snapshot.id,
            value: snapshot.state["value"] as? String ?? "",
            state: inferElementState(snapshot),
            enabled: snapshot.enabled,
            visible: snapshot.visible,
            focused: snapshot.state["focused"] as? Bool,
            required: snapshot.state["required"] as? Bool,
            validation: snapshot.state["validation"] as? String,
            errorMessage: snapshot.state["error"] as? String,
            placeholder: snapshot.state["placeholder"] as? String,
            nextAction: generateNextAction(for: snapshot),
            exampleValue: generateExampleValue(for: snapshot),
            action: snapshot.state["action"] as? String,
            nextView: snapshot.state["nextView"] as? String,
            failureView: snapshot.state["failureView"] as? String,
            dependencies: snapshot.state["dependencies"] as? [String],
            accessibilityLabel: snapshot.accessibilityLabel,
            accessibilityHint: snapshot.accessibilityHint,
            frame: snapshot.frame
        )
    }

    // NEW: Generate next action suggestion
    private func generateNextAction(for snapshot: AwareViewSnapshot) -> String {
        switch snapshot.type {
        case "TextField":
            return "Enter \(snapshot.label ?? "text")"
        case "SecureField":
            return "Enter password"
        case "Button":
            return "Tap to \(snapshot.label ?? "perform action")"
        case "Toggle":
            return "Toggle \(snapshot.label ?? "switch")"
        case "Link":
            return "Navigate to \(snapshot.label ?? "linked content")"
        default:
            return "Interact with \(snapshot.label ?? snapshot.type)"
        }
    }

    // NEW: Generate example value
    private func generateExampleValue(for snapshot: AwareViewSnapshot) -> String? {
        let label = snapshot.label?.lowercased() ?? ""

        if label.contains("email") {
            return "test@example.com"
        } else if label.contains("phone") {
            return "+1234567890"
        } else if label.contains("name") {
            return "John Doe"
        } else if label.contains("username") {
            return "testuser"
        } else if label.contains("password") {
            return "••••••••"
        } else {
            return nil
        }
    }
}
```

---

### Step 3: Update MCP Tool

```typescript
// AetherMCP/src/features/unified/aware-actions.tools.ts

server.tool(
  'ui_snapshot',
  'Capture current UI state in LLM-optimized format',
  {
    app: z.string().optional().describe('App to snapshot (default: Breathe)'),
    format: z.enum(['compact', 'llm', 'text', 'json']).default('llm'),  // Default to LLM
  },
  async (args) => {
    // Call Aware via bridge
    const snapshot = await AwareBridge.call('snapshot', {
      app: args.app || 'Breathe',
      format: args.format
    })

    return {
      content: [{
        type: 'text',
        text: snapshot
      }]
    }
  }
)
```

---

### Step 4: Test with Claude

```typescript
// Example usage in Claude Code

// 1. Get snapshot
const snapshot = await mcp.call('ui_snapshot', { format: 'llm' })

// Claude sees:
// {
//   "view": {
//     "intent": "Authenticate user with email and password",
//     "elements": [
//       { "nextAction": "Enter email address", "exampleValue": "test@example.com" },
//       ...
//     ],
//     "testSuggestions": [
//       "Fill email with 'test@example.com'",
//       "Fill password with 'password123'",
//       ...
//     ]
//   }
// }

// Claude understands immediately what to do
```

---

## Next Steps

### Week 1: Implementation

**Day 1-2**: Implement Swift types
- [ ] Create `AwareLLMSnapshot.swift`
- [ ] Define all structs/enums
- [ ] Add Codable conformance

**Day 3-4**: Update AwareService
- [ ] Implement `generateLLMSnapshot()`
- [ ] Implement `inferIntent()`
- [ ] Implement `generateTestSuggestions()`

**Day 5**: Test
- [ ] Unit tests for LLM format
- [ ] Token count validation (target: ~200)
- [ ] Compare with compact format

---

### Week 2: Validation

**Day 1-2**: Real-world testing
- [ ] Test on 10 different views
- [ ] Measure token counts
- [ ] Validate suggestions are useful

**Day 3-4**: Claude integration
- [ ] Update MCP tool
- [ ] Test Claude can understand snapshots
- [ ] Validate Claude can follow suggestions

**Day 5**: Documentation
- [ ] Update README with LLM format
- [ ] Examples for common views
- [ ] Migration guide from compact

---

## Success Criteria

✅ **Token count**: 150-250 tokens per view (target: 200)
✅ **Self-describing**: Claude understands without docs
✅ **Actionable**: Test suggestions are useful
✅ **Accurate**: Intent inference 80%+ correct
✅ **Fast**: <50ms generation time

---

**Status**: Ready to implement

**Next**: Start Day 1 (Swift types)
