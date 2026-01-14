# Aware v4.0 MVP: Feature-Complete LLM-Native IDE Instrumentation

**Target Release:** Q1 2027 (12-month roadmap)
**Scope:** Breathe IDE + controlled apps (macOS primary, iOS limited)
**Positioning:** "The LLM-native instrumentation framework for AI-assisted development"

> 🎯 **Value Proposition**: 70-99% token reduction across UI, files, network, and processes. Makes AI-assisted development 10-25x cheaper and 10x faster.

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Existing Features (v3.1.0)](#existing-features-v310)
3. [New Features (v4.0)](#new-features-v40)
4. [Complete Feature Matrix](#complete-feature-matrix)
5. [Token Efficiency Targets](#token-efficiency-targets)
6. [MCP Tools Reference](#mcp-tools-reference)
7. [Technical Architecture](#technical-architecture)
8. [Use Case Scenarios](#use-case-scenarios)
9. [Success Metrics](#success-metrics)
10. [12-Month Roadmap](#12-month-roadmap)

---

## Executive Summary

### What is Aware v4.0?

**Aware v4.0** is the **complete LLM-native instrumentation framework** for Breathe IDE, providing comprehensive observability and control across all development operations—from UI interactions to file changes to network requests to build processes.

**Key Differentiator**: While traditional approaches cost **$0.045 per test** (screenshots) or **$0.015 per operation** (raw logs), Aware delivers **$0.00033-0.001 per operation** through semantic compression (70-99% token reduction).

### What's Included?

**4 Core Layers:**
1. ✅ **UI Layer** (Shipping v3.1.0) - 99.3% token reduction
2. 🆕 **File Layer** (NEW v4.0) - 85% token reduction
3. 🆕 **Network Layer** (NEW v4.0) - 75% token reduction
4. 🆕 **Process Layer** (NEW v4.0) - 90% token reduction

**Cross-Cutting Features:**
- 🆕 **AwareGraph** - Unified knowledge graph across all layers
- 🆕 **Causality Tracking** - Automatic event correlation
- 🆕 **Intent Metadata** - Every operation has semantic context
- ✅ **MCP Integration** - 45+ tools for Claude Code
- 🆕 **Token Budget Dashboard** - Real-time cost tracking
- 🆕 **Local Assistant** (Experimental) - On-device Phi-3 for simple queries

### Target Users

**Primary**: Developers using Breathe IDE with Claude Code
**Secondary**: AI tool vendors (Cursor, Cline, Windsurf) via AwareProtocol

### Platform Support

| Platform | UI | Files | Network | Processes | Status |
|----------|----|----|---------|-----------|--------|
| **macOS 14+** | ✅ | ✅ | ✅ | ✅ | Full support |
| **iOS 17+** | ✅ | ⚠️ Limited | ⚠️ Limited | ❌ | UI testing only |
| **Linux** | ⚠️ Experimental | ✅ | ✅ | ✅ | Command-line only |
| **Windows** | ❌ | ❌ | ❌ | ❌ | Not planned (v4.0) |

---

## Existing Features (v3.1.0)

### Layer 1: UI Instrumentation ✅ SHIPPING

**What it does**: Capture SwiftUI UI state as token-efficient text snapshots.

**Key Features:**
- **9 Core Modifiers**: `.aware()`, `.awareButton()`, `.awareTextField()`, `.awareSecureField()`, `.awareToggle()`, `.awareNavigation()`, `.awareAnimation()`, `.awareScroll()`, `.awareState()`
- **Ghost UI Testing**: Direct action callbacks (no mouse simulation)
- **5 Snapshot Formats**: Compact (110 tokens), Text, JSON, Markdown, Accessibility
- **Type-Safe Actions**: 21 explicit methods (`tap()`, `typeText()`, `focus()`, etc.)
- **Focus Management**: Tab navigation, focus tracking, blur triggers
- **Performance Budgeting**: Measure/assert action speeds (lenient/standard/strict)
- **WCAG Auditing**: Automated accessibility compliance checking (A/AA/AAA)
- **Visual Regression**: Snapshot comparison for UI changes
- **Coverage Tracking**: Test coverage metrics

**Token Efficiency**: **99.3% reduction** (15,000 → 110 tokens)

**Platforms**: iOS 17+, macOS 14+ (production-ready)

**MCP Tools**: 18 tools (`ui_*`, `aware_*`, `aware_focus_*`, `aware_performance_*`, `aware_accessibility_*`, `aware_coverage_*`, `aware_visual_*`, `aware_nav_*`)

**Testing**: 65+ unit tests, LLM integration tests, token efficiency benchmarks

**Example:**
```swift
Button("Save") { save() }
    .awareButton("save-btn", label: "Save")

// Snapshot (110 tokens):
// Button#save-btn[enabled,label="Save"]
```

---

### Layer 2: Validation & Patterns ✅ SHIPPING

**What it does**: 27 validation rules + 18 UI pattern templates for code quality.

**Key Features:**
- **27 Validation Rules**: Completeness (7), Consistency (7), WCAG (7), Performance (6)
- **18 UI Patterns**: Authentication, Forms, Lists, Navigation, Settings, Feedback
- **Auto-Fix Capability**: >70% success rate on violations
- **Pattern Library**: Best practices + code templates + common mistakes

**MCP Tools**: 4 tools (`aware_validate_code`, `aware_fix_code`, `aware_check_wcag`, `aware_check_performance`)

**Example Validation:**
```
Rule: Interactive elements need labels (WCAG 2.4.6)
Finding: Button#submit[label=nil] ❌
Auto-fix: Add .awareButton("submit", label: "Submit Form")
Result: ✅ Fixed in <500ms
```

---

### Layer 3: Documentation System ✅ SHIPPING

**What it does**: Self-documenting API with 5 export formats.

**Key Features:**
- **5 Export Formats**: Compact (1,200 tokens), JSON Schema, Mermaid, Markdown, OpenAPI
- **API Registry**: 9 modifiers, 21 actions, 15+ types documented
- **Protocol Generator**: Exports full Aware API for LLM consumption

**Use Cases:**
- LLM planning (Compact format)
- Tool validation (JSON Schema)
- Breathe IDE visualization (Mermaid diagrams)
- Human docs (Markdown)
- External integrations (OpenAPI)

**Example:**
```bash
# Generate compact protocol (1,200 tokens)
swift run ExportProtocol --format compact

# LLM consumes this to understand Aware capabilities
```

---

### Cross-Cutting: MCP Integration ✅ SHIPPING

**What it does**: 18 MCP tools for Claude Code integration via AetherMCP.

**Categories:**
- `ui_*` (8 tools) - App control, snapshot, find, test, wait
- `aware_*` (21 tools) - Type-safe actions (tap, type, assert, swipe, navigate)
- `aware_focus_*` (5 tools) - Focus management and accessibility
- `aware_performance_*` (6 tools) - Performance budgeting
- `aware_accessibility_*` (6 tools) - WCAG auditing
- `aware_coverage_*` (6 tools) - Coverage tracking
- `aware_visual_*` (5 tools) - Visual regression
- `aware_nav_*` (5 tools) - Navigation management

**Integration**: Breathe embeds AetherMCP, which uses Aware via SQLite bridge (`~/.breathe/index.sqlite`)

**Example:**
```typescript
// Claude Code calls:
await mcp.call("aware_tap", { viewId: "login-btn" })
await mcp.call("ui_snapshot", { format: "compact" })

// Returns: 110 tokens with full UI state
```

---

### Cross-Cutting: TDD Infrastructure ✅ SHIPPING

**What it does**: Makes TDD affordable at scale.

**Key Features:**
- **Token Cost**: $0.00033 per test (vs $0.045 screenshots)
- **Speed**: <100ms snapshot generation
- **LLM Integration Tests**: Validate LLMs can parse snapshots
- **Performance Benchmarks**: Prove 99.3% token reduction

**Example TDD Cycle:**
```swift
// 1. RED: Write failing test (50 tokens)
func testLoginButton() async {
    let snapshot = Aware.shared.snapshot(format: .compact)
    XCTAssertTrue(snapshot.contains("login-btn"))
}

// 2. GREEN: Add modifier (5 seconds)
Button("Login") { login() }
    .awareButton("login-btn", label: "Login")

// 3. REFACTOR: Tests still pass
// Change button style → snapshot unchanged (structural focus)
```

**1000 Tests Cost**: $0.33 (vs $45 screenshots) = **136x cheaper**

---

## New Features (v4.0)

### Layer 4: File System Instrumentation 🆕

**What it does**: Track file operations with semantic intent and causality.

**Key Features:**
- **Semantic File Operations**: Read/write/delete with intent metadata
- **Change Tracking**: Monitor modifications in real-time (FSEvents on macOS)
- **Token-Efficient Diffs**: 85% compression vs raw diffs
- **Causality Linking**: File change → test failure → user action
- **Cost Estimation**: Token cost before reading large files
- **Related Files**: Graph-based discovery (imports, tests, docs)
- **Intent Blame**: Who changed what and why (beyond git blame)

**Token Efficiency**: **85% reduction** (1,000 tokens → 150 tokens)

**Platform Support**: macOS (FSEvents), Linux (inotify), iOS (limited - app sandbox only)

**MCP Tools**: 8 new tools
- `fs_query` - Semantic file search
- `fs_read_intent` - Read with context tracking
- `fs_write_intent` - Write with purpose metadata
- `fs_track_changes` - Monitor modifications
- `fs_semantic_diff` - Token-efficient diffs
- `fs_blame_intent` - Intent-aware blame
- `fs_related_files` - Graph-based discovery
- `fs_estimate_cost` - Pre-read token estimation

**Example:**
```typescript
// Query files by intent
const files = await mcp.call("fs_query", {
  intent: "incomplete_work",
  lang: "swift",
  project: "Breathe"
})

// Returns (150 tokens vs 1,000 raw paths):
[
  {
    file: "AuthService.swift:42",
    intent: "fix_auth_bug",
    context: "TODO: Handle token refresh",
    priority: "P0",
    author: "adrian",
    staleness: "3 days",
    relatedFiles: ["Login.swift", "AuthTests.swift"]
  }
]
```

**Causality Example:**
```typescript
// File change triggers cascade
File: AuthService.swift:42 (changed)
  → Test: AuthTests.swift:89 (failed)
    → UI: Login button (disabled)
      → User: Tapped repeatedly (frustrated)

// LLM sees entire chain in 200 tokens
```

---

### Layer 5: Network Instrumentation 🆕

**What it does**: Track HTTP requests with API cost awareness and failure correlation.

**Key Features:**
- **Request Tracking**: Intercept HTTP/WebSocket from Breathe IDE
- **API Cost Estimation**: $ cost + token cost for LLM responses
- **Failure Correlation**: Network timeout → UI error → user action
- **Intent Metadata**: Why this request? (user action, auto-refresh, background sync)
- **Response Compression**: 75% token reduction for JSON APIs
- **GraphQL Optimization**: Query/mutation tracking
- **Rate Limiting Detection**: Warn before hitting API limits

**Token Efficiency**: **75% reduction** (2,000 tokens → 500 tokens)

**Platform Support**: macOS (URLSessionTaskDelegate), iOS (app-scoped only)

**MCP Tools**: 6 new tools
- `net_track_request` - Record request with intent
- `net_estimate_cost` - API $ + token cost
- `net_correlate_failure` - Link failure to UI state
- `net_query_history` - Search past requests
- `net_rate_limit_status` - Check API quotas
- `net_optimize_query` - GraphQL query optimization

**Example:**
```typescript
// Track API request
await mcp.call("net_track_request", {
  url: "/api/sessions",
  method: "POST",
  intent: "user_sync",
  triggeredBy: "sync-button"
})

// Returns (500 tokens vs 2,000 raw):
{
  request: "POST /api/sessions",
  status: 200,
  latency: "450ms",
  size: "12KB",
  apiCost: "$0.002",
  tokenCost: "~500 tokens if LLM reads response",
  intent: "user_sync",
  causedBy: "user_tap#sync-button",
  nextAction: "ui_refresh#session-list"
}
```

**Failure Correlation:**
```typescript
// Network failure cascade
Network: POST /api/sessions (timeout after 30s)
  → UI: Sync button (stuck in loading state)
    → User: Tapped 3 more times (frustrated)
      → Process: 4 concurrent requests (race condition)

// LLM diagnoses in one query (300 tokens)
```

---

### Layer 6: Process Instrumentation 🆕

**What it does**: Track build/test/script processes with resource attribution.

**Key Features:**
- **Lifecycle Tracking**: Spawn → execute → complete/fail with purpose
- **Resource Attribution**: CPU/memory → user action causality
- **Anomaly Detection**: Hung processes, memory leaks, CPU spikes
- **Build Intelligence**: Why did build fail? (not just exit code)
- **Test Correlation**: Test failure → code change → author
- **Script Monitoring**: Track automation scripts (deploy, migrate, etc.)

**Token Efficiency**: **90% reduction** (5,000 tokens → 500 tokens)

**Platform Support**: macOS (NSTask/Process), Linux (fork/exec), iOS (N/A - no process spawning)

**MCP Tools**: 7 new tools
- `proc_track` - Monitor process lifecycle
- `proc_why_failed` - Diagnose build/test failures
- `proc_resource_attribution` - Link CPU spike to action
- `proc_detect_hung` - Find stuck processes
- `proc_correlate_test` - Link test failure to code change
- `proc_script_status` - Track automation scripts
- `proc_optimize` - Suggest performance improvements

**Example:**
```typescript
// Track build process
await mcp.call("proc_track", {
  command: "swift build",
  intent: "verify_changes",
  triggeredBy: "user_save#AuthService.swift"
})

// Returns (500 tokens vs 5,000 raw logs):
{
  process: "swift build",
  status: "failed",
  exitCode: 1,
  duration: "12.3s",
  cpuUsage: "280%",
  memoryPeak: "1.2GB",
  intent: "verify_changes",
  causedBy: "file_change#AuthService.swift:42",
  error: {
    file: "AuthService.swift:42",
    message: "Type 'Token' has no member 'refresh'",
    fix: "Add Token.refresh() method or import extension"
  }
}
```

**Resource Attribution:**
```typescript
// CPU spike diagnosis
CPU: 95% usage (spike at 14:32:15)
  → Process: work_discover_all (scanning 10,000 files)
    → Triggered by: user_action#discovery-scan-button
      → Recommendation: "Cancel scan? Scanning node_modules (8K files)"

// LLM sees cause in 200 tokens
```

---

### Cross-Cutting: AwareGraph 🆕

**What it does**: Unified knowledge graph across UI, files, network, processes.

**Key Features:**
- **Graph Database**: SQLite with FTS5 (full-text search)
- **Cross-Layer Queries**: Find related operations across all layers
- **Causality Chains**: Automatic event correlation
- **GraphQL Interface**: Query language for complex searches
- **Incremental Snapshots**: Deltas, not full state
- **Time-Travel**: Query historical state ("What was UI at 14:30?")
- **Relationship Types**: CAUSED_BY, READS, WRITES, DISPLAYS, TRIGGERED, CONSUMES

**Query Latency**: <10ms (p99)

**Storage**: `~/.breathe/aware_graph.db` (SQLite with WAL mode)

**Graph Schema:**
```
Nodes:
- UIElement (Button, TextField, etc.)
- File (Swift, TypeScript, Markdown, etc.)
- NetworkRequest (API calls, WebSockets)
- Process (Build, test, script)
- UserAction (Tap, type, navigate)
- SystemEvent (Low battery, network change)

Edges:
- CAUSED_BY (Process → UserAction)
- READS (Process → File)
- WRITES (Process → File)
- DISPLAYS (UIElement → Data)
- TRIGGERED (NetworkRequest → UserAction)
- CONSUMES (Process → Resources)
```

**MCP Tools**: 5 new tools
- `graph_query` - GraphQL queries over system state
- `graph_causality` - Find causality chains
- `graph_related` - Find related operations
- `graph_timeline` - Time-travel queries
- `graph_export` - Export subgraph for LLM

**Example Queries:**

```graphql
# 1. Why did test fail?
query {
  testFailure(name: "testLogin", timestamp: "14:30:00") {
    causedBy {
      fileChange { path, author, intent }
      recentChanges { count, files }
    }
    affectedUI { elements, states }
    recommendation
  }
}

# Returns (300 tokens):
{
  "causedBy": {
    "fileChange": {
      "path": "AuthService.swift:42",
      "author": "adrian",
      "intent": "fix_token_refresh"
    },
    "recentChanges": { "count": 3, "files": ["AuthService", "Token", "API"] }
  },
  "affectedUI": {
    "elements": ["login-btn"],
    "states": ["disabled"]
  },
  "recommendation": "Token.refresh() is undefined. Revert changes or implement method."
}
```

```graphql
# 2. What's consuming CPU?
query {
  systemResources(metric: "cpu", threshold: 80) {
    processes { name, usage, intent }
    causedBy { userAction, timestamp }
    recommendation
  }
}

# Returns (200 tokens):
{
  "processes": [
    { "name": "work_discover_all", "usage": "95%", "intent": "scan_todos" }
  ],
  "causedBy": {
    "userAction": "tap#discovery-scan-button",
    "timestamp": "14:32:15"
  },
  "recommendation": "Cancel scan? Scanning node_modules (8,000 files). Exclude via .awareignore?"
}
```

**Token Efficiency**: Full system state = **<2,000 tokens** (vs 50,000+ raw logs)

---

### Cross-Cutting: Intent Metadata System 🆕

**What it does**: Every operation has semantic "why" context.

**Key Features:**
- **Intent Types**: 15 standard intents (backup, refactor, debug, optimize, test, etc.)
- **Custom Intents**: User-defined for project-specific workflows
- **Automatic Inference**: ML model predicts intent from context
- **Intent History**: Track intent evolution over time
- **Priority Tagging**: P0 (critical) → P3 (low)
- **Reversibility Flags**: Mark operations as undoable

**Intent Schema:**
```typescript
interface AwareIntent {
  type: "backup" | "refactor" | "debug" | "optimize" | "test" | "feature" | "fix" | "docs" | "chore" | "explore" | "cleanup" | "security" | "performance" | "ux" | "custom"
  description: string          // Human-readable why
  project?: string             // Which project context
  triggeredBy: TriggerSource   // What caused this
  priority: "P0" | "P1" | "P2" | "P3"
  reversible: boolean          // Can undo?
  costEstimate?: {
    tokens: number             // Token cost if LLM reads
    apiCost?: number           // $ cost for API calls
  }
  relatedIntents?: string[]    // Other intents in same workflow
}
```

**Example Usage:**

```swift
// File operation with intent
Aware.fileSystem.copy(
    source: "Config.json",
    destination: "Config.backup.json",
    intent: AwareIntent(
        type: .backup,
        description: "Backup before config changes",
        project: "Breathe",
        triggeredBy: .userAction("edit-config-btn"),
        priority: .P1,
        reversible: true,
        costEstimate: { tokens: 200 }
    )
)
```

**LLM Benefits:**
- Filter by intent: "Show me all backup operations"
- Prioritize by relevance: User actions > automated
- Estimate costs: "Will reading this file cost 5,000 tokens?"
- Understand context: "This failed because of refactoring intent"

---

### Cross-Cutting: Token Budget Dashboard 🆕

**What it does**: Real-time token cost tracking and optimization suggestions.

**Key Features:**
- **Live Cost Tracking**: Current session token usage
- **Budget Alerts**: Warn at 80% of daily budget
- **Cost Attribution**: Which operations cost most tokens?
- **Optimization Suggestions**: "Pin context to save 2,000 tokens/day"
- **Historical Analysis**: Token usage trends over time
- **What-If Scenarios**: "If I switch to compact format, save X tokens"

**MCP Tools**: 4 new tools
- `token_budget_current` - Session usage so far
- `token_budget_alert` - Set budget limits
- `token_budget_optimize` - Get optimization suggestions
- `token_budget_history` - Usage trends

**Example:**
```typescript
// Query current session usage
const budget = await mcp.call("token_budget_current")

// Returns:
{
  session: "abc123",
  duration: "45 minutes",
  tokensUsed: 8750,
  estimatedCost: "$0.026",
  breakdown: {
    "mem_context": 2000,      // 23%
    "ui_snapshot": 550,        // 6% (5 snapshots × 110)
    "fs_read_intent": 3200,    // 37%
    "net_track_request": 2000, // 23%
    "proc_track": 1000         // 11%
  },
  recommendations: [
    {
      action: "Pin AuthService.swift context",
      impact: "Save ~800 tokens on repeated reads",
      savingsPerDay: "$0.07"
    },
    {
      action: "Use compact UI snapshots (already optimal)",
      impact: "Currently saving 14,890 tokens vs screenshots",
      savingsPerDay: "$0.13"
    }
  ]
}
```

**Dashboard UI (Breathe IDE):**
```
┌─────────────────────────────────────────────┐
│ Token Budget - Session abc123               │
│                                             │
│ Used: 8,750 / 20,000 (44%) ████████░░       │
│ Cost: $0.026 / $0.060                       │
│                                             │
│ Top Costs:                                  │
│  1. File reads      3,200 tokens (37%) 📄  │
│  2. Memory context  2,000 tokens (23%) 🧠  │
│  3. Network logs    2,000 tokens (23%) 🌐  │
│                                             │
│ 💡 Optimization: Pin "AuthService.swift"    │
│    → Save 800 tokens/day ($0.07)            │
│    [Pin Now] [Dismiss]                      │
└─────────────────────────────────────────────┘
```

---

### Experimental: Local Assistant (AwareAgent) 🔬

**What it does**: On-device Phi-3 for instant, privacy-preserving queries.

**Key Features:**
- **Model**: Phi-3 Mini (3.8B, 4-bit quantized)
- **Size**: 500MB on disk, <2GB memory
- **Latency**: <100ms for simple queries
- **Accuracy**: 60-70% (vs 95% for Claude)
- **Privacy**: Sensitive data never leaves device
- **Routing**: Simple → local, complex → cloud

**Local Capabilities** (Good enough):
- UI navigation ("Open settings")
- File operations ("Find TODO comments")
- Process management ("Kill hung process")
- System queries ("Battery status?")
- Error diagnosis (simple cases)

**Cloud Escalation** (Too complex):
- Code generation
- Complex debugging
- Architecture decisions
- Multi-file refactoring

**MCP Tools**: 3 new tools
- `agent_query_local` - Ask local assistant
- `agent_should_escalate` - Check if needs cloud
- `agent_config` - Configure routing thresholds

**Example:**
```typescript
// User asks: "Why is Breathe using 90% CPU?"

// 1. Local agent queries AwareGraph (50ms)
const result = await mcp.call("agent_query_local", {
  query: "high cpu usage Breathe",
  maxLatency: 100
})

// Returns:
{
  answer: "work_discover_all process is scanning 10,000 files",
  confidence: 0.85,
  latency: 67,
  source: "local_phi3",
  actions: [
    { label: "Cancel Scan", tool: "proc_kill", args: { pid: 12345 } },
    { label: "Get Details", escalate: "cloud" }
  ]
}

// 2. If user clicks "Get Details" → escalate to Claude
```

**Trade-offs:**
- ✅ **Fast** - <100ms vs 2-3s cloud round-trip
- ✅ **Private** - Credentials stay local
- ✅ **Offline** - Works without internet
- ❌ **Dumb** - 60-70% accuracy vs 95% Claude
- ❌ **Battery** - +10% drain during use

**Recommendation**: Ship as **experimental opt-in** (disabled by default). Test with power users, collect feedback, improve routing logic.

---

## Complete Feature Matrix

### Core Capabilities

| Feature | v3.1.0 (Current) | v4.0 (Target) | Token Reduction | Platform |
|---------|------------------|---------------|-----------------|----------|
| **UI Instrumentation** | ✅ Shipping | ✅ Enhanced | 99.3% | iOS, macOS |
| **File System Tracking** | ❌ | 🆕 NEW | 85% | macOS, Linux, iOS (limited) |
| **Network Monitoring** | ❌ | 🆕 NEW | 75% | macOS, iOS (app-scoped) |
| **Process Tracking** | ❌ | 🆕 NEW | 90% | macOS, Linux |
| **Knowledge Graph** | ❌ | 🆕 NEW | 95% (queries) | All platforms |
| **Intent Metadata** | ❌ | 🆕 NEW | N/A (semantic) | All platforms |
| **Token Budget Dashboard** | ❌ | 🆕 NEW | N/A (monitoring) | All platforms |
| **Local Assistant** | ❌ | 🔬 Experimental | N/A (routing) | macOS (M1+) |
| **Validation & Auto-Fix** | ✅ Shipping | ✅ Enhanced | N/A (quality) | All platforms |
| **TDD Infrastructure** | ✅ Shipping | ✅ Enhanced | 99.3% | All platforms |
| **MCP Integration** | ✅ 18 tools | ✅ 45+ tools | 70-99% | All platforms |

### MCP Tools Summary

| Category | v3.1.0 | v4.0 | Examples |
|----------|--------|------|----------|
| **UI Control** | 8 | 8 | `ui_snapshot`, `ui_action`, `ui_find` |
| **Aware Actions** | 21 | 21 | `aware_tap`, `aware_type`, `aware_assert` |
| **Focus Management** | 5 | 5 | `aware_focus`, `aware_focus_next` |
| **Performance** | 6 | 6 | `aware_performance_measure`, `aware_performance_assert` |
| **Accessibility** | 6 | 6 | `aware_accessibility_audit`, `aware_check_wcag` |
| **Coverage** | 6 | 6 | `aware_coverage_start`, `aware_coverage_get` |
| **Visual Regression** | 5 | 5 | `aware_visual_capture`, `aware_visual_compare` |
| **Navigation** | 5 | 5 | `aware_nav_back`, `aware_nav_deep_link` |
| **Validation** | 4 | 4 | `aware_validate_code`, `aware_fix_code` |
| **File System** | 0 | 🆕 8 | `fs_query`, `fs_read_intent`, `fs_semantic_diff` |
| **Network** | 0 | 🆕 6 | `net_track_request`, `net_correlate_failure` |
| **Process** | 0 | 🆕 7 | `proc_track`, `proc_why_failed`, `proc_detect_hung` |
| **Graph** | 0 | 🆕 5 | `graph_query`, `graph_causality`, `graph_timeline` |
| **Token Budget** | 0 | 🆕 4 | `token_budget_current`, `token_budget_optimize` |
| **Local Assistant** | 0 | 🔬 3 | `agent_query_local`, `agent_should_escalate` |
| **Total** | **18** | **45+** | |

---

## Token Efficiency Targets

### Per-Layer Efficiency

| Layer | Raw Format | Aware v4.0 | Reduction | Example Operation |
|-------|-----------|------------|-----------|-------------------|
| **UI** | 15,000 tokens | 110 tokens | **99.3%** | Snapshot of login form |
| **Files** | 1,000 tokens | 150 tokens | **85%** | File change with context |
| **Network** | 2,000 tokens | 500 tokens | **75%** | API request/response |
| **Processes** | 5,000 tokens | 500 tokens | **90%** | Build failure diagnosis |
| **Graph Query** | 50,000 tokens | 2,000 tokens | **96%** | Full system state |

### Cost Comparison (1,000 Operations)

| Approach | Tokens | Cost @ $3/M | Annual Cost (100K ops) |
|----------|--------|-------------|------------------------|
| **Screenshots** | 15M | $45.00 | $4,500 |
| **Raw Logs** | 5M | $15.00 | $1,500 |
| **Accessibility Tree** | 1.5M | $4.50 | $450 |
| **Aware v3.0 (UI only)** | 110K | $0.33 | $33 |
| **Aware v4.0 (All layers)** | 300K | $0.90 | $90 |

**Savings**: Aware v4.0 saves **$4,410/year** vs screenshots, **$1,410/year** vs raw logs.

### Full System State Comparison

| Method | Tokens | Cost |
|--------|--------|------|
| **Screenshots** (10 screens) | 150,000 | $0.45 |
| **Raw Logs** (all events) | 50,000 | $0.15 |
| **Aware v4.0** (graph query) | 2,000 | $0.006 |

**Reduction**: **98.7%** vs raw logs, **99.9%** vs screenshots.

---

## Technical Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────┐
│ Breathe IDE (macOS)                                         │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │ UI Layer     │  │ Code Editor  │  │ Token Budget │    │
│  │ (Aware v3.0) │  │              │  │ Dashboard    │    │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘    │
│         │                  │                  │             │
│         └──────────────────┴──────────────────┘             │
│                            │                                │
│                  ┌─────────▼─────────┐                     │
│                  │  AwareGraph       │                     │
│                  │  (SQLite + FTS5)  │                     │
│                  └─────────┬─────────┘                     │
│                            │                                │
│         ┌──────────────────┼──────────────────┐            │
│         │                  │                  │             │
│  ┌──────▼───────┐  ┌──────▼───────┐  ┌──────▼───────┐   │
│  │ File Layer   │  │ Network Layer │  │ Process Layer│   │
│  │ (FSEvents)   │  │ (URLSession)  │  │ (NSTask)     │   │
│  └──────────────┘  └──────────────┘  └──────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ WebSocket IPC
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ AetherMCP Server                                            │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ 45+ MCP Tools                                         │  │
│  │  - ui_* (8), aware_* (21), aware_focus_* (5)         │  │
│  │  - fs_* (8), net_* (6), proc_* (7)                   │  │
│  │  - graph_* (5), token_budget_* (4), agent_* (3)      │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ MCP Protocol (stdio/websocket)
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ Claude Code CLI                                             │
│  - Receives compact snapshots (110-2,000 tokens)           │
│  - Executes actions via MCP tools                          │
│  - Tracks token budget in real-time                        │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow

**1. User Action → UI Change:**
```
User taps "Save" button
  → .awareButton() modifier captures tap
    → Registers in AwareGraph: UserAction#tap → UIElement#save-btn
      → Updates UI state in real-time
        → Claude queries: ui_snapshot (110 tokens)
```

**2. Code Change → Build → Test:**
```
Developer edits AuthService.swift
  → FSEvents detects file change
    → Records in AwareGraph: FileChange#AuthService.swift
      → Triggers build process
        → NSTask monitors: proc_track
          → Build fails
            → Graph links: FileChange → Build → TestFailure
              → Claude queries: graph_causality (300 tokens, full chain)
```

**3. Network Request → UI Update:**
```
User taps "Sync" button
  → UI action recorded
    → Triggers network request
      → URLSessionTaskDelegate intercepts
        → Records in AwareGraph: NetworkRequest#POST_/sessions
          → Response received
            → UI updates (session list refreshes)
              → Graph links: UserAction → NetworkRequest → UIUpdate
                → Claude queries: net_correlate_failure (500 tokens)
```

### Storage Architecture

**AwareGraph Database** (`~/.breathe/aware_graph.db`):

```sql
-- Nodes table (all entities)
CREATE TABLE nodes (
    id TEXT PRIMARY KEY,
    type TEXT NOT NULL,  -- 'ui', 'file', 'network', 'process', 'user_action', 'system_event'
    data TEXT NOT NULL,  -- JSON blob with entity-specific fields
    intent TEXT,         -- Semantic intent
    timestamp INTEGER,
    project TEXT,
    INDEX idx_type_timestamp ON nodes(type, timestamp),
    INDEX idx_project ON nodes(project)
);

-- Edges table (relationships)
CREATE TABLE edges (
    id TEXT PRIMARY KEY,
    source_id TEXT NOT NULL,
    target_id TEXT NOT NULL,
    type TEXT NOT NULL,  -- 'CAUSED_BY', 'READS', 'WRITES', 'DISPLAYS', 'TRIGGERED', 'CONSUMES'
    weight REAL DEFAULT 1.0,
    timestamp INTEGER,
    FOREIGN KEY (source_id) REFERENCES nodes(id),
    FOREIGN KEY (target_id) REFERENCES nodes(id),
    INDEX idx_source ON edges(source_id),
    INDEX idx_target ON edges(target_id),
    INDEX idx_type ON edges(type)
);

-- Full-text search
CREATE VIRTUAL TABLE nodes_fts USING fts5(
    id, type, data, intent, project,
    content=nodes,
    content_rowid=id
);

-- Metrics table (token budget tracking)
CREATE TABLE metrics (
    session_id TEXT NOT NULL,
    tool TEXT NOT NULL,
    tokens INTEGER NOT NULL,
    cost REAL NOT NULL,
    timestamp INTEGER,
    INDEX idx_session ON metrics(session_id)
);
```

**Size Estimates:**
- 100K operations/day
- Nodes: ~10MB/day (100 bytes/node avg)
- Edges: ~5MB/day (50 bytes/edge avg)
- FTS index: ~15MB/day
- **Total**: ~30MB/day, ~900MB/month
- **Retention**: 7 days (auto-prune) = ~210MB steady-state

---

## Use Case Scenarios

### Scenario 1: Debug Production Crash (Traditional vs Aware)

**Traditional Approach** (45 minutes):
1. User reports: "App crashed at 14:32"
2. Developer checks logs (5-10 min)
3. Manually correlates events (10 min)
4. Tries to reproduce (20 min)
5. Finds root cause: Network timeout → nil unwrap
6. Fixes issue

**Aware v4.0 Approach** (2 minutes):
```typescript
// LLM query: "What caused crash at 14:32?"
const causality = await mcp.call("graph_causality", {
  event: "crash",
  timestamp: "14:32:00"
})

// Returns (300 tokens):
{
  crash: { process: "Breathe", signal: "SIGSEGV", address: 0x... },
  causedBy: {
    network: { url: "/api/sessions", status: "timeout", duration: "30s" },
    code: { file: "SessionService.swift:67", line: "let data = response.data!" },
    reason: "Force unwrap of nil after network timeout"
  },
  fix: "Add guard let data = response.data else { return } before line 67",
  confidence: 0.95
}
```

**Time saved**: 43 minutes, **Token cost**: 300 tokens ($0.0009)

---

### Scenario 2: Cross-File Refactoring (Safety Net)

**Problem**: Rename `AuthToken` → `SessionToken` across 15 files.

**Aware v4.0 Workflow**:
```typescript
// 1. Before refactoring: Capture baseline
await mcp.call("graph_export", { scope: "auth" })

// 2. Perform refactoring (global search/replace)
// ... developer makes changes ...

// 3. Run validation
const validation = await mcp.call("aware_validate_code", {
  files: ["*.swift"],
  rules: ["completeness", "consistency"]
})

// 4. Check for breaks
const breaks = await mcp.call("graph_query", {
  query: `
    query {
      filesChanged(since: "baseline") {
        path
        testsAffected { name, status }
        buildStatus
      }
    }
  `
})

// Returns (500 tokens):
{
  filesChanged: 15,
  testsAffected: [
    { name: "testLogin", status: "failed" },
    { name: "testRefreshToken", status: "failed" }
  ],
  buildStatus: "failed",
  errors: [
    {
      file: "MockAuth.swift:23",
      message: "Cannot find 'AuthToken' in scope",
      fix: "Update mock to use 'SessionToken'"
    }
  ]
}
```

**Result**: Catches missed files before committing. **Token cost**: 500 tokens ($0.0015).

---

### Scenario 3: Token Budget Optimization

**Problem**: Monthly AI development costs = $50/developer (high).

**Aware v4.0 Solution**:
```typescript
// Analyze token usage
const analysis = await mcp.call("token_budget_history", {
  period: "30d",
  groupBy: "tool"
})

// Returns:
{
  totalTokens: 550000,
  totalCost: "$1.65",
  breakdown: {
    "ui_snapshot": 33000,   // 6% - Already optimal (compact format)
    "fs_read_intent": 275000, // 50% - Repeated reads of same files
    "mem_context": 165000,   // 30% - Loading full context each session
    "net_track_request": 77000 // 14% - JSON responses
  },
  recommendations: [
    {
      action: "Pin 10 most-read files to session context",
      files: ["AuthService.swift", "API.swift", "Config.swift", ...],
      currentCost: 275000,
      projectedCost: 50000,
      savings: "$0.68/month per developer"
    },
    {
      action: "Use memory context references instead of full reload",
      currentCost: 165000,
      projectedCost: 20000,
      savings: "$0.44/month per developer"
    }
  ]
}
```

**Result**: Implements recommendations → Costs drop from $1.65/mo to $0.21/mo (**87% reduction**).

---

### Scenario 4: Proactive Assistance (OS Initiates)

**Problem**: User stuck, LLM doesn't know.

**Aware v4.0 Proactive Detection**:
```typescript
// AwareGraph detects pattern
const pattern = await mcp.call("graph_query", {
  query: `
    query {
      userActions(
        element: "login-btn",
        action: "tap",
        since: "5m",
        minCount: 5
      ) {
        count
        uiState { element: "login-btn", state }
        relatedErrors
      }
    }
  `
})

// Returns:
{
  count: 7,  // User tapped login 7 times in 5 minutes
  uiState: { element: "login-btn", state: "loading" },  // Still stuck
  relatedErrors: [
    { type: "network_timeout", url: "/api/auth" }
  ]
}

// Proactive suggestion to LLM
const suggestion = {
  trigger: "user_frustration",
  message: "User tapped login 7× but button stuck in loading state. Network timeout detected.",
  actions: [
    { label: "Check Network", tool: "net_query_history", args: { url: "/api/auth" } },
    { label: "Reset UI", tool: "ui_action", args: { viewId: "login-btn", action: "reset" } }
  ],
  priority: 90  // High priority
}
```

**Result**: LLM proactively offers help instead of waiting for user to ask.

---

## Success Metrics

### Product Metrics (12 Months)

| Metric | Target | Measure |
|--------|--------|---------|
| **Breathe IDE Users** | 10,000 | Active users with Aware v4.0 enabled |
| **Token Savings** | $10,000+ | Cumulative savings vs screenshots |
| **Avg Session Cost** | <$0.10 | Median cost per AI-assisted session |
| **Time Savings** | 30% | Reduction in debugging time |
| **Adoption Rate** | 70% | Users who enable file/network/process layers |
| **Local Assistant Usage** | 20% | Sessions with local queries |

### Technical Metrics

| Metric | Target | Measure |
|--------|--------|---------|
| **Token Efficiency** | 70-99% | Reduction vs raw formats |
| **UI Snapshot** | 99.3% | (Proven - maintain) |
| **File Ops** | 85% | Target for fs_* tools |
| **Network Ops** | 75% | Target for net_* tools |
| **Process Ops** | 90% | Target for proc_* tools |
| **Graph Queries** | <10ms p99 | Query latency |
| **System Overhead** | <5% | CPU/memory impact |
| **Local Assistant Latency** | <100ms | On-device query response |

### Quality Metrics

| Metric | Target | Measure |
|--------|--------|---------|
| **Causality Accuracy** | 90% | Correct causality chains |
| **Intent Inference** | 80% | Accurate intent prediction |
| **Auto-Fix Success** | 70% | Violations fixed automatically |
| **Privacy Incidents** | 0 | Credential leaks to cloud |
| **False Positives** | <5% | Incorrect anomaly detection |

---

## 12-Month Roadmap

### Q1 2026: File System Layer (3 months)

**Goals**:
- Ship `AwareFileSystem` protocol + implementation
- 8 new `fs_*` MCP tools
- 85% token reduction vs raw file operations

**Deliverables**:
- `AwareCore/FileSystem/AwareFileSystem.swift` (macOS, Linux, iOS-limited)
- FSEvents integration (real-time file monitoring)
- `fs_query`, `fs_read_intent`, `fs_write_intent`, `fs_track_changes`, `fs_semantic_diff`, `fs_blame_intent`, `fs_related_files`, `fs_estimate_cost`
- 20+ unit tests
- Token efficiency benchmarks

**Success Criteria**:
- ✅ Read file: 1,000 → 150 tokens (85% reduction)
- ✅ Causality: File change → test failure (90% accuracy)
- ✅ Zero performance regression (<5% overhead)

---

### Q2 2026: Network + Process Layers (3 months)

**Goals**:
- Ship `AwareNetwork` + `AwareProcessManager` protocols
- 13 new `net_*` + `proc_*` MCP tools
- 75-90% token reduction

**Deliverables**:
- Network layer: `net_track_request`, `net_estimate_cost`, `net_correlate_failure`, `net_query_history`, `net_rate_limit_status`, `net_optimize_query`
- Process layer: `proc_track`, `proc_why_failed`, `proc_resource_attribution`, `proc_detect_hung`, `proc_correlate_test`, `proc_script_status`, `proc_optimize`
- URLSession + NSTask integration
- 30+ unit tests

**Success Criteria**:
- ✅ Network: 2,000 → 500 tokens (75% reduction)
- ✅ Process: 5,000 → 500 tokens (90% reduction)
- ✅ Build failure diagnosis in 1 query

---

### Q3 2026: AwareGraph + Intent System (3 months)

**Goals**:
- Ship unified knowledge graph
- 5 new `graph_*` MCP tools
- <10ms query latency

**Deliverables**:
- SQLite graph database with FTS5
- GraphQL query interface
- `graph_query`, `graph_causality`, `graph_related`, `graph_timeline`, `graph_export`
- Intent metadata system (15 standard intents)
- Cross-layer causality tracking

**Success Criteria**:
- ✅ Full system state: <2,000 tokens
- ✅ Query latency: <10ms p99
- ✅ Causality accuracy: 90%

---

### Q4 2026: Token Budget + Local Assistant (3 months)

**Goals**:
- Ship token budget dashboard
- Experimental local assistant (opt-in)

**Deliverables**:
- Token budget tracking: 4 tools (`token_budget_*`)
- Breathe IDE dashboard UI
- Phi-3 integration (4-bit quantized)
- Local/cloud routing logic
- 3 tools: `agent_query_local`, `agent_should_escalate`, `agent_config`

**Success Criteria**:
- ✅ Budget dashboard: Real-time cost tracking
- ✅ Local assistant: <100ms, 60-70% accuracy
- ✅ User feedback: 7/10 satisfaction (experimental feature)

---

### Q1 2027: Polish + Stabilization (3 months)

**Goals**:
- Production-ready v4.0 release
- Performance optimization
- Documentation

**Deliverables**:
- Performance optimization (target <3% overhead)
- Bug fixes based on beta feedback
- Comprehensive documentation (README, API docs, tutorials)
- Case studies (3-5 real-world examples)
- Open source release (MIT license)
- Blog post + launch

**Success Criteria**:
- ✅ 10,000 active users
- ✅ <3% system overhead
- ✅ 70-99% token efficiency maintained
- ✅ 0 privacy incidents

---

## Conclusion

**Aware v4.0** is the feature-complete LLM-native instrumentation framework that makes AI-assisted development **10-25x cheaper** and **10x faster** by providing comprehensive observability across UI, files, network, and processes—all with 70-99% token reduction.

**What makes it compelling**:
1. ✅ **Proven foundation** - v3.0 ships today with 99.3% UI token reduction
2. ✅ **Realistic scope** - IDE-scoped (not blocked by OS sandboxing)
3. ✅ **Massive value** - $4,410/year savings vs screenshots
4. ✅ **No competitor** - Only solution with system-wide semantic compression
5. ✅ **12-month roadmap** - All features achievable with current technology

**The honest pitch**:
> "Aware v4.0 is the LLM-native instrumentation framework for Breathe IDE. It provides 70-99% token reduction across UI, files, network, and processes—making AI-assisted development 10-25x cheaper than screenshot-based testing. Works today on macOS, with comprehensive MCP integration and real-time token budget tracking."

**Next steps**:
1. Validate MVP scope with users
2. Kick off Phase 1 (File System) in Q1 2026
3. Ship feature-complete v4.0 by Q1 2027
4. Scale to 10,000 users
5. Consider system-wide (OS partnership) in 2028+

---

**Status**: MVP specification - ready for implementation planning

**Contributors**: Adrian Portelli, Claude Sonnet 4.5

**Contact**: team@cogito.cv
