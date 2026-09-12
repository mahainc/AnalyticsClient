import AnalyticsClient
import FunnelClient

/// Outbound bridge: the funnel engine's analytics sink, backed by `AnalyticsClient`.
///
/// The port's `logEvent` / `setUserProperty` are synchronous while every `AnalyticsClient`
/// closure is `async`. Spawning one detached `Task` per call would hand the ordering to
/// the scheduler, and order is load-bearing here — the engine stamps each event with the
/// screen context established by the `screen_view` that preceded it, so a reordered pair
/// stamps the wrong screen. An `AsyncStream` continuation gives a synchronous,
/// order-preserving `yield`, and a single drain task awaits one call before it starts the
/// next, so the sequence that reaches the SDK is the sequence the engine emitted.
public final class AnalyticsFunnelProvider: FunnelClient.Analytics.Providing {
    private enum Call: Sendable {
        case event(name: String, params: AnalyticsClient.Params)
        case userProperty(value: String?, name: String)
    }

    private let client: AnalyticsClient
    private let calls: AsyncStream<Call>.Continuation

    public init(client: AnalyticsClient) {
        let (stream, continuation) = AsyncStream<Call>.makeStream()
        self.client = client
        self.calls = continuation
        Task {
            for await call in stream {
                await Self.perform(call, on: client)
            }
        }
    }

    deinit {
        // Ends the drain loop once the buffered calls have run; cancelling would drop them.
        calls.finish()
    }

    public func logEvent(
        _ name: String,
        parameters: [String: FunnelClient.Analytics.Value]
    ) {
        calls.yield(.event(name: name, params: parameters.mapValues(Self.param)))
    }

    public func setUserProperty(
        _ value: String?,
        forName name: String
    ) {
        calls.yield(.userProperty(value: value, name: name))
    }

    public func sessionID() async -> Int64? {
        await client.sessionID()
    }

    private static func perform(
        _ call: Call,
        on client: AnalyticsClient
    ) async {
        switch call {
            case .event(let name, let params): await client.trackEvent(name, params)
            case .userProperty(let value, let name): await client.setUserProperty(value, name)
        }
    }

    private static func param(_ value: FunnelClient.Analytics.Value) -> AnalyticsClient.Param {
        switch value {
            case .string(let s): return .string(s)
            case .int(let i): return .int(i)
            case .double(let d): return .double(d)
            case .bool(let b): return .bool(b)
            case .items(let items): return .items(items)
        }
    }
}
