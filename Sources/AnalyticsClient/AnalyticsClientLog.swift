import OSLog

extension Logger {
    /// Filter Console.app with `subsystem:com.mahainc.AnalyticsClient` to see every
    /// `trackEvent` / `setUserProperty` / `recordError` call that crossed this
    /// façade. Live emits `.info` for normal traffic (high-signal calls — .debug
    /// is volatile on iOS and won't show in `log show` without a `log config`
    /// override) and `.notice` when Firebase will silently drop a payload
    /// (reserved param prefix, etc.).
    public static let analyticsClient = Logger(subsystem: "com.mahainc.AnalyticsClient", category: "live")
}
