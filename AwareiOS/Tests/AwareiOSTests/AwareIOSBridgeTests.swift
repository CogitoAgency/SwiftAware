//
//  AwareIOSBridgeTests.swift
//  AwareiOSTests
//
//  Tests for AwareIPCService and IPC functionality.
//  Covers initialization, heartbeat, file-based commands,
//  transport modes, and error handling.
//

#if os(iOS)
import XCTest
@testable import AwareiOS
import AwareCore
import Foundation

@MainActor
final class AwareIOSBridgeTests: XCTestCase {

    var tempDir: String!

    override func setUp() async throws {
        try await super.setUp()
        tempDir = "/tmp/aware-test-\(UUID().uuidString)"
        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        if let tempDir = tempDir {
            try? FileManager.default.removeItem(atPath: tempDir)
        }
        try await super.tearDown()
    }

    // MARK: - Initialization Tests (5 tests)

    func testInitializationWithFileBasedMode() {
        let service = AwareIPCService(ipcPath: tempDir, transportMode: .fileBased)

        XCTAssertNotNil(service)
        // Verify directory was created
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDir))
    }

    func testInitializationWithAutoMode() {
        let service = AwareIPCService(ipcPath: tempDir, transportMode: .auto)

        XCTAssertNotNil(service)
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDir))
    }

    func testInitializationWithConfig() {
        let config = AwareIOSConfiguration(
            ipcPath: tempDir,
            transportMode: .fileBased,
            webSocketHost: "localhost",
            webSocketPort: 9999,
            heartbeatInterval: 1.0,
            commandTimeoutAttempts: 30
        )

        let service = AwareIPCService(config: config)

        XCTAssertNotNil(service)
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDir))
    }

    func testTildeExpansion() {
        let service = AwareIPCService(ipcPath: "~/aware-test", transportMode: .fileBased)

        XCTAssertNotNil(service)
        // Should expand ~ to home directory
        let expandedPath = ("~/aware-test" as NSString).expandingTildeInPath
        XCTAssertTrue(FileManager.default.fileExists(atPath: expandedPath))

        // Cleanup
        try? FileManager.default.removeItem(atPath: expandedPath)
    }

    func testNestedDirectoryCreation() {
        let nestedPath = tempDir + "/nested/deep/ipc"
        let service = AwareIPCService(ipcPath: nestedPath, transportMode: .fileBased)

        XCTAssertNotNil(service)
        XCTAssertTrue(FileManager.default.fileExists(atPath: nestedPath))
    }

    // MARK: - Heartbeat Tests (4 tests)

    func testHeartbeatStart() async {
        let service = AwareIPCService(ipcPath: tempDir, transportMode: .fileBased)

        service.startHeartbeat(interval: 0.5)

        // Wait for heartbeat to write
        try? await Task.sleep(for: .seconds(1))

        let heartbeatPath = tempDir + "/ui_watcher_heartbeat.txt"
        XCTAssertTrue(FileManager.default.fileExists(atPath: heartbeatPath))

        service.stopHeartbeat()
    }

    func testHeartbeatUpdates() async {
        let service = AwareIPCService(ipcPath: tempDir, transportMode: .fileBased)

        service.startHeartbeat(interval: 0.3)

        // Wait for first heartbeat
        try? await Task.sleep(for: .seconds(0.4))

        let heartbeatPath = tempDir + "/ui_watcher_heartbeat.txt"
        let firstContent = try? String(contentsOfFile: heartbeatPath, encoding: .utf8)

        // Wait for second heartbeat
        try? await Task.sleep(for: .seconds(0.4))

        let secondContent = try? String(contentsOfFile: heartbeatPath, encoding: .utf8)

        XCTAssertNotNil(firstContent)
        XCTAssertNotNil(secondContent)
        XCTAssertNotEqual(firstContent, secondContent)  // Timestamps should differ

        service.stopHeartbeat()
    }

    func testHeartbeatStop() async {
        let service = AwareIPCService(ipcPath: tempDir, transportMode: .fileBased)

        service.startHeartbeat(interval: 0.5)
        try? await Task.sleep(for: .seconds(0.6))

        service.stopHeartbeat()

        let heartbeatPath = tempDir + "/ui_watcher_heartbeat.txt"
        let contentBefore = try? String(contentsOfFile: heartbeatPath, encoding: .utf8)

        // Wait and verify no more updates
        try? await Task.sleep(for: .seconds(0.6))

        let contentAfter = try? String(contentsOfFile: heartbeatPath, encoding: .utf8)

        XCTAssertNotNil(contentBefore)
        XCTAssertEqual(contentBefore, contentAfter)  // Should not have updated
    }

    func testHeartbeatISO8601Format() async {
        let service = AwareIPCService(ipcPath: tempDir, transportMode: .fileBased)

        service.startHeartbeat(interval: 0.5)
        try? await Task.sleep(for: .seconds(0.6))

        let heartbeatPath = tempDir + "/ui_watcher_heartbeat.txt"
        let content = try? String(contentsOfFile: heartbeatPath, encoding: .utf8)

        XCTAssertNotNil(content)

        // Verify ISO8601 format (basic check)
        if let content = content {
            XCTAssertTrue(content.contains("T"))  // ISO8601 has T separator
            XCTAssertTrue(content.contains("Z") || content.contains("+"))  // Timezone
        }

        service.stopHeartbeat()
    }

    // MARK: - File-Based Command Tests (6 tests)

    func testFileBasedCommandWritesJSON() async throws {
        let service = AwareIPCService(ipcPath: tempDir, transportMode: .fileBased)

        let command = AwareCommand(action: "tap", parameters: ["target": "button1"])

        // Spawn background task to write result
        Task {
            try? await Task.sleep(for: .milliseconds(50))
            let result = AwareResult(success: true, data: ["status": "ok"], error: nil)
            let resultData = try! JSONEncoder().encode(result)
            let resultPath = tempDir + "/ui_result.json"
            try! resultData.write(to: URL(fileURLWithPath: resultPath))
        }

        let result = try await service.sendCommand(command)

        XCTAssertTrue(result.success)
        XCTAssertEqual(result.data?["status"], "ok")
    }

    func testFileBasedCommandJSONFormat() async throws {
        let service = AwareIPCService(ipcPath: tempDir, transportMode: .fileBased)

        let command = AwareCommand(action: "typeText", parameters: ["target": "field1", "text": "Hello"])

        // Spawn background task
        Task {
            try? await Task.sleep(for: .milliseconds(50))

            // Verify command JSON was written correctly
            let commandPath = tempDir + "/ui_command.json"
            let commandData = try! Data(contentsOf: URL(fileURLWithPath: commandPath))
            let decodedCommand = try! JSONDecoder().decode(AwareCommand.self, from: commandData)

            XCTAssertEqual(decodedCommand.action, "typeText")
            XCTAssertEqual(decodedCommand.parameters["target"], "field1")
            XCTAssertEqual(decodedCommand.parameters["text"], "Hello")

            // Write result
            let result = AwareResult(success: true, data: nil, error: nil)
            let resultData = try! JSONEncoder().encode(result)
            let resultPath = tempDir + "/ui_result.json"
            try! resultData.write(to: URL(fileURLWithPath: resultPath))
        }

        let result = try await service.sendCommand(command)
        XCTAssertTrue(result.success)
    }

    func testFileBasedCommandTimeout() async {
        let config = AwareIOSConfiguration(
            ipcPath: tempDir,
            transportMode: .fileBased,
            webSocketHost: "localhost",
            webSocketPort: 9999,
            heartbeatInterval: 2.0,
            commandTimeoutAttempts: 5  // 500ms timeout
        )
        let service = AwareIPCService(config: config)

        let command = AwareCommand(action: "tap", parameters: ["target": "button1"])

        // Don't write result - should timeout

        do {
            let _ = try await service.sendCommand(command)
            XCTFail("Expected timeout error")
        } catch AwareIPCError.timeout {
            // Expected
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testFileBasedCommandPolling() async throws {
        let service = AwareIPCService(ipcPath: tempDir, transportMode: .fileBased)

        let command = AwareCommand(action: "tap", parameters: ["target": "button1"])

        // Write result after delay
        Task {
            try? await Task.sleep(for: .milliseconds(200))
            let result = AwareResult(success: true, data: nil, error: nil)
            let resultData = try! JSONEncoder().encode(result)
            let resultPath = tempDir + "/ui_result.json"
            try! resultData.write(to: URL(fileURLWithPath: resultPath))
        }

        let startTime = Date()
        let result = try await service.sendCommand(command)
        let elapsed = Date().timeIntervalSince(startTime)

        XCTAssertTrue(result.success)
        XCTAssertGreaterThan(elapsed, 0.2)  // Should have waited
        XCTAssertLessThan(elapsed, 1.0)     // But not too long
    }

    func testFileBasedCommandCleanup() async throws {
        let service = AwareIPCService(ipcPath: tempDir, transportMode: .fileBased)

        let command = AwareCommand(action: "tap", parameters: ["target": "button1"])

        Task {
            try? await Task.sleep(for: .milliseconds(50))
            let result = AwareResult(success: true, data: nil, error: nil)
            let resultData = try! JSONEncoder().encode(result)
            let resultPath = tempDir + "/ui_result.json"
            try! resultData.write(to: URL(fileURLWithPath: resultPath))
        }

        let _ = try await service.sendCommand(command)

        // Command file should have been written
        let commandPath = tempDir + "/ui_command.json"
        XCTAssertTrue(FileManager.default.fileExists(atPath: commandPath))
    }

    func testMultipleConsecutiveCommands() async throws {
        let service = AwareIPCService(ipcPath: tempDir, transportMode: .fileBased)

        // Command 1
        let command1 = AwareCommand(action: "tap", parameters: ["target": "button1"])
        Task {
            try? await Task.sleep(for: .milliseconds(50))
            let result = AwareResult(success: true, data: ["id": "1"], error: nil)
            let resultData = try! JSONEncoder().encode(result)
            try! resultData.write(to: URL(fileURLWithPath: tempDir + "/ui_result.json"))
        }
        let result1 = try await service.sendCommand(command1)

        // Clean up result file
        try? FileManager.default.removeItem(atPath: tempDir + "/ui_result.json")

        // Command 2
        let command2 = AwareCommand(action: "tap", parameters: ["target": "button2"])
        Task {
            try? await Task.sleep(for: .milliseconds(50))
            let result = AwareResult(success: true, data: ["id": "2"], error: nil)
            let resultData = try! JSONEncoder().encode(result)
            try! resultData.write(to: URL(fileURLWithPath: tempDir + "/ui_result.json"))
        }
        let result2 = try await service.sendCommand(command2)

        XCTAssertTrue(result1.success)
        XCTAssertEqual(result1.data?["id"], "1")
        XCTAssertTrue(result2.success)
        XCTAssertEqual(result2.data?["id"], "2")
    }

    // MARK: - Transport Mode Tests (3 tests)

    func testFileBasedTransportMode() {
        let service = AwareIPCService(ipcPath: tempDir, transportMode: .fileBased)

        XCTAssertNotNil(service)
        // File-based mode should create directory
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDir))
    }

    func testAutoTransportModeFallback() {
        let service = AwareIPCService(ipcPath: tempDir, transportMode: .auto)

        XCTAssertNotNil(service)
        // Auto mode should fall back to file-based if WebSocket unavailable
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDir))
    }

    func testWebSocketModeWhenUnavailable() {
        // WebSocket mode without AwareBridge should still create file-based
        let service = AwareIPCService(ipcPath: tempDir, transportMode: .webSocket)

        XCTAssertNotNil(service)
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDir))
    }

    // MARK: - Error Handling Tests (2 tests)

    func testIPCErrorTypes() {
        let timeoutError = AwareIPCError.timeout
        let encodingError = AwareIPCError.encodingFailed
        let decodingError = AwareIPCError.decodingFailed
        let notConnectedError = AwareIPCError.notConnected
        let invalidURLError = AwareIPCError.invalidURL
        let connectionTimeoutError = AwareIPCError.connectionTimeout

        XCTAssertEqual(timeoutError.localizedDescription, "IPC command timed out after waiting for response")
        XCTAssertEqual(encodingError.localizedDescription, "Failed to encode command data")
        XCTAssertEqual(decodingError.localizedDescription, "Failed to decode result data")
        XCTAssertEqual(notConnectedError.localizedDescription, "WebSocket is not connected")
        XCTAssertEqual(invalidURLError.localizedDescription, "Invalid WebSocket URL provided")
        XCTAssertEqual(connectionTimeoutError.localizedDescription, "WebSocket connection attempt timed out")
    }

    func testResultSerialization() throws {
        let result = AwareResult(
            success: true,
            data: ["key1": "value1", "key2": "value2"],
            error: nil
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(result)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AwareResult.self, from: data)

        XCTAssertTrue(decoded.success)
        XCTAssertEqual(decoded.data?["key1"], "value1")
        XCTAssertEqual(decoded.data?["key2"], "value2")
        XCTAssertNil(decoded.error)
    }
}

#endif // os(iOS)
