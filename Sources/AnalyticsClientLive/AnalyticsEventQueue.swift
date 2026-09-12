import Foundation

/// Serialises the funnel's synchronous analytics calls onto the client's asynchronous ones.
///
/// `FunnelClient.Analytics.Providing` hands events over synchronously while every
/// `AnalyticsClient` closure is `async`. Spawning one detached `Task` per call would hand
/// the ordering to the scheduler, and order is load-bearing: the engine stamps each event
/// with the screen context established by the `screen_view` that preceded it, so a
/// reordered pair stamps the wrong screen.
///
/// An `AsyncStream` continuation gives a synchronous, order-preserving `yield`, and the
/// single drain task awaits one call before starting the next — so the sequence reaching
/// the SDK is the sequence the engine emitted.
///
/// Process-wide because the thing it feeds is process-wide: there is one Firebase.
final class AnalyticsEventQueue: Sendable {
    static let shared = AnalyticsEventQueue()

    private let continuation: AsyncStream<@Sendable () async -> Void>.Continuation

    private init() {
        let (stream, continuation) = AsyncStream<@Sendable () async -> Void>.makeStream()
        self.continuation = continuation
        Task {
            for await work in stream {
                await work()
            }
        }
    }

    func enqueue(_ work: @escaping @Sendable () async -> Void) {
        continuation.yield(work)
    }
}
