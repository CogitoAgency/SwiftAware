# Aware: LLM-First UI Testing

**Date:** 2026-01-14
**Vision:** UI testing designed for AI, not humans
**Target:** Claude Code writes/reads/debugs tests autonomously

> 🤖 **Core Insight**: Human developers don't write tests anymore. LLMs do. Design for the AI, not the human.

---

## The Paradigm Shift

### Old Paradigm: Human-First Testing

```swift
// Human writes test
func testLogin() {
    let app = XCUIApplication()
    app.launch()

    let emailField = app.textFields["Email"]
    XCTAssertTrue(emailField.exists)
    emailField.tap()
    emailField.typeText("test@example.com")

    let passwordField = app.secureTextFields["Password"]
    XCTAssertTrue(passwordField.exists)
    passwordField.tap()
    passwordField.typeText("password123")

    app.buttons["Login"].tap()

    XCTAssertTrue(app.staticTexts["Welcome"].waitForExistence(timeout: 5))
}
```

**Problems**:
- Human must know XCTest API
- Verbose (20 lines for simple flow)
- Brittle (element selectors break)
- Slow (mouse simulation)
- Expensive (developer time)

---

### New Paradigm: LLM-First Testing

```
User: "Test the login flow"

Claude Code:
1. Reads UI snapshot (110 tokens)
2. Understands: email field, password field, login button
3. Generates test plan in natural language
4. Executes actions via Aware
5. Verifies state changes
6. Reports results

Total: 500 tokens, 5 seconds
```

**Advantages**:
- LLM speaks natural language (no API to learn)
- Concise (5-step plan vs 20 lines of code)
- Adaptive (LLM adjusts if UI changes)
- Fast (ghost UI, no mouse)
- Cheap (500 tokens = $0.0015)

---

## Design Principles

### 1. Natural Language > Code

**Bad** (Human API):
```swift
XCTAssertTrue(app.buttons["Login"].exists)
```

**Good** (LLM API):
```
Snapshot contains: Button#login[enabled, label="Login"]
```

**Why**: LLMs understand plain English better than code syntax.

---

### 2. Self-Describing State

**Bad** (Opaque):
```json
{"id": "btn1", "t": "b", "s": 1}
```

**Good** (Self-describing):
```
Button#login[enabled, label="Login", position=(150, 400)]
```

**Why**: LLMs don't need docs if state is self-explanatory.

---

### 3. Semantic Intent > Low-Level Actions

**Bad** (Low-level):
```
1. Tap (150, 400)
2. Wait 0.5s
3. Type "test@example.com"
4. Tap (150, 450)
5. Type "password123"
6. Tap (150, 500)
```

**Good** (Semantic):
```
1. Fill login form:
   - Email: "test@example.com"
   - Password: "password123"
2. Tap "Login" button
```

**Why**: LLMs reason about intent, not coordinates.

---

### 4. Causality > Snapshots

**Bad** (Isolated snapshots):
```
Before: Button#login[enabled]
After: Button#login[disabled]
```

**Good** (Causality chain):
```
User tapped login button
  → Network request started (POST /auth/login)
  → Button disabled (loading state)
  → Response received (200 OK)
  → Navigation to Dashboard
```

**Why**: LLMs debug by understanding cause-and-effect.

---

### 5. Error Signals > Pass/Fail

**Bad** (Binary):
```
❌ Test failed
```

**Good** (Diagnostic):
```
❌ Test failed: Login flow

  Expected: Dashboard#main[loaded]
  Actual: LoginView#main[error="Invalid credentials"]

  Likely cause:
    - Network request failed (500 Internal Server Error)
    - API endpoint: POST /auth/login

  Suggestion:
    - Check server logs at 14:32:15
    - Verify credentials: test@example.com
```

**Why**: LLMs need context to diagnose, not just "failed".

---

## The LLM Testing Workflow

### Step 1: User Describes Goal

```
User: "Test the login flow end-to-end"
```

---

### Step 2: LLM Queries UI State

```typescript
// Claude Code calls MCP tool
const snapshot = await mcp.call("ui_snapshot", {
  app: "MyApp",
  format: "compact"
})

// Returns (110 tokens):
LoginView#main
  TextField#email[value="", label="Email", focused=false]
  SecureField#password[value="", label="Password", focused=false]
  Button#login[enabled, label="Login"]
  Link#forgot[label="Forgot password?"]
```

**LLM understands**:
- This is a login screen
- Has email + password fields
- Has a login button
- No errors displayed

---

### Step 3: LLM Generates Test Plan

```
Claude Code (internal reasoning):

Goal: Test login flow
Steps:
  1. Verify UI elements exist
  2. Enter valid credentials
  3. Tap login button
  4. Verify navigation to dashboard
  5. Verify user session is active

Expected outcome: Dashboard visible with user name
```

---

### Step 4: LLM Executes Test

```typescript
// Claude Code calls Aware MCP tools
await mcp.call("aware_type_text", {
  viewId: "email",
  text: "test@example.com"
})

await mcp.call("aware_type_text", {
  viewId: "password",
  text: "password123"
})

await mcp.call("aware_tap", {
  viewId: "login"
})

// Wait for navigation
await mcp.call("aware_wait", {
  condition: "view_appears",
  viewId: "dashboard",
  timeout: 5000
})
```

---

### Step 5: LLM Verifies Results

```typescript
// Check final state
const afterSnapshot = await mcp.call("ui_snapshot", {
  format: "compact"
})

// Returns (110 tokens):
DashboardView#main[loaded]
  NavigationBar[title="Welcome"]
  Text#greeting[value="Hello, test@example.com"]
  Button#logout[enabled, label="Logout"]
```

**LLM verifies**:
- ✅ Navigation happened (DashboardView not LoginView)
- ✅ User greeting shows correct email
- ✅ Logout button available (session active)

---

### Step 6: LLM Reports Results

```
✅ Login flow test passed

Steps executed:
  1. Filled email field with "test@example.com"
  2. Filled password field with "password123"
  3. Tapped login button
  4. Navigation to dashboard (1.2s)
  5. User session verified

Token usage: 450 tokens ($0.00135)
Time: 5.3 seconds
```

**Comparison to human writing this test**: 30 minutes, 50 lines of code

---

## LLM-Optimized Features

### Feature 1: Natural Language Queries

**Human API** (Must know XCTest):
```swift
let button = app.buttons.matching(identifier: "login").firstMatch
XCTAssertTrue(button.exists)
XCTAssertTrue(button.isEnabled)
```

**LLM API** (Natural language):
```typescript
const result = await mcp.call("aware_find", {
  query: "enabled button labeled 'Login'"
})

// Returns:
// Button#login[enabled, label="Login"]
```

**LLM can ask in English**:
- "Find the submit button"
- "Is the email field focused?"
- "What error is displayed?"

---

### Feature 2: Semantic Assertions

**Human API** (Code):
```swift
XCTAssertEqual(emailField.value as? String, "test@example.com")
```

**LLM API** (English):
```typescript
await mcp.call("aware_assert", {
  condition: "email field contains 'test@example.com'"
})
```

**LLM generates assertions like**:
- "Login button should be enabled"
- "Error message should not be visible"
- "Dashboard should appear within 5 seconds"

---

### Feature 3: Self-Healing Tests

**Problem**: UI changes, tests break.

**LLM Solution**: Adapt on the fly.

**Example**:
```
Test expects: Button#login
UI changed to: Button#sign-in

Traditional test: ❌ FAILS (element not found)

LLM test:
  1. Notices "login" button missing
  2. Queries: "Find button that submits login form"
  3. Finds: Button#sign-in[label="Sign In"]
  4. ✅ ADAPTS (uses new button)
  5. Suggests: "Update test to use 'sign-in' ID"
```

**Key**: LLM understands *intent* (submit login), not just *selector* (id="login").

---

### Feature 4: Visual Regression (Text-Based)

**Human approach**: Screenshot comparison (15,000 tokens)

**LLM approach**: Structural comparison (200 tokens)

```typescript
// Capture baseline
const baseline = await mcp.call("ui_snapshot", { format: "compact" })
// Store: LoginView with email, password, login button

// After code changes
const current = await mcp.call("ui_snapshot", { format: "compact" })

// LLM compares (200 tokens)
const diff = await mcp.call("aware_diff", { baseline, current })

// Returns:
// ADDED: Link#forgot[label="Forgot password?"]
// REMOVED: None
// CHANGED: Button#login[label: "Login" → "Sign In"]
```

**LLM reasoning**:
- New "Forgot password" link: ✅ Expected (new feature)
- Button label changed: ⚠️ Verify with user
- Structure intact: ✅ No breaking changes

---

### Feature 5: Contextual Debugging

**Human debugging**: Read stack trace, add print statements, re-run.

**LLM debugging**: Query causality graph.

**Example**:
```
❌ Test failed: Login button didn't respond

LLM queries:
1. "What happened when login button was tapped?"
   → Response: Network request started

2. "Did network request complete?"
   → Response: Timeout after 30s

3. "Why did request timeout?"
   → Response: Server returned 500 error

4. "What was the 500 error?"
   → Response: Database connection failed

LLM reports:
"Login failed due to server database error (500).
 Not a UI bug. Check backend logs at 14:32:15."
```

**Token cost**: 300 tokens ($0.0009) vs 30 minutes human debugging.

---

## Aware's LLM-First API Design

### Tool 1: `ui_snapshot` (LLM-Optimized)

**Purpose**: Get UI state in LLM-readable format.

```typescript
await mcp.call("ui_snapshot", {
  app: "MyApp",
  format: "llm",  // NEW: LLM-optimized format
  include: {
    structure: true,
    state: true,
    causality: true,
    suggestions: true
  }
})

// Returns (200 tokens):
{
  view: "LoginView",
  intent: "user_authentication",
  elements: [
    {
      id: "email",
      type: "TextField",
      label: "Email",
      state: "empty",
      validation: "required, email format",
      nextAction: "type email address"
    },
    {
      id: "password",
      type: "SecureField",
      label: "Password",
      state: "empty",
      validation: "required, min 8 chars",
      nextAction: "type password"
    },
    {
      id: "login",
      type: "Button",
      label: "Login",
      state: "enabled",
      action: "submit login form",
      nextView: "DashboardView (on success)"
    }
  ],
  suggestions: [
    "Fill email and password fields",
    "Tap login button",
    "Expect navigation to dashboard"
  ]
}
```

**Key LLM features**:
- `intent`: Why this view exists
- `validation`: What's required
- `nextAction`: What LLM should do
- `nextView`: What happens next
- `suggestions`: Test ideas

---

### Tool 2: `aware_test_plan` (NEW)

**Purpose**: LLM generates test plan from natural language goal.

```typescript
await mcp.call("aware_test_plan", {
  goal: "Test login flow end-to-end",
  app: "MyApp"
})

// Returns (300 tokens):
{
  goal: "Test login flow end-to-end",
  steps: [
    {
      step: 1,
      action: "verify_ui",
      description: "Verify login view elements exist",
      assertions: [
        "Email field is visible",
        "Password field is visible",
        "Login button is enabled"
      ]
    },
    {
      step: 2,
      action: "fill_form",
      description: "Enter valid credentials",
      actions: [
        { tool: "aware_type_text", viewId: "email", text: "test@example.com" },
        { tool: "aware_type_text", viewId: "password", text: "password123" }
      ]
    },
    {
      step: 3,
      action: "submit",
      description: "Tap login button",
      actions: [
        { tool: "aware_tap", viewId: "login" }
      ],
      expectedOutcome: "Navigation to dashboard"
    },
    {
      step: 4,
      action: "verify_result",
      description: "Verify user logged in",
      assertions: [
        "Dashboard view is visible",
        "User greeting shows email",
        "Logout button is available"
      ]
    }
  ],
  estimatedTokens: 450,
  estimatedTime: "5 seconds"
}
```

**LLM executes this plan autonomously.**

---

### Tool 3: `aware_execute_plan` (NEW)

**Purpose**: Execute test plan with real-time feedback.

```typescript
await mcp.call("aware_execute_plan", {
  plan: testPlan,  // From aware_test_plan
  streaming: true   // Real-time updates
})

// Streams (50 tokens per update):
{
  step: 1,
  status: "running",
  message: "Verifying UI elements..."
}

{
  step: 1,
  status: "success",
  message: "All elements present",
  duration: 0.5
}

{
  step: 2,
  status: "running",
  message: "Filling form fields..."
}

{
  step: 2,
  status: "success",
  message: "Credentials entered",
  duration: 1.2
}

{
  step: 3,
  status: "running",
  message: "Tapping login button..."
}

{
  step: 3,
  status: "success",
  message: "Navigation started",
  duration: 0.3
}

{
  step: 4,
  status: "running",
  message: "Verifying dashboard..."
}

{
  step: 4,
  status: "success",
  message: "Login successful",
  duration: 1.5
}

{
  status: "complete",
  totalSteps: 4,
  totalDuration: 3.5,
  totalTokens: 450,
  cost: "$0.00135"
}
```

**LLM sees real-time progress, can intervene if needed.**

---

### Tool 4: `aware_explain` (NEW)

**Purpose**: LLM asks "why?" about any UI state.

```typescript
await mcp.call("aware_explain", {
  question: "Why is the login button disabled?",
  context: currentSnapshot
})

// Returns (100 tokens):
{
  answer: "Login button is disabled because password field is empty",
  reasoning: [
    "Button has state: disabled",
    "Button has validation rule: requires email AND password",
    "Email field: filled ('test@example.com')",
    "Password field: empty",
    "Conclusion: Missing required field (password)"
  ],
  suggestion: "Fill password field to enable login button",
  relevantCode: "LoginView.swift:42 - Button disabled binding"
}
```

**LLM can ask**:
- "Why did this test fail?"
- "Why is this element not visible?"
- "Why did navigation not happen?"
- "Why is this field showing an error?"

---

### Tool 5: `aware_fix` (NEW)

**Purpose**: LLM proposes fix for failing test.

```typescript
await mcp.call("aware_fix", {
  failedTest: testResult,
  errorMessage: "Button#login not found"
})

// Returns (200 tokens):
{
  diagnosis: "Button ID changed from 'login' to 'sign-in'",
  evidencemm: [
    "Expected: Button#login",
    "Found: Button#sign-in[label='Sign In']",
    "Both buttons have same label text",
    "Same position: (150, 500)",
    "Likely: ID was renamed in code"
  ],
  proposedFix: {
    type: "update_test",
    changes: [
      {
        file: "LoginViewTests.swift",
        line: 15,
        old: "aware_tap({ viewId: 'login' })",
        new: "aware_tap({ viewId: 'sign-in' })"
      }
    ]
  },
  confidence: 0.95,
  autoApply: true  // LLM can auto-fix if confidence > 0.9
}
```

**LLM can**:
- Diagnose test failures
- Propose fixes
- Auto-apply fixes (if confident)
- Ask human for confirmation (if uncertain)

---

## Example: Full LLM Testing Session

### User Request

```
User: "Write a comprehensive test suite for the login flow"
```

---

### Claude Code Response

```
I'll create a comprehensive test suite for the login flow. Let me start by understanding the UI.

[Calls: ui_snapshot]
```

**Snapshot returned** (110 tokens):
```
LoginView#main
  TextField#email[value="", label="Email"]
  SecureField#password[value="", label="Password"]
  Button#login[enabled, label="Login"]
  Link#forgot[label="Forgot password?"]
```

```
I see the login view has email, password fields, a login button, and a forgot password link.

Let me create a test plan covering:
1. Happy path (valid credentials)
2. Invalid email format
3. Empty password
4. Network failure
5. Forgot password flow

[Calls: aware_test_plan with 5 scenarios]
```

**Test plan returned** (800 tokens):
```
Test Suite: Login Flow (5 scenarios)

Scenario 1: Valid credentials
  - Fill email: test@example.com
  - Fill password: password123
  - Tap login
  - Verify: Navigation to dashboard

Scenario 2: Invalid email format
  - Fill email: invalid-email
  - Tap login
  - Verify: Error "Invalid email format"

Scenario 3: Empty password
  - Fill email: test@example.com
  - Leave password empty
  - Verify: Login button disabled

Scenario 4: Network failure
  - Fill valid credentials
  - Simulate network error
  - Verify: Error "Connection failed"

Scenario 5: Forgot password
  - Tap "Forgot password?" link
  - Verify: Navigation to password reset
```

```
Executing test suite...

[Calls: aware_execute_plan with 5 scenarios]
```

**Execution results** (streaming):
```
Scenario 1: ✅ PASS (3.5s, 450 tokens)
Scenario 2: ✅ PASS (2.1s, 350 tokens)
Scenario 3: ✅ PASS (1.2s, 200 tokens)
Scenario 4: ❌ FAIL (5.0s, 400 tokens)
  Error: Expected error message "Connection failed"
  Actual: Generic error "Something went wrong"

Scenario 5: ✅ PASS (2.5s, 300 tokens)
```

```
Test suite complete: 4/5 passed

Found issue in Scenario 4:
  Network error shows generic message instead of specific error.

  Recommendation:
    Update error handling in LoginView.swift:67
    Show specific network error message instead of generic fallback.

[Calls: aware_fix to propose code change]
```

**Fix proposed**:
```swift
// LoginView.swift:67

// Before:
.alert("Error", isPresented: $showError) {
    Button("OK") { showError = false }
} message: {
    Text("Something went wrong")  // ❌ Generic
}

// After:
.alert("Error", isPresented: $showError) {
    Button("OK") { showError = false }
} message: {
    Text(errorMessage)  // ✅ Specific error
}
```

```
Total test execution:
  - Tests: 5 scenarios
  - Passed: 4/5 (80%)
  - Duration: 14.3 seconds
  - Tokens: 1,700 ($0.0051)
  - Found: 1 bug (generic error message)
  - Proposed: 1 fix (code change)

Would you like me to:
1. Apply the proposed fix automatically?
2. Generate regression tests for the fix?
3. Add more test scenarios?
```

---

### Total LLM Workflow

**Time**: 15 seconds (vs 2+ hours human writing tests)
**Cost**: 1,700 tokens = $0.0051 (vs $0+ human time)
**Tests**: 5 comprehensive scenarios
**Bugs found**: 1 (generic error message)
**Fix proposed**: Yes (with code change)

**Key**: LLM did everything autonomously. Human just said "test the login flow."

---

## Why This Beats Human Testing

### 1. Speed: 100x Faster

**Human**:
- Read requirements (15 min)
- Write test code (60 min)
- Debug failures (30 min)
- Total: ~2 hours

**LLM**:
- Understand UI (2s)
- Generate plan (3s)
- Execute tests (10s)
- Total: ~15 seconds

**Speedup**: 480x faster

---

### 2. Cost: 100x Cheaper

**Human**:
- Developer time: 2 hours × $100/hr = $200
- Per test suite: $200

**LLM**:
- Token cost: 1,700 tokens × $3/M = $0.0051
- Per test suite: $0.0051

**Savings**: 39,215x cheaper

---

### 3. Thoroughness: 10x Better

**Human**:
- Tests happy path only (70% of time)
- Forgets edge cases
- Misses error states
- No visual regression

**LLM**:
- Tests all scenarios (happy + edge + error)
- Generates edge cases automatically
- Validates error messages
- Detects visual regressions (structural)

**Coverage**: 10x more thorough

---

### 4. Maintenance: Self-Healing

**Human tests**:
- UI changes → Tests break
- Developer manually fixes (30 min)
- Brittle, high maintenance

**LLM tests**:
- UI changes → LLM adapts
- Finds equivalent elements
- Proposes test updates
- Self-healing, low maintenance

**Maintenance**: 100x less effort

---

## Success Metrics (LLM-First)

### Technical Metrics

| Metric | Target | Measure |
|--------|--------|---------|
| **Token efficiency** | 99.3% | Snapshot: 110 tokens vs 15,000 screenshot |
| **Test generation time** | <30s | Natural language → Full test suite |
| **Self-healing rate** | 80% | Tests adapt when UI changes |
| **Bug detection rate** | 3x human | LLM finds edge cases humans miss |
| **Maintenance cost** | <10% human | LLM fixes most broken tests |

### Product Metrics

| Metric | Target | Measure |
|--------|--------|---------|
| **Developers using** | 10,000 | Monthly active users |
| **Tests generated** | 1M+ | Total LLM-generated tests |
| **Bugs found** | 10,000+ | Bugs caught by LLM tests |
| **Time saved** | 20,000 hrs | Cumulative (vs human testing) |
| **Cost saved** | $2M+ | Cumulative (vs human testing) |

---

## The LLM Testing Future

### Phase 1: LLM as Test Writer (Today)

```
Human: "Test the login flow"
LLM: Writes tests, executes, reports results
```

---

### Phase 2: LLM as QA Engineer (6 months)

```
Human: Ships code
LLM: Automatically tests all affected flows, files bugs
```

---

### Phase 3: LLM as Development Partner (12 months)

```
Human: "Add forgot password feature"
LLM: Implements feature + writes tests + validates + deploys
```

**Aware enables Phase 1 today, Phase 2 in 6 months, Phase 3 in 12 months.**

---

## Implementation Plan

### Month 1: LLM-Optimized Snapshot Format

**Goal**: Make snapshots LLM-readable.

**Deliverables**:
- New format: `llm` (200 tokens, self-describing)
- Includes: intent, validation, suggestions, next actions
- Update: `ui_snapshot` tool

**Success**: Claude can understand any UI in one query

---

### Month 2: Test Plan Generation

**Goal**: LLM generates test plans from natural language.

**Deliverables**:
- New tool: `aware_test_plan`
- Input: Natural language goal
- Output: Structured test plan (steps, assertions, estimates)

**Success**: "Test login" → 5-scenario test plan in 3 seconds

---

### Month 3: Autonomous Execution

**Goal**: LLM executes test plans with real-time feedback.

**Deliverables**:
- New tool: `aware_execute_plan`
- Streaming progress updates
- Failure diagnostics
- Self-healing on UI changes

**Success**: LLM runs 5 tests in 15 seconds, adapts to changes

---

### Month 4: Contextual Debugging

**Goal**: LLM explains failures with causality.

**Deliverables**:
- New tool: `aware_explain`
- Answers "why?" questions
- Causality graph integration
- Code location references

**Success**: LLM diagnoses root cause in <5 seconds

---

### Month 5: Auto-Fix

**Goal**: LLM proposes and applies fixes to failing tests.

**Deliverables**:
- New tool: `aware_fix`
- Diagnose test failures
- Propose code changes
- Auto-apply if confident (>90%)

**Success**: 80% of broken tests fixed automatically

---

### Month 6: Continuous Testing

**Goal**: LLM tests on every code change.

**Deliverables**:
- GitHub Actions integration
- Pre-commit hooks
- PR comments with test results
- Auto-generated regression tests

**Success**: Every commit tested in <30 seconds

---

## Conclusion

**The shift**: Testing designed for AI, not humans.

**Why it matters**:
- 480x faster test generation
- 39,215x cheaper per test suite
- 10x better coverage
- 100x less maintenance
- Self-healing when UI changes

**The bet**: In 5 years, no human writes UI tests. LLMs do it all.

**Aware is the framework that makes this possible.**

---

**Next Steps**:

1. **Week 1**: Implement LLM-optimized snapshot format
2. **Week 2**: Build `aware_test_plan` tool
3. **Week 3**: Ship `aware_execute_plan` with streaming
4. **Week 4**: Demo full LLM testing workflow

**Goal**: Claude Code tests any iOS app autonomously by Month 6.

---

**Status**: LLM-First UI Testing Strategy

**Contact**: team@cogito.cv
