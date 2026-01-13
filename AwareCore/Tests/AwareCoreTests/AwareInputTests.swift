//
//  AwareInputTests.swift
//  Aware
//
//  Tests for input simulation utilities.
//  Note: Actual event posting requires accessibility permissions.
//

import XCTest
@testable import Aware

#if os(macOS)
final class AwareInputTests: XCTestCase {

    // MARK: - Keyboard Key Code Mapping Tests

    @MainActor
    func testKeyCodeForLowercaseLetters() async throws {
        // Test lowercase letters map correctly
        let lowercaseA = AwareKeyboardInput.keyCodeForCharacter("a")
        let lowercaseZ = AwareKeyboardInput.keyCodeForCharacter("z")

        XCTAssertNotNil(lowercaseA, "Should have key code for 'a'")
        XCTAssertNotNil(lowercaseZ, "Should have key code for 'z'")

        // Lowercase should not need shift
        XCTAssertEqual(lowercaseA?.1, false, "Lowercase 'a' should not need shift")
        XCTAssertEqual(lowercaseZ?.1, false, "Lowercase 'z' should not need shift")
    }

    @MainActor
    func testKeyCodeForUppercaseLetters() async throws {
        // Test uppercase letters need shift
        let uppercaseA = AwareKeyboardInput.keyCodeForCharacter("A")
        let uppercaseZ = AwareKeyboardInput.keyCodeForCharacter("Z")

        XCTAssertNotNil(uppercaseA, "Should have key code for 'A'")
        XCTAssertNotNil(uppercaseZ, "Should have key code for 'Z'")

        // Uppercase should need shift
        XCTAssertEqual(uppercaseA?.1, true, "Uppercase 'A' should need shift")
        XCTAssertEqual(uppercaseZ?.1, true, "Uppercase 'Z' should need shift")

        // Same key code as lowercase
        let lowercaseA = AwareKeyboardInput.keyCodeForCharacter("a")
        XCTAssertEqual(uppercaseA?.0, lowercaseA?.0, "'A' and 'a' should have same key code")
    }

    @MainActor
    func testKeyCodeForNumbers() async throws {
        // Test number keys
        for num in 0...9 {
            let char = Character("\(num)")
            let result = AwareKeyboardInput.keyCodeForCharacter(char)
            XCTAssertNotNil(result, "Should have key code for '\(num)'")
            XCTAssertEqual(result?.1, false, "Number '\(num)' should not need shift")
        }
    }

    @MainActor
    func testKeyCodeForSpecialCharacters() async throws {
        // Test special characters that need shift
        let bang = AwareKeyboardInput.keyCodeForCharacter("!")
        let at = AwareKeyboardInput.keyCodeForCharacter("@")
        let hash = AwareKeyboardInput.keyCodeForCharacter("#")

        XCTAssertNotNil(bang, "Should have key code for '!'")
        XCTAssertNotNil(at, "Should have key code for '@'")
        XCTAssertNotNil(hash, "Should have key code for '#'")

        // Special chars should need shift
        XCTAssertEqual(bang?.1, true, "'!' should need shift")
        XCTAssertEqual(at?.1, true, "'@' should need shift")
        XCTAssertEqual(hash?.1, true, "'#' should need shift")
    }

    @MainActor
    func testKeyCodeForSpace() async throws {
        let space = AwareKeyboardInput.keyCodeForCharacter(" ")
        XCTAssertNotNil(space, "Should have key code for space")
        XCTAssertEqual(space?.1, false, "Space should not need shift")
    }

    @MainActor
    func testKeyCodeForReturn() async throws {
        let returnKey = AwareKeyboardInput.keyCodeForCharacter("\n")
        XCTAssertNotNil(returnKey, "Should have key code for return")
        XCTAssertEqual(returnKey?.1, false, "Return should not need shift")
    }

    @MainActor
    func testKeyCodeForTab() async throws {
        let tab = AwareKeyboardInput.keyCodeForCharacter("\t")
        XCTAssertNotNil(tab, "Should have key code for tab")
        XCTAssertEqual(tab?.1, false, "Tab should not need shift")
    }

    // MARK: - Unicode Input Tests

    @MainActor
    func testUnicodeKeyEventsForAccentedChar() async throws {
        // Unicode events should be created for characters not in key map
        let accent = Character("é")
        let events = AwareKeyboardInput.createUnicodeKeyEvents(for: accent)

        // Should create key down and key up events
        XCTAssertEqual(events.count, 2, "Should create 2 events (down + up)")
    }

    @MainActor
    func testUnicodeKeyEventsForCurrencySymbol() async throws {
        // Test another BMP character (Basic Multilingual Plane)
        let euro = Character("€")
        let events = AwareKeyboardInput.createUnicodeKeyEvents(for: euro)

        XCTAssertEqual(events.count, 2, "Should create 2 events for currency symbol")
    }
}
#endif
