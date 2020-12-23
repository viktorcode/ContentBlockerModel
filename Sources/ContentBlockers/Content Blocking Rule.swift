// Source: https://developer.apple.com/documentation/safariservices/creating_a_content_blocker

import Foundation

public let optimisingDomainPrefix = "^[^:]+://+([^:/]+\\.)?"
public let optimisingDomainSuffix = "[:/]"

public struct ContentBlockingRule : Equatable, Hashable {
    public var trigger: Trigger
    public var action: Action

    public init(trigger: Trigger, action: Action) {
        self.trigger = trigger
        self.action = action
    }
}

/// When to trigger the rule
public struct Trigger : Equatable, Hashable {
    public var urlFilter: String

    /// A Boolean value. The default value is false.
    public var urlFilterIsCaseSensitive: Bool?

    /// An array of strings representing the resource types (how the browser intends to use the resource) that the rule should match. If not specified, the rule matches all resource types. Valid values: document, image, style-sheet, script, font, raw (Any untyped load), svg-document, media, popup
    public var resourceType: [ResourceType]?

    /// An array of strings that can include one of two mutually exclusive values. If not specified, the rule matches all load types. first-party is triggered only if the resource has the same scheme, domain, and port as the main page resource. third-party is triggered if the resource is not from the same domain as the main page resource.
    public var loadType: [LoadType]?
    public var urlSelection: URLSelection?

    public init(urlFilter: String, urlFilterIsCaseSensitive: Bool? = nil,
                resourceType: [ResourceType]? = nil, loadType: [LoadType]? = nil,
                urlSelection: URLSelection? = nil) {
        self.urlFilter = urlFilter
        self.urlFilterIsCaseSensitive = urlFilterIsCaseSensitive
        self.resourceType = resourceType
        self.loadType = loadType
        self.urlSelection = urlSelection
    }
}

/// The action applied to the website content
public struct Action : Equatable, Hashable {
    public var type: ActionType
    
    /// Specifies a comma-separated selector list. This value is required when the action type is css-display-none. If it's not, the selector field is ignored by Safari.
    public var selector: String?

    public init(type: ActionType, selector: String? = nil) {
        self.type = type
        self.selector = selector
    }
}

/// Action that will be applied when the corresponding trigger is activated
///
/// - `block`: Stops loading of the resource. If the resource was cached, the cache is ignored.
/// - `blockCookies`: Strips cookies from the header before sending to the server. Only cookies otherwise acceptable to Safari's privacy policy can be blocked. Combining with ignore-previous-rules doesn't override the browser’s privacy settings.
/// - `cssDisplayNone`: Hides elements of the page based on a CSS selector. A selector field contains the selector list. Any matching element has its display property set to none, which hides it.
/// - `ignorePreviousRules`: Ignores previously triggered actions.
/// - `makeHTTPS`: Changes a URL from http to https. URLs with a specified (nondefault) port and links using other protocols are unaffected.
public enum ActionType : String {
	case block
	case blockCookies = "block-cookies"
	case cssDisplayNone = "css-display-none"
	case ignorePreviousRules = "ignore-previous-rules"
	case makeHTTPS = "make-https"
}

public enum ResourceType : String {
	case document
	case image
	case styleSheet = "style-sheet"
	case script
	case font
	case raw
	case svgDocument = "svg-document"
	case media
	case popup
}

public enum LoadType : String {
	case firstParty = "first-party"
	case thirdParty = "third-party"
}

/// Limits the scope of the trigger
///
/// - `ifDomain`: An array of strings matched to a URL's domain; limits action to a list of specific domains. Values must be lowercase ASCII, or punycode for non-ASCII. Add * in front to match domain and subdomains. Can't be used with unless-domain.
/// - `unlessDomain`: An array of strings matched to a URL's domain; acts on any site except domains in a provided list. Values must be lowercase ASCII, or punycode for non-ASCII. Add * in front to match domain and subdomains. Can't be used with if-domain.
/// - `ifTopURL`: An array of strings matched to the entire main document URL; limits the action to a specific list of URL patterns. Values must be lowercase ASCII, or punycode for non-ASCII. Can't be used with unless-top-url.
/// - `unlessTopURL`: An array of strings matched to the entire main document URL; acts on any site except URL patterns in provided list. Values must be lowercase ASCII, or punycode for non-ASCII. Can't be used with if-top-url.
public enum URLSelection : Equatable, Hashable {
    case ifDomain([String])
	case unlessDomain([String])
	case ifTopURL([String])
	case unlessTopURL([String])
}


// MARK: - Comparable conformance
// This is needed to automatically sort list of rules for performance and correctness

// I wish I could make these fileprivate... comparisons aren't universal, don't reuse for other cases
// For content blocking rules this will put less specific ones ahead (ascending order)
// ---
extension Optional : Comparable where Wrapped: Comparable {
    public static func < (lhs: Optional<Wrapped>, rhs: Optional<Wrapped>) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none): return false
        case (.none, .some(_)): return true
        case (.some(_), .none): return false
        case (.some(let left), .some(let right)): return left < right
        }
    }
}

extension Array : Comparable where Element: Comparable {
    public static func < (lhs: Array<Element>, rhs: Array<Element>) -> Bool {
        let last = Swift.min(lhs.count, rhs.count)
        for index in 0..<last {
            if lhs[index] != rhs[index] { return lhs[index] < rhs[index] }
        }
        return lhs.count < rhs.count
    }
}

extension Bool : Comparable {
    public static func < (lhs: Bool, rhs: Bool) -> Bool {
        switch (lhs, rhs) {
        case (false, true): return true
        case (_, _): return false
        }
    }
}
// ---

// Group the rules with similar actions together to improve performance -- Apple
extension ContentBlockingRule : Comparable {
    public static func < (lhs: ContentBlockingRule, rhs: ContentBlockingRule) -> Bool {
        if lhs.action != rhs.action { return lhs.action < rhs.action }
        return lhs.trigger < rhs.trigger
    }
}

extension Action : Comparable {
    public static func < (lhs: Action, rhs: Action) -> Bool {
        if lhs.type != rhs.type { return lhs.type < rhs.type }
        return lhs.selector < rhs.selector
    }
}

extension ActionType : Comparable {
    public static func < (lhs: ActionType, rhs: ActionType) -> Bool {
        guard lhs != rhs else { return false }
        switch rhs {
        case .ignorePreviousRules: return true
        default: // alphabetic sorting for everything else
            return lhs.rawValue < rhs.rawValue
        }
    }
}

extension Trigger : Comparable {
    public static func < (lhs: Trigger, rhs: Trigger) -> Bool {
        if lhs.urlFilter != rhs.urlFilter { return lhs.urlFilter < rhs.urlFilter }
        if lhs.loadType != rhs.loadType { return lhs.loadType < rhs.loadType }
        if lhs.urlSelection != rhs.urlSelection { return lhs.urlSelection < rhs.urlSelection }
        if lhs.resourceType != rhs.resourceType { return lhs.resourceType < rhs.resourceType }
        return lhs.urlFilterIsCaseSensitive < rhs.urlFilterIsCaseSensitive
    }
}

extension URLSelection : Comparable {
    public static func < (lhs: URLSelection, rhs: URLSelection) -> Bool {
        switch (lhs, rhs) {
        case (.unlessDomain(let left), .unlessDomain(let right)): return left < right
        case (.ifDomain(let left), .ifDomain(let right)): return left < right
        case (.unlessTopURL(let left), .unlessTopURL(let right)): return left < right
        case (.ifTopURL(let left), .ifTopURL(let right)): return left < right
        case (.unlessDomain, _): return true
        case (_, .unlessDomain): return false
        case (.ifDomain, _): return true
        case (_, .ifDomain): return false
        case (.unlessTopURL, _): return true
        default: return false
        }
    }
}

extension ResourceType : Comparable {
    public static func < (lhs: ResourceType, rhs: ResourceType) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

extension LoadType : Comparable {
    public static func < (lhs: LoadType, rhs: LoadType) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Codable Conformance
extension ContentBlockingRule : Codable { }
extension Action : Codable { }
extension ActionType : Codable { }
extension ResourceType : Codable { }
extension LoadType : Codable { }

extension Trigger : Codable {
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		urlFilter = try container.decode(String.self, forKey: .urlFilter)
		urlFilterIsCaseSensitive = try container.decodeIfPresent(Bool.self, forKey: .urlFilterIsCaseSensitive)
		resourceType = try container.decodeIfPresent([ResourceType].self, forKey: .resourceType)
		loadType = try container.decodeIfPresent([LoadType].self, forKey: .loadType)
		let selectionContainer = try decoder.container(keyedBy: UrlSelectionKeys.self)
		if selectionContainer.contains(.ifDomain) {
			if let array = try selectionContainer.decode([String]?.self, forKey: .ifDomain) {
				urlSelection = URLSelection.ifDomain(array)
			}
		} else if selectionContainer.contains(.unlessDomain) {
			if let array = try selectionContainer.decode([String]?.self, forKey: .unlessDomain) {
				urlSelection = URLSelection.unlessDomain(array)
			}
		} else if selectionContainer.contains(.ifTopURL) {
			if let array = try selectionContainer.decode([String]?.self, forKey: .ifTopURL) {
				urlSelection = URLSelection.ifTopURL(array)
			}
		} else if selectionContainer.contains(.unlessTopURL) {
			if let array = try selectionContainer.decode([String]?.self, forKey: .unlessTopURL) {
				urlSelection = URLSelection.unlessTopURL(array)
			}
		}
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(urlFilter, forKey: .urlFilter)
		try container.encodeIfPresent(urlFilterIsCaseSensitive, forKey: .urlFilterIsCaseSensitive)
		try container.encodeIfPresent(resourceType, forKey: .resourceType)
		try container.encodeIfPresent(loadType, forKey: .loadType)
		if let selection = urlSelection {
			var selectionContainer = encoder.container(keyedBy: UrlSelectionKeys.self)
			switch selection {
			case .ifTopURL(let selection):
				try selectionContainer.encode(selection, forKey: .ifTopURL)
			case .unlessTopURL(let selection):
				try selectionContainer.encode(selection, forKey: .unlessTopURL)
			case .ifDomain(let selection):
				try selectionContainer.encode(selection, forKey: .ifDomain)
			case .unlessDomain(let selection):
				try selectionContainer.encode(selection, forKey: .unlessDomain)
			}
		}
	}

	private enum CodingKeys: String, CodingKey {
		case urlFilter = "url-filter"
		case urlFilterIsCaseSensitive = "url-filter-is-case-sensitive"
		case resourceType = "resource-type"
		case loadType = "load-type"
	}

	private enum UrlSelectionKeys: String, CodingKey {
		case ifDomain = "if-domain"
		case unlessDomain = "unless-domain"
		case ifTopURL = "if-top-url"
		case unlessTopURL = "unless-top-url"
	}
}
