/// Bootstrap-time configuration for `AnalyticsClient.initialize(_:)`.
///
/// Firebase auto-initialises on first SDK call once `FirebaseApp.configure()`
/// has run in the app delegate, so this struct is *not* about turning Firebase
/// on — it's a one-shot way to apply the runtime knobs (`collectionEnabled`,
/// `userID`, initial user properties) at a known point in the bootstrap
/// sequence instead of scattering the setters across the app.
public struct AnalyticsConfig: Sendable, Equatable {
    /// Forwarded to `Analytics.setAnalyticsCollectionEnabled(_:)`. Firebase
    /// persists this across launches, so the value at first init is sticky
    /// until explicitly toggled (e.g. on UMP decline / re-consent).
    public var collectionEnabled: Bool
    /// Optional initial user ID. When non-nil, sets both Firebase Analytics
    /// and Crashlytics user IDs; pass `nil` to leave the existing ID alone
    /// (use `analyticsClient.setUserID(nil)` later to clear).
    public var userID: String?
    /// Initial user properties applied via `Analytics.setUserProperty(_:forName:)`.
    /// Keys must be ≤ 24 chars, alphanumeric + underscore; Firebase caps at
    /// 25 properties per app.
    public var userProperties: [String: String]

    public init(
        collectionEnabled: Bool = true,
        userID: String? = nil,
        userProperties: [String: String] = [:]
    ) {
        self.collectionEnabled = collectionEnabled
        self.userID = userID
        self.userProperties = userProperties
    }
}
