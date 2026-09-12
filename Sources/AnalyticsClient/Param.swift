import Foundation

extension AnalyticsClient {
    /// Typed parameter value for analytics events. Widens `[String: String]` so numeric
    /// metrics (revenue, durations, counts) keep their native type for Firebase aggregation.
    /// Conforms to `ExpressibleByStringLiteral` / `…IntegerLiteral` / `…FloatLiteral` /
    /// `…BooleanLiteral` so call sites stay ergonomic:
    ///
    /// ```swift
    /// await analyticsClient.trackEvent("purchase", [
    ///     "product_id": "pro.yearly",   // string literal
    ///     "price": 29.99,               // float literal
    ///     "count": 1,                   // int literal
    ///     "gifted": false,              // bool literal
    /// ])
    /// ```
    ///
    /// Named `Param` rather than `Value` because TCA's `TestDependencyKey` protocol
    /// declares an `associatedtype Value = Self` that collides with any nested
    /// `AnalyticsClient.Value` at name-lookup time.
    public enum Param: Sendable, Equatable {
        /// The `stringValue` fallback when the line-items can't be serialised.
        private static let emptyItemsJSON = "[]"

        case string(String)
        case int(Int)
        case double(Double)
        case bool(Bool)
        /// The GA4 `items` array — the product line-items that ride along on `purchase`.
        /// The only non-scalar case, hence the only one with no literal form.
        case items([[String: String]])

        /// The underlying Foundation value suitable for `Analytics.logEvent(_:parameters:)`.
        public var anyValue: Any {
            switch self {
                case .string(let s): return s
                case .int(let i): return i
                case .double(let d): return d
                case .bool(let b): return b
                case .items(let items): return items
            }
        }

        /// A lossless string form — used by analytics backends that accept only strings,
        /// and by `Crashlytics.record(error:userInfo:)` which takes `[String: Any]`.
        /// Line-items render as JSON with sorted keys so the form is stable.
        public var stringValue: String {
            switch self {
                case .string(let s): return s
                case .int(let i): return String(i)
                case .double(let d): return String(d)
                case .bool(let b): return String(b)
                case .items(let items): return Self.json(items)
            }
        }

        private static func json(_ items: [[String: String]]) -> String {
            guard
                let encoded = try? JSONSerialization.data(withJSONObject: items, options: [.sortedKeys]),
                let text = String(data: encoded, encoding: .utf8)
            else {
                return emptyItemsJSON
            }
            return text
        }
    }

    /// Convenience alias for the common analytics-params dictionary shape.
    /// Callers that want `[String: AnalyticsClient.Param]` can write `AnalyticsClient.Params` instead.
    public typealias Params = [String: Param]
}

extension AnalyticsClient.Param: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) { self = .string(value) }
}

extension AnalyticsClient.Param: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) { self = .int(value) }
}

extension AnalyticsClient.Param: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) { self = .double(value) }
}

extension AnalyticsClient.Param: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) { self = .bool(value) }
}
