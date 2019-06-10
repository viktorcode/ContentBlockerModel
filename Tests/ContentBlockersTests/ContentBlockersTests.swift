import XCTest
@testable import ContentBlockers

final class ContentBlockersTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(ContentBlockers().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
