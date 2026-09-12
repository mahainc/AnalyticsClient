import DependenciesMacros

/// A generic analytics + crash-reporting façade.
///
/// The interface is intentionally free of app-specific `Screen` / `Event` *values* —
/// consumer apps declare their own tokens and call `trackScreen(name:params:)` with raw
/// strings. The package does ship a generic, extensible `AnalyticsClient.Screen` token
/// *type* (apps add their own values via an extension); it hardcodes no screens itself.
/// Params use the typed `AnalyticsClient.Param` so numeric metrics aren't forced to strings.
@DependencyClient
public struct AnalyticsClient: Sendable {
    /// One-shot bootstrap: applies `collectionEnabled`, then `userID` (if
    /// non-nil), then each entry of `userProperties`. Idempotent — Firebase
    /// persists `collectionEnabled` and user IDs across launches, so calling
    /// twice with the same `AnalyticsConfig` is a no-op.
    public var initialize: @Sendable (_ config: AnalyticsConfig) async -> Void
    public var trackScreen: @Sendable (_ name: String, _ params: [String: Param]) async -> Void
    public var trackEvent: @Sendable (_ name: String, _ params: [String: Param]) async -> Void
    public var setUserID: @Sendable (_ id: String?) async -> Void
    /// Sets a Firebase Analytics user property. Pass `nil` to clear the
    /// property. Property names must be ≤ 24 chars, alphanumeric +
    /// underscore; keep to Firebase's 25-properties-per-app cap.
    public var setUserProperty: @Sendable (_ value: String?, _ name: String) async -> Void = { _, _ in }
    /// Toggles `Analytics.setAnalyticsCollectionEnabled(_:)` at runtime. Call
    /// with `false` on UMP decline / ATT denial; `true` to re-enable. Firebase
    /// persists the setting across launches, so this is idempotent.
    public var setAnalyticsCollectionEnabled: @Sendable (_ enabled: Bool) async -> Void = { _ in }
    /// The analytics SDK's current session identifier — the value Firebase stamps onto
    /// every event as `ga_session_id`. `nil` until the SDK has opened a session, and on
    /// any backend that has no notion of one. Async because the SDK resolves it off the
    /// calling thread.
    public var currentSessionID: @Sendable () async -> Int64? = { nil }
    public var log: @Sendable (_ message: String) async -> Void
    public var recordError: @Sendable (_ error: any Error & Sendable, _ userInfo: [String: Param]?) async -> Void
}
