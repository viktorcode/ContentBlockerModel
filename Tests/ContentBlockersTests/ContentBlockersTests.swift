import XCTest
@testable import ContentBlockers

final class ContentBlockersTests: XCTestCase {

    func testEquality() {
        let rule = ContentBlockingRule(
            trigger: Trigger(urlFilter: "*.", urlFilterIsCaseSensitive: true,
                             resourceType: [.document, .image, .script],
                             loadType: [.firstParty], urlSelection: .ifDomain(["*doma.in"])),
            action: Action(type: .block))

        let another = ContentBlockingRule(
            trigger: Trigger(urlFilter: "*.", urlFilterIsCaseSensitive: true,
                             resourceType: [.document, .image, .script],
                             loadType: [.firstParty], urlSelection: .ifDomain(["*doma.in"])),
            action: Action(type: .block))

        XCTAssertEqual(rule, another)
    }

    func testSerialization() {
        let escapedOptimisingDomainPrefix = #"^[^:]+:\/\/+([^:\/]+\\.)?"#
        let blockRule = ContentBlockingRule(
            trigger: Trigger(urlFilter: optimisingDomainPrefix + #"trc\.taboola\.com"#,
                             urlFilterIsCaseSensitive: true,
                             loadType: [.thirdParty]),
            action: Action(type: .block))

        let json = JSONEncoder()
        XCTAssertNoThrow(try json.encode(blockRule))
        let string = String(data: try! json.encode(blockRule), encoding: .utf8)!
        XCTAssertTrue(string.contains(escapedOptimisingDomainPrefix))
    }

    func testDeserialization() {
        let jsonData = #"""
        {
          "trigger" : {
            "url-filter" : "^[^:]+:\/\/+([^:\/]+\\.)?trc\\.taboola\\.com",
            "url-filter-is-case-sensitive" : true,
            "load-type" : [
              "third-party"
            ]
          },
          "action" : {
            "type" : "block"
          }
        }
        """#
        let json = JSONDecoder()
        let data = jsonData.data(using: .utf8)!
        XCTAssertNoThrow(try json.decode(ContentBlockingRule.self, from: data))
    }

    func testOrdering() {
        let blockRule1 = ContentBlockingRule(
            trigger: Trigger(urlFilter: optimisingDomainPrefix + #"trc\.taboola\.com"#,
                             urlFilterIsCaseSensitive: true,
                             loadType: [.thirdParty]),
            action: Action(type: .block))
        let blockRule2 = ContentBlockingRule(
            trigger: Trigger(urlFilter: optimisingDomainPrefix + #"trc\.taboola\.com"#,
                             loadType: [.thirdParty]),
            action: Action(type: .block))
        let hidingRule = ContentBlockingRule(
            trigger: Trigger(urlFilter: "*."),
            action: Action(type: .cssDisplayNone, selector: ".big-fat-ad"))
        let exceptionRule = ContentBlockingRule(
            trigger: Trigger(urlFilter: "*important.com"),
            action: Action(type: .ignorePreviousRules))

        var list = [exceptionRule, blockRule1, hidingRule, blockRule2]
        list.sort()
        XCTAssertEqual(list.last!, exceptionRule, "Exception must go last")
        XCTAssertEqual(list.first!, blockRule2, "Less specific ahead of more specific")
        XCTAssertEqual(list[2], hidingRule, "Hiding goes lower priority")
    }

    static var allTests = [
        ("Should be equal", testEquality),
        ("Should serialise", testSerialization),
        ("Should deserialize", testDeserialization)
    ]
}
