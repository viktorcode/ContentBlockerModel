import XCTest
@testable import ContentBlockers

final class ContentBlockersTests: XCTestCase {
    let escapedOptimisingDomainPrefix = "^[^:]+:\\/\\/+([^:\\/]+\\\\.)?"
    let blockRule = ContentBlockingRule(
        trigger: Trigger(urlFilter: optimisingDomainPrefix + "trc\\.taboola\\.com",
            urlFilterIsCaseSensitive: true,
            loadType: [.thirdParty]),
        action: Action(type: .block))



    func testSanity() {
        let rule = ContentBlockingRule(
            trigger: Trigger(urlFilter: "*."),
            action: Action(type: .block))

        let another = ContentBlockingRule(
            trigger: Trigger(urlFilter: "*."),
            action: Action(type: .block))

        XCTAssertEqual(rule, another)
    }

    func testShouldSerialize() {
        let json = JSONEncoder()
        XCTAssertNoThrow(try json.encode(blockRule))
        let string = String(data: try! json.encode(blockRule), encoding: .utf8)!
        XCTAssertTrue(string.contains(escapedOptimisingDomainPrefix))
    }

    static var allTests = [
        ("Test Sanity", testSanity),
        ("Should Serialise", testShouldSerialize)
    ]
}
