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
        XCTAssertTrue(string.contains(#"\\.taboola\\."#))
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
        let blockRule = ContentBlockingRule(
            trigger: Trigger(urlFilter: optimisingDomainPrefix + #"trc\.taboola\.com"#,
                             urlFilterIsCaseSensitive: true,
                             loadType: [.thirdParty]),
            action: Action(type: .block))
        XCTAssertNoThrow(try json.decode(ContentBlockingRule.self, from: data))
        let rule = try! json.decode(ContentBlockingRule.self, from: data)
        XCTAssertEqual(rule, blockRule)
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

    func testOverlapping() {
        let blockRule = ContentBlockingRule(
            trigger: Trigger(urlFilter: optimisingDomainPrefix + #"trc\.taboola\.com"#,
                             urlFilterIsCaseSensitive: true,
                             loadType: [.thirdParty]),
            action: Action(type: .block))
        let moreGenericBlockRule = ContentBlockingRule(
            trigger: Trigger(urlFilter: optimisingDomainPrefix + #"trc\.taboola\.com"#,
                             urlFilterIsCaseSensitive: true),
            action: Action(type: .block))
        let otherBlockRule = ContentBlockingRule(
            trigger: Trigger(urlFilter: optimisingDomainPrefix + #"trc\.taboola\.com"#,
                             urlFilterIsCaseSensitive: true,
                             resourceType: [.popup, .script]),
            action: Action(type: .block))

        XCTAssert(moreGenericBlockRule.isSuperset(of: blockRule), "Empty loadType is more generic")
        XCTAssert(!blockRule.isSuperset(of: moreGenericBlockRule), "Specific rule is 'smaller' than the generic one")
        XCTAssert(moreGenericBlockRule.isSuperset(of: otherBlockRule), "Empty resourceType is more generic")
        XCTAssert(!blockRule.isSuperset(of: otherBlockRule) && !otherBlockRule.isSuperset(of: blockRule),
                  "Specific rules are overlapping only partially")
    }

    static var allTests = [
        ("Should be equal", testEquality),
        ("Should serialise", testSerialization),
        ("Should deserialize", testDeserialization)
    ]
}
