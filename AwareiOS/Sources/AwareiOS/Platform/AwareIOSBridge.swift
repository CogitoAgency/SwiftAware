//
//  AwareIOSBridge.swift
//  AwareiOS
//
//  File-based IPC service for Breathe IDE integration.
//  Provides heartbeat monitoring and command/result communication.
//

#if os(iOS)
import Foundation
import AwareCore

// MARK: - IPC Service

@MainActor
final class AwareIPCService {
    private let ipcPath: String
    private var heartbeatTask: Task<Void, Never>?

    init(ipcPath: String) {
        self.ipcPath = (ipcPath as NSString).expandingTildeInPath
        setupIPC()
    }

    private func setupIPC() {
        // Create IPC directory
        try? FileManager.default.createDirectory(
            atPath: ipcPath,
            withIntermediateDirectories: true
        )

        #if DEBUG
        print("AwareIPC: IPC directory created at: \(ipcPath)")
        #endif
    }

    func startHeartbeat(interval: TimeInterval = 2.0) {
        heartbeatTask?.cancel()

        heartbeatTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.writeHeartbeat()
                try? await Task.sleep(for: .seconds(interval))
            }
        }

        #if DEBUG
        print("AwareIPC: Heartbeat started with \(interval)s interval")
        #endif
    }

    private func writeHeartbeat() {
        let heartbeatPath = ipcPath + "/ui_watcher_heartbeat.txt"
        let timestamp = ISO8601DateFormatter().string(from: Date())

        do {
            try timestamp.write(toFile: heartbeatPath, atomically: true, encoding: .utf8)
        } catch {
            #if DEBUG
            print("AwareIPC: Failed to write heartbeat: \(error.localizedDescription)")
            #endif
        }
    }

    func sendCommand(_ command: AwareCommand) async throws -> AwareResult {
        let commandPath = ipcPath + "/ui_command.json"
        let resultPath = ipcPath + "/ui_result.json"

        // Write command
        let commandData = try JSONEncoder().encode(command)
        try commandData.write(to: URL(fileURLWithPath: commandPath))

        // Wait for result (simple polling - will be replaced with WebSocket in Phase 8)
        var attempts = 0
        while attempts < 50 { // 5 second timeout
            if FileManager.default.fileExists(atPath: resultPath) {
                let resultData = try Data(contentsOf: URL(fileURLWithPath: resultPath))
                return try JSONDecoder().decode(AwareResult.self, from: resultData)
            }
            try await Task.sleep(for: .milliseconds(100))
            attempts += 1
        }

        throw AwareIPCError.timeout
    }

    func stopHeartbeat() {
        heartbeatTask?.cancel()
        heartbeatTask = nil
    }
}

// MARK: - IPC Errors

enum AwareIPCError: Error {
    case timeout
    case encodingFailed
    case decodingFailed
}

#endif // os(iOS)
