//
//  main.swift
//  AwareTestHarness
//
//  Headless test harness for LLM-driven testing with Aware.
//  Demonstrates TDD workflow and dogfooding validation.
//

import Foundation
import AwareCore
import AwareiOS

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

@main
@MainActor
struct AwareTestHarness {
    static func main() async {
        print("🧪 Aware Test Harness v1.0.0")
        print("════════════════════════════════════")
        print("Headless test environment for LLM testing")
        print("")

        // Configure Aware for testing
        let config = AwareIOSConfiguration(
            ipcPath: "~/.aware",
            transportMode: .webSocket,
            webSocketHost: "127.0.0.1",
            webSocketPort: 8081,
            heartbeatInterval: 2.0,
            commandTimeoutAttempts: 50
        )

        do {
            AwareIOSPlatform.shared.configure(config: config)
            print("✅ Aware configured successfully")
            print("   Transport: WebSocket")
            print("   Port: 8081")
            print("   IPC Path: ~/.aware")
        } catch {
            print("❌ Failed to configure Aware: \(error)")
            return
        }

        // Initialize test harness runner
        print("")
        print("Initializing views...")
        let harness = TestHarnessRunner()
        await harness.initialize()

        print("")
        print("✅ Test harness ready for LLM testing")
        print("════════════════════════════════════")
        print("")
        print("Available views:")
        print("  - LoginView (viewId: 'login-view')")
        print("  - ListViewWithSearch (viewId: 'list-view')")
        print("  - FormView (viewId: 'form-view')")
        print("")
        print("📊 Snapshot available at: ~/.aware/ui-snapshot.json")
        print("🔌 WebSocket server: ws://127.0.0.1:8081")
        print("")
        print("Press Ctrl+C to stop")

        // Keep process alive for testing
        RunLoop.main.run()
    }
}
