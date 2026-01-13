//
//  AwareServiceTests.swift
//  Aware
//
//  Basic tests for the Aware framework.
//

import XCTest
@testable import Aware

final class AwareServiceTests: XCTestCase {

    @MainActor
    func testRegisterView() async throws {
        // Given
        let viewId = "test-view-\(UUID().uuidString)"
        let uniqueLabel = "Test View \(viewId)"

        // When
        Aware.shared.registerView(viewId, label: uniqueLabel)

        // Then
        let node = Aware.shared.query().where { $0.id == viewId }.first()
        XCTAssertNotNil(node)
        XCTAssertEqual(node?.label, uniqueLabel)

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    // MARK: - Error Handling Tests

    @MainActor
    func testInvalidViewIdValidation() async throws {
        // Given: Empty view ID
        let invalidId = ""

        // When: Attempt to register view with invalid ID
        Aware.shared.registerView(invalidId, label: "Test View")

        // Then: View should not be registered
        XCTAssertNil(Aware.shared.query().where { $0.id == invalidId }.first())
    }

    @MainActor
    func testDuplicateViewRegistration() async throws {
        // Given: Register a view
        let viewId = "duplicate-test-\(UUID().uuidString)"
        Aware.shared.registerView(viewId, label: "Original Label")

        // When: Try to register the same view with different label
        Aware.shared.registerView(viewId, label: "Different Label")

        // Then: Original view should still exist
        let view = Aware.shared.query().where { $0.id == viewId }.first()
        XCTAssertNotNil(view)
        XCTAssertEqual(view?.label, "Original Label") // Should keep original

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    @MainActor
    func testStateRegistrationForNonexistentView() async throws {
        // Given: Non-existent view ID
        let nonexistentViewId = "nonexistent-\(UUID().uuidString)"

        // When: Try to register state for non-existent view
        Aware.shared.registerState(nonexistentViewId, key: "test", value: "value")

        // Then: State should not be registered
        XCTAssertNil(Aware.shared.getStateValue(nonexistentViewId, key: "test"))
    }

    @MainActor
    func testSnapshotDepthValidation() async throws {
        // Given: Valid views
        setupTestViews(count: 5)

        // When: Try invalid depth
        let result = Aware.shared.captureSnapshot(maxDepth: 0)

        // Then: Should handle gracefully (not crash)
        XCTAssertNotNil(result)
        XCTAssertTrue(result.content.contains("Error") || result.viewCount >= 0)

        // When: Try excessive depth
        let excessiveResult = Aware.shared.captureSnapshot(maxDepth: 100)

        // Then: Should still work
        XCTAssertNotNil(excessiveResult)

        // Cleanup
        Aware.shared.reset()
    }

    // MARK: - Helper Methods

    @MainActor
    private func setupTestViews(count: Int) {
        for i in 0..<count {
            let viewId = "test-view-\(UUID().uuidString)-\(i)"
            Aware.shared.registerView(viewId, label: "Test View \(i)")
        }
    }

    @MainActor
    func testFindElements() async throws {
        // Given
        let viewId1 = "test-find-1-\(UUID().uuidString)"
        let viewId2 = "test-find-2-\(UUID().uuidString)"
        Aware.shared.registerView(viewId1, label: "Button View")
        Aware.shared.registerView(viewId2, label: "Text View")

        // When
        let allViews = Aware.shared.findElements { $0.isVisible }

        // Then
        XCTAssertTrue(allViews.count >= 2)
        XCTAssertTrue(allViews.contains { $0.id == viewId1 })
        XCTAssertTrue(allViews.contains { $0.id == viewId2 })

        // Cleanup
        Aware.shared.unregisterView(viewId1)
        Aware.shared.unregisterView(viewId2)
    }

    @MainActor
    func testFindByLabel() async throws {
        // Given
        let viewId = "test-find-label-\(UUID().uuidString)"
        Aware.shared.registerView(viewId, label: "Login Button")

        // When
        let results = Aware.shared.findByLabel("Login")

        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.id, viewId)

        // Test case-insensitive
        let caseResults = Aware.shared.findByLabel("login")
        XCTAssertEqual(caseResults.count, 1)

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    @MainActor
    func testFindByState() async throws {
        // Given
        let viewId = "test-find-state-\(UUID().uuidString)"
        Aware.shared.registerView(viewId, label: "Test View")
        Aware.shared.registerState(viewId, key: "enabled", value: "true")

        // When
        let results = Aware.shared.findByState(key: "enabled", value: "true")

        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.id, viewId)

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    @MainActor
    func testUpdateFrame() async throws {
        // Given
        let viewId = "test-frame-\(UUID().uuidString)"
        Aware.shared.registerView(viewId, label: "Test View")
        let newFrame = CGRect(x: 10, y: 20, width: 100, height: 200)

        // When
        Aware.shared.updateFrame(viewId, frame: newFrame)

        // Then
        let view = Aware.shared.query().where { $0.id == viewId }.first()
        XCTAssertEqual(view?.frame, newFrame)

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    @MainActor
    func testClearState() async throws {
        // Given
        let viewId = "test-clear-state-\(UUID().uuidString)"
        Aware.shared.registerView(viewId, label: "Test View")
        Aware.shared.registerState(viewId, key: "testKey", value: "testValue")

        // Verify state exists
        XCTAssertEqual(Aware.shared.getStateValue(viewId, key: "testKey"), "testValue")

        // When
        Aware.shared.clearState(viewId)

        // Then
        XCTAssertNil(Aware.shared.getStateValue(viewId, key: "testKey"))

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    @MainActor
    func testStateMatches() async throws {
        // Given
        let viewId = "test-state-match-\(UUID().uuidString)"
        Aware.shared.registerView(viewId, label: "Test View")
        Aware.shared.registerState(viewId, key: "status", value: "active")

        // When & Then
        XCTAssertTrue(Aware.shared.stateMatches(viewId, key: "status", value: "active"))
        XCTAssertFalse(Aware.shared.stateMatches(viewId, key: "status", value: "inactive"))
        XCTAssertFalse(Aware.shared.stateMatches(viewId, key: "nonexistent", value: "active"))

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    @MainActor
    func testRegisterAnimation() async throws {
        // Given
        let viewId = "test-animation-\(UUID().uuidString)"
        Aware.shared.registerView(viewId, label: "Test View")
        let animationState = AwareAnimationState(isAnimating: true, animationType: "spring", duration: 0.3)

        // When
        Aware.shared.registerAnimation(viewId, animation: animationState)

        // Then
        let view = Aware.shared.query().where { $0.id == viewId }.first()
        XCTAssertEqual(view?.animation?.animationType, "spring")
        XCTAssertEqual(view?.animation?.duration, 0.3)
        XCTAssertEqual(view?.animation?.isAnimating, true)

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    @MainActor
    func testClearAnimation() async throws {
        // Given
        let viewId = "test-clear-animation-\(UUID().uuidString)"
        Aware.shared.registerView(viewId, label: "Test View")
        let animationState = AwareAnimationState(isAnimating: true, animationType: "spring", duration: 0.3)
        Aware.shared.registerAnimation(viewId, animation: animationState)

        // Verify animation exists
        var view = Aware.shared.query().where { $0.id == viewId }.first()
        XCTAssertNotNil(view?.animation)

        // When
        Aware.shared.clearAnimation(viewId)

        // Then
        view = Aware.shared.query().where { $0.id == viewId }.first()
        XCTAssertNil(view?.animation)

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    @MainActor
    func testDescribeView() async throws {
        // Given
        let viewId = "test-describe-\(UUID().uuidString)"
        Aware.shared.registerView(viewId, label: "Test View", isContainer: true)
        Aware.shared.registerState(viewId, key: "count", value: "5")

        // When
        let description = Aware.shared.describeView(viewId)

        // Then
        XCTAssertNotNil(description)
        XCTAssertEqual(description?.id, viewId)
        XCTAssertEqual(description?.label, "Test View")
        XCTAssertEqual(description?.isVisible, true)
        XCTAssertEqual(description?.state?["count"], "5")

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    @MainActor
    func testRegisteredViewIds() async throws {
        // Given
        let viewId1 = "test-ids-1-\(UUID().uuidString)"
        let viewId2 = "test-ids-2-\(UUID().uuidString)"

        // Initially should be empty or have existing views
        let initialCount = Aware.shared.registeredViewIds.count

        // When
        Aware.shared.registerView(viewId1, label: "View 1")
        Aware.shared.registerView(viewId2, label: "View 2")

        // Then
        let viewIds = Aware.shared.registeredViewIds
        XCTAssertTrue(viewIds.contains(viewId1))
        XCTAssertTrue(viewIds.contains(viewId2))
        XCTAssertEqual(viewIds.count, initialCount + 2)

        // Cleanup
        Aware.shared.unregisterView(viewId1)
        Aware.shared.unregisterView(viewId2)
    }

    @MainActor
    func testVisibleViewCount() async throws {
        // Given
        let viewId1 = "test-visible-1-\(UUID().uuidString)"
        let viewId2 = "test-visible-2-\(UUID().uuidString)"

        let initialCount = Aware.shared.visibleViewCount

        // When
        Aware.shared.registerView(viewId1, label: "Visible View")
        Aware.shared.registerView(viewId2, label: "Hidden View")

        // Then
        XCTAssertEqual(Aware.shared.visibleViewCount, initialCount + 2)

        // When making one invisible
        Aware.shared.unregisterView(viewId1)

        // Then
        XCTAssertEqual(Aware.shared.visibleViewCount, initialCount + 1)

        // Cleanup
        Aware.shared.unregisterView(viewId2)
    }
}
