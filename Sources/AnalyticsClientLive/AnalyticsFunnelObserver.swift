import AnalyticsClient
import FunnelClient

/// Inbound bridge: relays every event Firebase logs into the funnel engine.
///
/// The sink is called synchronously, on whatever thread saw the event — no `Task` hop. A
/// `screen_view` has to update the engine's screen context *before* the next event is
/// stamped with it, and a hop would let a fast follower carry the stale screen. That
/// requirement is why the port is a sink registration rather than an `AsyncStream`.
///
/// The relay deliberately does not go through `AnalyticsClient.trackEvent`: the params on
/// this path are precisely the reserved-prefix keys (`ga_session_id`, `firebase_screen`…)
/// the live client warns about, because Firebase drops those on the way *out*. On the way
/// *in* they are the payload the engine needs.
public final class AnalyticsFunnelObserver: FunnelClient.Analytics.Observing {
    public init() {}

    public func startObserving(_ sink: @escaping @Sendable (FunnelClient.Analytics.ObservedEvent) -> Void) {
        LogEventInterceptor.install { name, params in
            sink(FunnelClient.Analytics.ObservedEvent(name: name, parameters: Self.values(params)))
        }
    }

    /// Case order — String, Int, Double, Bool, items — is the contract, not a style choice.
    /// An ObjC dictionary boxes `Bool` as `NSNumber` and that bridge is lenient:
    /// `NSNumber(value: 1) as? Bool` is `true`, so testing `Bool` first would retype every
    /// 0/1 integer parameter as a boolean and change what the engine has always received.
    private static func values(_ params: [String: Any]) -> [String: FunnelClient.Analytics.Value] {
        var out: [String: FunnelClient.Analytics.Value] = [:]
        out.reserveCapacity(params.count)
        for (key, value) in params {
            switch value {
                case let x as String: out[key] = .string(x)
                case let x as Int: out[key] = .int(x)
                case let x as Double: out[key] = .double(x)
                case let x as Bool: out[key] = .bool(x)
                case let x as [[String: String]]: out[key] = .items(x)
                default: continue
            }
        }
        return out
    }
}
