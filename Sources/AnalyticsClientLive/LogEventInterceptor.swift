import AnalyticsClient
import Foundation
import OSLog
import ObjectiveC.runtime

/// Swizzles the single chokepoint every Firebase Analytics event passes through, so a
/// consumer can observe events this façade never emitted — the SDK's own, and any logged
/// by another module. `APMAnalytics` is resolved by string through the ObjC runtime, so
/// this file links without importing FirebaseAnalytics.
enum LogEventInterceptor {
    typealias Forward = (_ name: String, _ params: [String: Any]) -> Void

    private static let className = "APMAnalytics"
    private static let selectorName = "logEventWithOrigin:isPublicEvent:name:parameters:"
    /// Firebase prefixes its internal events with `_`; `_ai` is the one worth relaying.
    private static let internalPrefix = "_"
    private static let relayedInternalName = "_ai"
    private static let droppedNames: Set<String> = ["_err", "_dbg", "_ssr", "_cmp", "_e", "_iap"]

    nonisolated(unsafe) private static var forward: Forward?
    nonisolated(unsafe) private static var installed = false

    /// Re-pointing `forward` on a later call is deliberate: the swizzle itself is a
    /// process-wide, one-shot mutation of the ObjC method table.
    static func install(_ forward: @escaping Forward) {
        self.forward = forward
        guard !installed else { return }
        installed = true

        guard let cls = NSClassFromString(className) else {
            Logger.analyticsClient.error(
                "LogEventInterceptor no-op: \(className, privacy: .public) not linked — the observer will receive ZERO events"
            )
            return
        }
        let sel = NSSelectorFromString(selectorName)
        guard let original = class_getClassMethod(cls, sel) else {
            Logger.analyticsClient.error(
                "LogEventInterceptor no-op: \(className, privacy: .public) missing selector \(selectorName, privacy: .public)"
            )
            return
        }

        typealias LogEventIMP = @convention(c) (AnyClass, Selector, NSString, ObjCBool, NSString, NSDictionary?) -> Void
        let originalIMP = unsafeBitCast(method_getImplementation(original), to: LogEventIMP.self)

        let block: @convention(block) (AnyClass, NSString, ObjCBool, NSString, NSDictionary?) -> Void = {
            cls,
            origin,
            isPublic,
            name,
            params in
            originalIMP(cls, sel, origin, isPublic, name, params)
            let eventName = name as String
            guard isRelayed(eventName) else {
                Logger.analyticsClient.debug(
                    "intercept pre-filter drop name=\(eventName, privacy: .public) origin=\(origin as String, privacy: .public)"
                )
                return
            }
            let dict = (params as? [String: Any]) ?? [:]
            Logger.analyticsClient.debug(
                "intercept forward name=\(eventName, privacy: .public) origin=\(origin as String, privacy: .public) params=\(dict.keys.sorted().joined(separator: ","), privacy: .public)"
            )
            LogEventInterceptor.forward?(eventName, dict)
        }
        method_setImplementation(original, imp_implementationWithBlock(block))
        Logger.analyticsClient.info(
            "LogEventInterceptor installed — swizzled \(className, privacy: .public) event chokepoint"
        )
    }

    /// Mirrors FunnelClient's interceptor verbatim. `droppedNames` is already covered by
    /// the prefix rule; it is kept so the two filters stay comparable line for line and so
    /// loosening the prefix rule can't silently re-admit the diagnostics events.
    private static func isRelayed(_ name: String) -> Bool {
        if droppedNames.contains(name) { return false }
        if name.hasPrefix(internalPrefix) { return name == relayedInternalName }
        return true
    }
}
