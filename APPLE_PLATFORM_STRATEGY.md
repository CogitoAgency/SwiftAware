# Aware v4.0: Apple Platform Strategy

**Target Release:** Q1 2027 (12 months)
**Platforms:** macOS 14+ (full support), iOS 17+ (optimized for constraints)
**Positioning:** "The LLM-native instrumentation framework for Apple platforms"

> 🎯 **Strategy**: Go deep on Apple platforms instead of spreading thin. Leverage Apple-specific APIs, embrace iOS constraints as features, and make cross-device workflows magical.

---

## Table of Contents

1. [Platform Capabilities Matrix](#platform-capabilities-matrix)
2. [macOS: Full Power Strategy](#macos-full-power-strategy)
3. [iOS: Constraint-Optimized Strategy](#ios-constraint-optimized-strategy)
4. [Cross-Device Workflows](#cross-device-workflows)
5. [Apple-Specific Advantages](#apple-specific-advantages)
6. [Technical Implementation](#technical-implementation)
7. [12-Month Roadmap](#12-month-roadmap)

---

## Platform Capabilities Matrix

### What's Possible on Each Platform

| Feature | macOS 14+ | iOS 17+ | Rationale |
|---------|-----------|---------|-----------|
| **UI Instrumentation** | ✅ Full | ✅ Full | SwiftUI works identically |
| **File System Tracking** | ✅ Full | ⚠️ App Sandbox | iOS limited to app container |
| **Network Monitoring** | ✅ Full | ⚠️ App Only | iOS can track own app's requests |
| **Process Tracking** | ✅ Full | ❌ Not Allowed | iOS sandboxing blocks process APIs |
| **Knowledge Graph** | ✅ Full | ✅ Full | SQLite works everywhere |
| **Intent Metadata** | ✅ Full | ✅ Full | Pure Swift, no restrictions |
| **Token Budget** | ✅ Full | ✅ Full | Client-side tracking |
| **Local Assistant** | ✅ Full | ⚠️ Battery | Phi-3 works but drains battery |
| **Background Monitoring** | ✅ Full | ❌ Suspended | iOS apps suspended in background |
| **System-Wide Access** | ⚠️ Limited | ❌ Never | macOS requires entitlements, iOS impossible |

### Strategy: Embrace the Constraints

**Don't fight iOS sandboxing** - Design iOS experience around what it's *great* at:
1. ✅ **Spec-driven development** - Define requirements on iPhone, implement on Mac
2. ✅ **UI testing** - Test mobile apps with 99.3% token efficiency
3. ✅ **Code review** - Read code/PRs on mobile, sync context to Mac
4. ✅ **Context capture** - Record "what I was thinking" notes, sync to IDE

**macOS is the workhorse** - Full IDE instrumentation:
1. ✅ All 4 layers (UI, Files, Network, Processes)
2. ✅ System-wide monitoring (with user permission)
3. ✅ Local assistant (M1+ Neural Engine)
4. ✅ Heavy compute (builds, tests, AI inference)

---

## macOS: Full Power Strategy

### Target: Breathe IDE + Developer Workflows

**Core Use Case**: Professional development on Mac with comprehensive instrumentation.

### Layer 1: UI Instrumentation ✅

**Status**: Production-ready (v3.1.0)

**Capabilities**:
- SwiftUI app testing (Breathe IDE itself)
- macOS-specific UI (NSMenu, NSToolbar, NSSplitView)
- AppKit interop (wrap legacy views)
- Multiple windows (Breathe can have many editor windows)

**Mac-Specific Features**:
- `.awareMacMenu()` - Menu item tracking
- `.awareMacToolbar()` - Toolbar button instrumentation
- `.awareMacWindow()` - Window lifecycle tracking
- `.awareMacKeyboard()` - Keyboard shortcut monitoring

**Example**:
```swift
// macOS-specific modifier
Menu("File") {
    Button("New File") { createFile() }
        .awareMacMenu("file-new", label: "New File", shortcut: "⌘N")

    Button("Save") { save() }
        .awareMacMenu("file-save", label: "Save", shortcut: "⌘S")
}
```

**Token Efficiency**: 110 tokens for full menu hierarchy

---

### Layer 2: File System Instrumentation 🆕

**Status**: NEW v4.0

**Capabilities**:
- **Full workspace access** - Monitor entire project directory
- **FSEvents API** - Real-time file change notifications
- **Spotlight integration** - Semantic file search
- **Extended attributes** - Store intent metadata in file xattrs
- **Time Machine awareness** - Track backups

**Mac-Specific Advantages**:
```swift
// FSEvents monitors entire /Users/adrian/Projects/Breathe
let monitor = AwareFileSystem.monitor(
    path: "/Users/adrian/Projects/Breathe",
    latency: 0.1,  // 100ms batching
    flags: [.watchRoot, .fileEvents, .markSelf]
)

monitor.observe { event in
    // Real-time notification for ANY file change
    await AwareGraph.record(
        node: .fileChange(
            path: event.path,
            type: event.type,  // created, modified, deleted, renamed
            intent: inferIntent(from: event),  // ML inference
            triggeredBy: currentUserAction()
        )
    )
}
```

**Token Efficiency**:
- Single file change: 150 tokens (vs 1,000 raw)
- Full workspace scan: 2,000 tokens (vs 50,000 raw)

**Performance**:
- FSEvents: <1% CPU overhead
- Incremental updates only (no polling)

---

### Layer 3: Network Monitoring 🆕

**Status**: NEW v4.0

**Capabilities**:
- **URLSession interception** - All HTTP/WebSocket from Breathe
- **Network.framework** - Low-level monitoring (with entitlement)
- **DNS queries** - Track all domain lookups
- **TLS inspection** - Certificate validation tracking
- **Bandwidth tracking** - Upload/download per endpoint

**Mac-Specific Advantages**:
```swift
// Option 1: App-scoped (no entitlement needed)
class AwareURLProtocol: URLProtocol {
    override func startLoading() {
        // Intercept all URLSession requests from Breathe
        AwareGraph.record(
            node: .networkRequest(
                url: request.url,
                method: request.httpMethod,
                headers: request.allHTTPHeaderFields,
                intent: inferIntent(from: request),
                triggeredBy: backtrace()  // Find calling code
            )
        )
    }
}

// Option 2: System-wide (requires entitlement + user approval)
import NetworkExtension

let monitor = NWPathMonitor()
monitor.pathUpdateHandler = { path in
    // Track all network interfaces
    AwareGraph.record(
        node: .networkChange(
            isExpensive: path.isExpensive,
            isConstrained: path.isConstrained,
            interfaces: path.availableInterfaces
        )
    )
}
```

**Token Efficiency**:
- Single API request: 500 tokens (vs 2,000 raw)
- Full network session: 1,500 tokens (vs 10,000 raw)

**Privacy**:
- App-scoped by default (Breathe's own requests only)
- System-wide opt-in (requires Network Extension entitlement)

---

### Layer 4: Process Tracking 🆕

**Status**: NEW v4.0

**Capabilities**:
- **NSTask/Process** - Track child processes (builds, tests, scripts)
- **libproc** - Query process info (CPU, memory, threads)
- **Endpoint Security** - System-wide process monitoring (with entitlement)
- **Instruments integration** - Deep profiling data
- **Crash reports** - Parse CrashReporter logs

**Mac-Specific Advantages**:
```swift
// Option 1: Child processes (no entitlement)
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
task.arguments = ["build"]

// Wrap with Aware instrumentation
let trackedTask = AwareProcess.track(
    task: task,
    intent: .build,
    project: "Breathe",
    triggeredBy: .userAction("build-button")
)

try await trackedTask.run()

// Returns:
// {
//   status: "success",
//   exitCode: 0,
//   duration: "12.3s",
//   cpuUsage: "280%",
//   memoryPeak: "1.2GB",
//   filesRead: 347,
//   filesWritten: 89,
//   networkRequests: 0
// }

// Option 2: System-wide (requires Endpoint Security entitlement)
import EndpointSecurity

let client = try ESClient(handler: { event in
    switch event.type {
    case .exec:
        // Any process spawned on system
        AwareGraph.record(
            node: .processSpawn(
                path: event.process.executable.path,
                arguments: event.process.arguments,
                parent: event.process.parent
            )
        )
    case .exit:
        // Process terminated
        AwareGraph.record(
            node: .processExit(
                pid: event.process.pid,
                exitCode: event.exitStatus
            )
        )
    }
})
```

**Token Efficiency**:
- Single build: 500 tokens (vs 5,000 raw logs)
- Test suite: 800 tokens (vs 20,000 raw)

**Entitlements Required** (for system-wide):
- `com.apple.developer.endpoint-security.client`
- User must approve in System Preferences

---

### macOS-Specific: Kernel Extension Alternative

**Problem**: System-wide access requires entitlements that Apple rarely grants.

**Solution**: Use existing macOS tools + parse their output.

```swift
// Leverage macOS built-in monitoring
class AwareSystemMonitor {
    // Use 'fs_usage' (Apple's own tool, no entitlement)
    func monitorFileSystem() async {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/fs_usage")
        task.arguments = ["-w", "-f", "filesys"]

        // Parse output in real-time
        task.standardOutput = Pipe()
        // ... stream parsing ...
    }

    // Use 'nettop' for network
    func monitorNetwork() async {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/nettop")
        task.arguments = ["-P", "-L", "1"]
        // ... parse output ...
    }

    // Use 'sample' for CPU profiling
    func profileProcess(pid: Int) async {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/sample")
        task.arguments = ["\(pid)", "1", "-f", "/tmp/sample.txt"]
        // ... parse output ...
    }
}
```

**Trade-offs**:
- ✅ No entitlements needed (uses Apple's own tools)
- ✅ Works immediately (no approval required)
- ⚠️ Slower (parsing text output, not native APIs)
- ⚠️ Less detailed (limited to what tools expose)

**Decision**: Ship both approaches
- Default: Parse built-in tools (works for everyone)
- Opt-in: Native APIs (for users who get entitlements)

---

### macOS Local Assistant (Neural Engine)

**Status**: NEW v4.0 (experimental)

**Capabilities**:
- **Apple Silicon Neural Engine** - 15 TOPS on M1, 38 TOPS on M4
- **Core ML integration** - Optimized inference
- **On-device fine-tuning** - Adapt to user's codebase
- **Low power mode** - Throttle when on battery

**Implementation**:
```swift
import CoreML

class AwareLocalAssistant {
    private let model: MLModel  // Phi-3 converted to CoreML

    func query(_ text: String) async -> AwareResponse {
        // Prepare input
        let input = prepareInput(text, context: AwareGraph.recentContext())

        // Run inference on Neural Engine
        let prediction = try await model.prediction(from: input)

        // Parse output
        return parseResponse(prediction)
    }
}
```

**Performance**:
- **M1/M2**: ~80ms per query (Phi-3 Mini 3.8B)
- **M3/M4**: ~50ms per query (Neural Engine boost)
- **Memory**: 2GB resident

**Battery Impact**:
- Active use: +10% drain
- Idle: +2% drain (model loaded in memory)
- Solution: Unload after 5 minutes idle

---

## iOS: Constraint-Optimized Strategy

### Target: Mobile-First Workflows

**Core Use Case**: Capture context on mobile, execute on Mac.

### What iOS Does BETTER Than macOS

**1. Always With You**
- Capture ideas/bugs the moment they happen
- Voice memos with automatic transcription
- Photos of whiteboards → parsed to tasks

**2. Native Mobile Testing**
- Test iOS apps with Aware instrumentation
- 99.3% token efficiency (vs screenshots)
- Ghost UI testing without simulators

**3. Context Capture**
- Review PRs on phone during commute
- Annotate code with Apple Pencil (iPad)
- Record voice notes: "This function needs refactoring because..."

**4. Handoff Workflows**
- Start on iPhone → Continue on Mac seamlessly
- Universal Clipboard with context
- AirDrop projects with full instrumentation

---

### Layer 1: UI Instrumentation ✅

**Status**: Production-ready (v3.1.0)

**iOS-Optimized Features**:
```swift
// iPhone-specific gestures
Button("Login") { login() }
    .awareButton("login-btn", label: "Login")
    .awareGesture(.longPress) { showOptions() }
    .awareGesture(.swipe(.left)) { dismiss() }

// iPad-specific (split view)
NavigationSplitView {
    SidebarView()
        .awareContainer("sidebar", label: "File Browser")
} detail: {
    EditorView()
        .awareContainer("editor", label: "Code Editor")
}
.awareNavigation("split-view", style: .threeColumn)

// Accessibility (VoiceOver integration)
Text("Hello")
    .aware("greeting", label: "Greeting message")
    .accessibilityLabel("Hello, welcome to Breathe")  // VoiceOver reads this
```

**Token Efficiency**: 110 tokens for full iOS screen

**iOS-Specific Testing**:
```swift
// Test iOS app with Aware
let app = XCUIApplication()
app.launch()

// Aware captures UI state
let snapshot = await Aware.shared.snapshot(format: .compact)

// LLM verifies without screenshots
XCTAssertTrue(snapshot.contains("login-btn"))
XCTAssertTrue(snapshot.contains("password-field[secure]"))

// Ghost UI testing
await Aware.shared.tap(viewId: "login-btn")
await Aware.shared.typeText(viewId: "email-field", text: "test@example.com")
```

---

### Layer 2: File System (App Sandbox) ⚠️

**Status**: NEW v4.0 (limited scope)

**iOS Constraints**:
- ❌ Cannot monitor system-wide files
- ✅ Can monitor app's own Documents directory
- ✅ Can monitor iCloud Drive (if enabled)
- ✅ Can monitor Files app bookmarks

**Strategy: Document-Based Apps**

```swift
// Monitor app's Documents directory
let documentsURL = FileManager.default.urls(
    for: .documentDirectory,
    in: .userDomainMask
).first!

let monitor = AwareFileSystem.monitor(
    path: documentsURL.path,
    scope: .appSandbox
)

// Use cases:
// 1. Breathe iOS - Edit code files in app
// 2. Working Copy integration - Git client with Aware
// 3. iCloud Drive - Sync files from Mac
```

**iOS-Specific: Files App Integration**

```swift
// Request access to external files
import UniformTypeIdentifiers

struct AwareDocumentPicker: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: [.sourceCode, .text],
            asCopy: false  // Get bookmark for ongoing access
        )
        return picker
    }
}

// User grants access → Aware can monitor
let bookmark = try URL.bookmarkData(
    withContentsOf: url,
    options: .minimalBookmark,
    includingResourceValuesForKeys: nil,
    relativeTo: nil
)

// Store bookmark → access persists across launches
UserDefaults.standard.set(bookmark, forKey: "projectBookmark")
```

**Token Efficiency**: Same as macOS (150 tokens per file change)

**Realistic iOS File Workflows**:
1. ✅ Edit project cloned in app (Working Copy, Textastic)
2. ✅ Monitor iCloud Drive projects
3. ✅ Files app bookmarks (user grants access)
4. ❌ Monitor system-wide files (impossible)

---

### Layer 3: Network (App Scoped) ⚠️

**Status**: NEW v4.0 (app requests only)

**iOS Constraints**:
- ❌ Cannot monitor system-wide network
- ✅ Can intercept app's own URLSession requests
- ✅ Can use Network.framework (app-scoped)

**Strategy: Track Breathe iOS API Calls**

```swift
// Intercept Breathe iOS → AetherMCP requests
class AwareNetworkInterceptor: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        // Only intercept our own API calls
        request.url?.host == "api.breathe.cogito.cv"
    }

    override func startLoading() {
        // Record request
        AwareGraph.record(
            node: .networkRequest(
                url: request.url!,
                method: request.httpMethod!,
                intent: .syncSession,
                triggeredBy: .userAction("sync-button")
            )
        )

        // Execute request
        // ... URLSession.shared.dataTask ...
    }
}
```

**Token Efficiency**: 500 tokens per API call (same as macOS)

**iOS-Specific Use Cases**:
1. ✅ Debug API failures on mobile
2. ✅ Track sync operations (iPhone → Mac)
3. ✅ Monitor GitHub API calls (PR reviews)
4. ❌ System-wide network monitoring (impossible)

---

### Layer 4: Process Tracking ❌

**Status**: NOT POSSIBLE on iOS

**iOS Constraints**:
- iOS does not expose process APIs to third-party apps
- No equivalent of NSTask, Process, or fork/exec
- Cannot spawn child processes (except via XPC for extensions)

**Strategy: SKIP on iOS**

**Alternative**: Track "async operations" instead
```swift
// Instead of processes, track long-running tasks
struct AwareOperation {
    let id: UUID
    let type: OperationType  // .build, .test, .sync, .download
    let intent: AwareIntent
    var status: OperationStatus  // .pending, .running, .completed, .failed
    var progress: Double  // 0.0 → 1.0
}

// Example: Track file sync
let operation = AwareOperation(
    id: UUID(),
    type: .sync,
    intent: .backup,
    status: .running,
    progress: 0.0
)

await AwareGraph.record(node: .operation(operation))

// Update progress
operation.progress = 0.5
await AwareGraph.update(operation)

// Complete
operation.status = .completed
await AwareGraph.update(operation)
```

**Token Efficiency**: 100 tokens per operation (lightweight)

---

### iOS-Specific: Siri Shortcuts Integration 🆕

**New Feature**: Expose Aware capabilities via Shortcuts.

```swift
import AppIntents

struct CaptureContextIntent: AppIntent {
    static var title: LocalizedStringResource = "Capture Development Context"
    static var description = IntentDescription("Save current coding context for later")

    @Parameter(title: "Context Type")
    var contextType: ContextType

    func perform() async throws -> some IntentResult {
        // Capture UI state
        let snapshot = await Aware.shared.snapshot(format: .compact)

        // Store in AwareGraph
        await AwareGraph.record(
            node: .contextCapture(
                type: contextType,
                snapshot: snapshot,
                location: CLLocationManager().location,
                timestamp: Date()
            )
        )

        // Sync to Mac via iCloud
        try await AwareSync.push()

        return .result(value: "Context captured and synced to Mac")
    }
}

enum ContextType: String, AppEnum {
    case bug = "Bug"
    case idea = "Feature Idea"
    case question = "Question"
    case review = "Code Review"

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Context Type")
}
```

**User Workflow**:
1. See a bug in production app
2. Say: "Hey Siri, capture bug context"
3. Siri: "Context captured and synced to Mac"
4. Open Breathe on Mac → Context appears in sidebar
5. LLM has full context (110 tokens)

**Token Efficiency**: 110 tokens (UI) + 50 tokens (location/time) = 160 tokens total

---

### iOS-Specific: Apple Pencil Annotations (iPad) 🆕

**New Feature**: Annotate code with Apple Pencil, convert to structured data.

```swift
import PencilKit

struct AwareCodeAnnotation: View {
    @State private var canvasView = PKCanvasView()
    let code: String

    var body: some View {
        VStack {
            // Show code
            Text(code)
                .font(.system(.body, design: .monospaced))

            // Drawing canvas overlay
            PencilKitView(canvasView: $canvasView)
                .frame(height: 200)
        }
        .toolbar {
            Button("Save Annotation") {
                saveAnnotation()
            }
        }
    }

    func saveAnnotation() {
        // Convert drawing to text (OCR + ML)
        let drawing = canvasView.drawing
        let analysis = PKDrawing.analyze(drawing)

        // Extract structured data
        let annotation = AwareAnnotation(
            code: code,
            drawing: drawing.dataRepresentation(),
            extractedText: analysis.transcription,
            intent: analysis.intent,  // e.g., "refactor", "bug", "question"
            location: analysis.boundingBox
        )

        // Store in AwareGraph
        AwareGraph.record(node: .annotation(annotation))

        // Sync to Mac
        AwareSync.push()
    }
}
```

**Token Efficiency**:
- Drawing data: 500 bytes (compressed)
- Extracted text: 50 tokens
- Total: ~60 tokens (vs 5,000 for screenshot)

**Use Case**:
1. Review PR on iPad during flight
2. Draw arrows, circle bugs, write notes
3. Sync to Mac
4. LLM sees annotations: "User circled line 42, wrote 'memory leak?'"

---

## Cross-Device Workflows

### The Killer Feature: iPhone ↔ Mac Continuity

**Strategy**: Make context transfer seamless.

### Workflow 1: Bug Capture on iPhone → Fix on Mac

```
┌─────────────────────────────────────────┐
│ iPhone (Production App)                 │
│                                         │
│ 1. User sees bug                        │
│ 2. "Hey Siri, capture bug"              │
│ 3. Aware captures:                      │
│    - UI state (110 tokens)              │
│    - Location (10 tokens)               │
│    - Screenshot (optional)              │
│ 4. Syncs to iCloud                      │
└─────────────────────────────────────────┘
            │
            │ iCloud sync (<1 second)
            ▼
┌─────────────────────────────────────────┐
│ Mac (Breathe IDE)                       │
│                                         │
│ 1. Notification: "Bug captured"        │
│ 2. Opens context sidebar                │
│ 3. LLM loads context (120 tokens)      │
│ 4. Suggests: "Button#save-btn disabled" │
│    "Likely: NetworkRequest timed out"   │
│ 5. Opens relevant file                  │
│ 6. Applies fix                          │
└─────────────────────────────────────────┘
```

**Time Saved**: 10+ minutes (no manual bug report, instant context)

**Token Cost**: 120 tokens ($0.00036) vs manual description (500+ tokens)

---

### Workflow 2: Code Review on iPhone → Continue on Mac

```
┌─────────────────────────────────────────┐
│ iPhone (GitHub App / Safari)            │
│                                         │
│ 1. Opens PR on commute                  │
│ 2. Reads code changes                   │
│ 3. Adds annotations (Aware captures)    │
│    - "Line 42: Memory leak risk"        │
│    - "Line 89: Consider error handling" │
│ 4. Marks progress: "Reviewed 3/8 files" │
│ 5. Syncs to iCloud                      │
└─────────────────────────────────────────┘
            │
            │ iCloud sync
            ▼
┌─────────────────────────────────────────┐
│ Mac (Breathe IDE)                       │
│                                         │
│ 1. Opens PR in IDE                      │
│ 2. Context restored:                    │
│    - Already reviewed files (grayed)    │
│    - Cursor at next unreviewed file     │
│    - Annotations shown inline           │
│ 3. Continue review seamlessly           │
└─────────────────────────────────────────┘
```

**Value**: 30% faster code reviews (no re-reading already reviewed files)

---

### Workflow 3: Voice Memo → Task on Mac

```
┌─────────────────────────────────────────┐
│ iPhone (Walking / Driving)              │
│                                         │
│ 1. Idea strikes                         │
│ 2. Voice memo: "Add feature that lets   │
│    users export session history as PDF" │
│ 3. Siri transcribes + analyzes          │
│ 4. Aware extracts:                      │
│    - Feature: "Export session to PDF"   │
│    - Intent: .feature                   │
│    - Priority: P2 (inferred)            │
│ 5. Syncs to iCloud                      │
└─────────────────────────────────────────┘
            │
            │ iCloud sync + ML processing
            ▼
┌─────────────────────────────────────────┐
│ Mac (Breathe IDE)                       │
│                                         │
│ 1. New task appears in backlog          │
│ 2. Already structured:                  │
│    - Title: "Export session to PDF"     │
│    - Type: Feature                      │
│    - Priority: P2                       │
│    - Context: Voice transcription       │
│ 3. LLM can immediately start planning   │
└─────────────────────────────────────────┘
```

**Token Efficiency**: 100 tokens (structured task) vs 500 tokens (raw transcription)

---

### Technical: Cross-Device Sync (CloudKit)

**Implementation**:
```swift
import CloudKit

class AwareCloudSync {
    private let container = CKContainer(identifier: "iCloud.cv.cogito.breathe")
    private let database: CKDatabase

    init() {
        self.database = container.privateCloudDatabase
    }

    // Push context from iPhone
    func push(_ context: AwareContext) async throws {
        let record = CKRecord(recordType: "AwareContext")
        record["type"] = context.type.rawValue
        record["data"] = context.snapshot
        record["intent"] = context.intent.description
        record["timestamp"] = context.timestamp
        record["device"] = "iPhone"

        // Atomic save with conflict resolution
        try await database.save(record)

        // Send silent push to Mac
        let notification = CKNotification(recordID: record.recordID)
        notification.soundName = nil  // Silent
        try await database.send(notification)
    }

    // Pull context on Mac
    func pull() async throws -> [AwareContext] {
        let query = CKQuery(
            recordType: "AwareContext",
            predicate: NSPredicate(format: "device == %@", "iPhone")
        )

        let results = try await database.records(matching: query)
        return results.map { AwareContext(from: $0) }
    }

    // Real-time updates via subscriptions
    func subscribe() async throws {
        let subscription = CKQuerySubscription(
            recordType: "AwareContext",
            predicate: NSPredicate(value: true),
            options: [.firesOnRecordCreation, .firesOnRecordUpdate]
        )

        let notification = CKSubscription.NotificationInfo()
        notification.shouldSendContentAvailable = true
        subscription.notificationInfo = notification

        try await database.save(subscription)
    }
}
```

**Performance**:
- Latency: <500ms (iPhone → iCloud → Mac)
- Conflicts: Last-write-wins (acceptable for context)
- Offline: Queues changes, syncs when online
- Cost: Free (within iCloud quota)

**Privacy**:
- Private CloudKit database (not shared)
- End-to-end encrypted
- User controls data (Settings → iCloud → Breathe)

---

## Apple-Specific Advantages

### 1. Swift Concurrency (async/await)

**Benefit**: AwareGraph queries are non-blocking.

```swift
// Multiple queries in parallel
async let uiState = Aware.shared.snapshot(format: .compact)
async let fileChanges = AwareGraph.query(.fileChanges(since: .now - 3600))
async let networkRequests = AwareGraph.query(.networkRequests(since: .now - 3600))

// All complete in parallel (~10ms total)
let (ui, files, network) = await (uiState, fileChanges, networkRequests)

// Token efficient summary
let summary = """
UI: \(ui.elementCount) elements
Files: \(files.count) changed
Network: \(network.count) requests
"""  // 50 tokens total
```

---

### 2. Combine Framework (Reactive Streams)

**Benefit**: Real-time UI updates for token budget.

```swift
import Combine

class TokenBudgetViewModel: ObservableObject {
    @Published var tokensUsed: Int = 0
    @Published var estimatedCost: Double = 0.0
    @Published var recommendations: [Recommendation] = []

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Subscribe to AwareGraph updates
        AwareGraph.publisher(for: .metrics)
            .map { metrics in metrics.totalTokens }
            .assign(to: &$tokensUsed)

        // Compute cost in real-time
        $tokensUsed
            .map { Double($0) / 1_000_000 * 3.0 }  // $3/M tokens
            .assign(to: &$estimatedCost)

        // Generate recommendations
        $tokensUsed
            .throttle(for: .seconds(5), scheduler: RunLoop.main, latest: true)
            .map { AwareOptimizer.recommendations(for: $0) }
            .assign(to: &$recommendations)
    }
}
```

---

### 3. SwiftUI (Declarative UI)

**Benefit**: UI state = UI structure (perfect for Aware).

```swift
// SwiftUI view
struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false

    var body: some View {
        VStack {
            TextField("Email", text: $email)
                .awareTextField("email", text: $email, label: "Email")

            SecureField("Password", text: $password)
                .awareSecureField("password", text: $password, label: "Password")

            Button("Login") { login() }
                .awareButton("login", label: "Login")
                .disabled(isLoading)
                .awareState("isLoading", value: isLoading)
        }
    }
}

// Aware captures this as:
// Container#login-form
//   TextField#email[value="", label="Email"]
//   SecureField#password[value="***", label="Password"]
//   Button#login[enabled, label="Login", loading=false]
// Total: 110 tokens (vs 15,000 screenshot)
```

---

### 4. Core ML (On-Device ML)

**Benefit**: Intent inference runs locally (fast + private).

```swift
import CoreML

class AwareIntentClassifier {
    private let model: IntentClassifierModel  // Trained CoreML model

    func inferIntent(from fileChange: FileChange) -> AwareIntent {
        // Prepare features
        let features = IntentClassifierInput(
            fileName: fileChange.path,
            changeType: fileChange.type.rawValue,
            linesAdded: fileChange.linesAdded,
            linesRemoved: fileChange.linesRemoved,
            recentCommits: fileChange.recentCommits
        )

        // Run on Neural Engine (<1ms)
        let prediction = try! model.prediction(input: features)

        return AwareIntent(
            type: prediction.intentType,
            confidence: prediction.confidence
        )
    }
}
```

**Performance**:
- Inference: <1ms (Neural Engine)
- Accuracy: ~80% (improves with usage)
- Privacy: All on-device (never sent to cloud)

---

### 5. Universal Apps (Catalyst)

**Benefit**: Single codebase for macOS + iOS + iPadOS.

```swift
// Shared Aware instrumentation
#if os(macOS)
import AppKit
typealias PlatformColor = NSColor
#elseif os(iOS)
import UIKit
typealias PlatformColor = UIColor
#endif

extension View {
    func awarePlatformOptimized(_ id: String) -> some View {
        #if os(macOS)
        return self
            .aware(id, label: id)
            .awareMacWindow(id)  // Mac-specific
        #elseif os(iOS)
        return self
            .aware(id, label: id)
            .awareGesture(.longPress) { }  // iOS-specific
        #endif
    }
}
```

**Result**: Write once, instrument everywhere.

---

## Technical Implementation

### Shared Package Structure

```
Aware/
├── AwareCore/                    # Shared (macOS + iOS)
│   ├── Types/                   # Protocols, intents, commands
│   ├── Services/                # AwareService, AwareGraph
│   └── Documentation/           # Protocol generator
│
├── AwareiOS/                     # iOS-specific
│   ├── Platform/
│   │   ├── AwareIOSPlatform.swift           # iOS implementation
│   │   ├── AwareIOSFileSystem.swift         # Sandbox-aware file monitoring
│   │   ├── AwareIOSNetwork.swift            # URLProtocol interception
│   │   └── AwareIOSSync.swift               # CloudKit integration
│   ├── Modifiers/
│   │   └── UIConvenienceModifiers.swift     # iOS-specific modifiers
│   └── Shortcuts/
│       └── AwareIntents.swift               # Siri Shortcuts
│
├── AwareMacOS/                   # macOS-specific
│   ├── Platform/
│   │   ├── AwareMacOSPlatform.swift         # macOS implementation
│   │   ├── AwareMacOSFileSystem.swift       # FSEvents integration
│   │   ├── AwareMacOSNetwork.swift          # Network.framework
│   │   ├── AwareMacOSProcess.swift          # Process tracking
│   │   └── AwareMacOSAssistant.swift        # Local Phi-3
│   └── Modifiers/
│       └── MacConvenienceModifiers.swift    # Mac-specific modifiers
│
└── AwareBridge/                  # Cross-device sync
    ├── CloudKitSync.swift       # iCloud synchronization
    ├── WebSocketBridge.swift    # Real-time IPC
    └── MCPProtocol.swift        # MCP command protocol
```

---

### Platform Detection & Graceful Degradation

```swift
@MainActor
public class Aware: ObservableObject {
    public static let shared = Aware()

    // Detect capabilities at runtime
    public struct Capabilities {
        let fullFileSystem: Bool
        let systemWideNetwork: Bool
        let processTracking: Bool
        let localAssistant: Bool
        let crossDeviceSync: Bool

        static var current: Capabilities {
            #if os(macOS)
            return Capabilities(
                fullFileSystem: true,
                systemWideNetwork: hasNetworkExtension(),
                processTracking: true,
                localAssistant: hasNeuralEngine(),
                crossDeviceSync: true
            )
            #elseif os(iOS)
            return Capabilities(
                fullFileSystem: false,  // Sandbox only
                systemWideNetwork: false,
                processTracking: false,
                localAssistant: hasNeuralEngine(),
                crossDeviceSync: true
            )
            #endif
        }
    }

    public let capabilities = Capabilities.current

    // Methods gracefully degrade
    public func trackProcess(_ command: String) async -> AwareProcess? {
        guard capabilities.processTracking else {
            // iOS: Track as async operation instead
            return await trackOperation(type: .external, command: command)
        }

        // macOS: Full process tracking
        return await AwareMacOSProcess.track(command)
    }
}
```

---

## 12-Month Roadmap

### Q1 2026: File System Layer (macOS + iOS)

**Goals**:
- Full file system tracking on macOS (FSEvents)
- App sandbox tracking on iOS (Documents + iCloud Drive)
- Cross-device sync via CloudKit

**Deliverables**:
- `AwareMacOSFileSystem.swift` (FSEvents integration)
- `AwareIOSFileSystem.swift` (Sandbox-aware)
- `AwareCloudSync.swift` (CloudKit)
- 8 `fs_*` MCP tools (work on both platforms)
- 20+ unit tests (platform-specific)

**Success Metrics**:
- ✅ macOS: Monitor entire workspace (<1% overhead)
- ✅ iOS: Monitor app documents + iCloud Drive
- ✅ Sync latency: <500ms (iPhone → Mac)
- ✅ 85% token reduction (both platforms)

---

### Q2 2026: Network + Operations (macOS + iOS)

**Goals**:
- Network tracking on both platforms (app-scoped)
- Process tracking on macOS (child processes)
- Async operations on iOS (instead of processes)

**Deliverables**:
- `AwareMacOSNetwork.swift` (URLSession + Network.framework)
- `AwareIOSNetwork.swift` (URLProtocol only)
- `AwareMacOSProcess.swift` (NSTask + libproc)
- `AwareIOSOperations.swift` (async task tracking)
- 13 MCP tools (`net_*` + `proc_*` / `op_*`)

**Success Metrics**:
- ✅ macOS: Full network + process tracking
- ✅ iOS: App network + async operations
- ✅ 75-90% token reduction

---

### Q3 2026: AwareGraph + Continuity

**Goals**:
- Unified knowledge graph (works offline)
- Cross-device workflows (iPhone → Mac)
- Siri Shortcuts integration

**Deliverables**:
- `AwareGraph.swift` (SQLite + FTS5, shared)
- `AwareContinuity.swift` (Handoff + Universal Clipboard)
- `AwareIntents.swift` (Siri Shortcuts)
- 5 `graph_*` MCP tools
- 3 Siri shortcuts (Capture Context, Sync to Mac, Query Graph)

**Success Metrics**:
- ✅ Graph queries: <10ms (both platforms)
- ✅ Sync latency: <500ms (iPhone → Mac)
- ✅ Siri shortcuts: 3 working examples
- ✅ Full system state: <2,000 tokens

---

### Q4 2026: Token Budget + Local Assistant

**Goals**:
- Token budget tracking (both platforms)
- Local assistant on macOS (Phi-3 on Neural Engine)
- iPad-specific features (Apple Pencil annotations)

**Deliverables**:
- `TokenBudgetTracker.swift` (shared)
- `AwareMacOSAssistant.swift` (Phi-3 + Core ML)
- `AwareAnnotations.swift` (iPad Apple Pencil)
- 4 `token_budget_*` MCP tools
- 3 `agent_*` MCP tools (macOS only)

**Success Metrics**:
- ✅ Budget tracking: Real-time, <1% overhead
- ✅ macOS assistant: <100ms, 60-70% accuracy
- ✅ iPad annotations: OCR + intent extraction

---

### Q1 2027: Polish + Launch

**Goals**:
- Production-ready v4.0 release
- App Store optimization (iOS + macOS)
- Performance tuning

**Deliverables**:
- Performance optimization (<3% overhead on both)
- App Store submission (iOS + macOS Universal)
- Comprehensive documentation
- Tutorial videos (3-5 examples)
- Blog post + launch
- Open source release (MIT license)

**Success Metrics**:
- ✅ 10,000 active users (5K macOS, 5K iOS)
- ✅ App Store rating: 4.5+ stars
- ✅ Token savings: $10,000+ cumulative
- ✅ 0 privacy incidents

---

## Success Metrics (Apple Platforms)

### Product Metrics

| Metric | macOS Target | iOS Target | Combined |
|--------|-------------|-----------|----------|
| **Active Users** | 5,000 | 5,000 | 10,000 |
| **Cross-Device Sessions** | - | - | 30% |
| **Avg Session Cost** | <$0.10 | <$0.05 | <$0.08 |
| **Token Savings** | $8,000 | $2,000 | $10,000 |
| **Time Savings** | 30% | 15% | 25% |

### Platform-Specific Metrics

| Metric | macOS | iOS |
|--------|-------|-----|
| **File Monitoring** | Full workspace | App sandbox |
| **Network Tracking** | Full (with entitlement) | App only |
| **Process Tracking** | ✅ Supported | ❌ N/A |
| **Local Assistant** | ✅ 60-70% accuracy | ⚠️ Experimental |
| **Cross-Device Sync** | ✅ Supported | ✅ Supported |

---

## Conclusion

**Apple-First Strategy** = Deep integration with iOS + macOS ecosystems instead of shallow cross-platform support.

**Key Decisions**:
1. ✅ **Full macOS support** - All 4 layers (UI, Files, Network, Processes)
2. ✅ **Optimized iOS support** - Focus on strengths (UI, context capture, sync)
3. ✅ **Cross-device workflows** - Make iPhone ↔ Mac seamless
4. ✅ **Apple-specific APIs** - CloudKit, Core ML, Siri Shortcuts, Apple Pencil
5. ❌ **Skip iOS limitations** - Don't fight sandboxing, design around it

**Differentiation**:
- Only framework with 99.3% token reduction on iOS UI testing
- Only solution with cross-device context sync (iPhone → Mac)
- Only tool with Siri Shortcuts for context capture
- Only platform using Neural Engine for local assistance

**Timeline**: 12 months to feature-complete v4.0 (macOS + iOS)

**Next Steps**:
1. Validate strategy with Apple developer community
2. File for App Store approval (start early)
3. Kick off Q1 2026 (File System layer)
4. Ship beta to TestFlight (Q2 2026)

---

**Status**: Apple platform strategy - ready for implementation

**Contact**: team@cogito.cv
