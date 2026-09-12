import Dependencies

extension DependencyValues {
    public var analyticsClient: AnalyticsClient {
        get { self[AnalyticsClient.self] }
        set { self[AnalyticsClient.self] = newValue }
    }
}

extension AnalyticsClient: TestDependencyKey {
    public static var testValue: Self { Self() }
    public static var previewValue: Self { Self() }
}

extension AnalyticsClient {
    /// No-op mock — all calls succeed silently. Useful when a test doesn't care about analytics.
    public static let noop: Self = .init(
        initialize: { _ in },
        trackScreen: { _, _ in },
        trackEvent: { _, _ in },
        setUserID: { _ in },
        setUserProperty: { _, _ in },
        setAnalyticsCollectionEnabled: { _ in },
        currentSessionID: { nil },
        log: { _ in },
        recordError: { _, _ in }
    )
}
