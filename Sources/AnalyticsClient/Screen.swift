import Foundation

extension AnalyticsClient {
    /// Typed, extensible screen/segment token for composing `/`-delimited
    /// `screen_path` breadcrumbs.
    ///
    /// The package ships only the generic *type* — it deliberately defines no
    /// app-specific screen *values*. Each consumer app declares its own tokens via
    /// an extension, following the `Notification.Name` / `NSAttributedString.Key`
    /// pattern so call sites stay typed yet the set is open across modules:
    ///
    /// ```swift
    /// // In the app:
    /// extension AnalyticsClient.Screen {
    ///     static let matches = Self("matches")
    ///     static let pickTeams = Self("pick_teams")
    /// }
    ///
    /// // Compose a path:
    /// AnalyticsClient.Screen.path(.matches, .web) // == "matches/web"
    /// ```
    ///
    /// Backed by a raw string so any value is representable, and
    /// `ExpressibleByStringLiteral` so ad-hoc segments (`"webgate"`) still pass
    /// where a `Screen` is expected.
    public struct Screen: Sendable, Equatable, Hashable, RawRepresentable {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }

        /// Joins tokens into a "/"-delimited path, e.g.
        /// `Screen.path(.matches, .web) == "matches/web"`.
        public static func path(_ segments: Screen...) -> String {
            segments.map(\.rawValue).joined(separator: "/")
        }
    }
}

extension AnalyticsClient.Screen: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .init(value)
    }
}
