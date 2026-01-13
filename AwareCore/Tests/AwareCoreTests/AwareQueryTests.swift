//
//  AwareQueryTests.swift
//  Aware
//
//  Tests for the chainable query builder.
//

import XCTest
@testable import Aware

final class AwareQueryTests: XCTestCase {

    // MARK: - Setup & Teardown

    private var testViewIds: [String] = []

    override func tearDown() async throws {
        // Clean up test views
        await MainActor.run {
            for id in testViewIds {
                Aware.shared.unregisterView(id)
            }
        }
        testViewIds.removeAll()
        try await super.tearDown()
    }

    private func makeTestId(_ suffix: String) -> String {
        let id = "query-test-\(suffix)-\(UUID().uuidString)"
        testViewIds.append(id)
        return id
    }

    // MARK: - State Filter Tests

    @MainActor
    func testQueryByState() async throws {
        // Given
        let viewId = makeTestId("state")
        Aware.shared.registerView(viewId, label: "State View")
        Aware.shared.registerState(viewId, key: "status", value: "active")

        // When
        let results = Aware.shared.query()
            .state("status", equals: "active")
            .all()

        // Then
        XCTAssertTrue(results.contains(where: { $0.id == viewId }))
    }

    @MainActor
    func testQueryHasState() async throws {
        // Given
        let viewId1 = makeTestId("has-state-1")
        let viewId2 = makeTestId("has-state-2")
        Aware.shared.registerView(viewId1, label: "With State")
        Aware.shared.registerView(viewId2, label: "Without State")
        Aware.shared.registerState(viewId1, key: "count", value: "5")

        // When
        let results = Aware.shared.query()
            .hasState("count")
            .all()

        // Then
        XCTAssertTrue(results.contains(where: { $0.id == viewId1 }))
        XCTAssertFalse(results.contains(where: { $0.id == viewId2 }))
    }

    // MARK: - Label Filter Tests

    @MainActor
    func testQueryLabelContains() async throws {
        // Given
        let buttonId = makeTestId("button")
        let textId = makeTestId("text")
        Aware.shared.registerView(buttonId, label: "Save Button")
        Aware.shared.registerView(textId, label: "Title Text")

        // When
        let buttonResults = Aware.shared.query().labelContains("button").all()
        let titleResults = Aware.shared.query().labelContains("title").all()

        // Then
        XCTAssertTrue(buttonResults.contains(where: { $0.id == buttonId }))
        XCTAssertFalse(buttonResults.contains(where: { $0.id == textId }))
        XCTAssertTrue(titleResults.contains(where: { $0.id == textId }))
    }

    @MainActor
    func testQueryExactLabel() async throws {
        // Given
        let viewId = makeTestId("exact")
        Aware.shared.registerView(viewId, label: "Exact Match")

        // When
        let exactResults = Aware.shared.query().label("Exact Match").all()
        let partialResults = Aware.shared.query().label("Exact").all()

        // Then
        XCTAssertTrue(exactResults.contains(where: { $0.id == viewId }))
        XCTAssertFalse(partialResults.contains(where: { $0.id == viewId }))
    }

    // MARK: - Chaining Tests

    @MainActor
    func testQueryChaining() async throws {
        // Given
        let viewId1 = makeTestId("chain-1")
        let viewId2 = makeTestId("chain-2")
        Aware.shared.registerView(viewId1, label: "Active Button")
        Aware.shared.registerView(viewId2, label: "Inactive Button")
        Aware.shared.registerState(viewId1, key: "enabled", value: "true")
        Aware.shared.registerState(viewId2, key: "enabled", value: "false")

        // When: Chain multiple filters
        let results = Aware.shared.query()
            .labelContains("Button")
            .state("enabled", equals: "true")
            .all()

        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertTrue(results.contains(where: { $0.id == viewId1 }))
    }

    // MARK: - Result Methods Tests

    @MainActor
    func testQueryFirst() async throws {
        // Given
        let viewId = makeTestId("first")
        Aware.shared.registerView(viewId, label: "First Test")

        // When
        let first = Aware.shared.query().label("First Test").first()

        // Then
        XCTAssertNotNil(first)
        XCTAssertEqual(first?.id, viewId)
    }

    @MainActor
    func testQueryFirstEmpty() async throws {
        // When: Query for non-existent view
        let first = Aware.shared.query().label("NonExistent-\(UUID())").first()

        // Then
        XCTAssertNil(first)
    }

    @MainActor
    func testQueryCount() async throws {
        // Given
        let viewId1 = makeTestId("count-1")
        let viewId2 = makeTestId("count-2")
        let viewId3 = makeTestId("count-3")
        Aware.shared.registerView(viewId1, label: "Count Item")
        Aware.shared.registerView(viewId2, label: "Count Item")
        Aware.shared.registerView(viewId3, label: "Other Item")

        // When
        let count = Aware.shared.query().labelContains("Count").count

        // Then
        XCTAssertEqual(count, 2)
    }

    @MainActor
    func testQueryExists() async throws {
        // Given
        let viewId = makeTestId("exists")
        Aware.shared.registerView(viewId, label: "Exists Test")

        // When
        let exists = Aware.shared.query().label("Exists Test").exists
        let notExists = Aware.shared.query().label("NoExists-\(UUID())").exists

        // Then
        XCTAssertTrue(exists)
        XCTAssertFalse(notExists)
    }

    @MainActor
    func testQueryIds() async throws {
        // Given
        let viewId1 = makeTestId("ids-1")
        let viewId2 = makeTestId("ids-2")
        Aware.shared.registerView(viewId1, label: "IDs Test")
        Aware.shared.registerView(viewId2, label: "IDs Test")

        // When
        let ids = Aware.shared.query().label("IDs Test").ids

        // Then
        XCTAssertEqual(ids.count, 2)
        XCTAssertTrue(ids.contains(viewId1))
        XCTAssertTrue(ids.contains(viewId2))
    }

    // MARK: - Custom Predicate Test

    @MainActor
    func testQueryWherePredicate() async throws {
        // Given
        let viewId = makeTestId("predicate")
        Aware.shared.registerView(viewId, label: "Predicate Test")
        Aware.shared.registerState(viewId, key: "value", value: "42")

        // When: Use custom predicate
        let results = Aware.shared.query()
            .where { $0.id.contains("predicate") }
            .all()

        // Then
        XCTAssertTrue(results.contains(where: { $0.id == viewId }))
    }
}
