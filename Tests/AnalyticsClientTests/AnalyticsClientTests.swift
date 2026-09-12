import Foundation
import Testing

@testable import AnalyticsClient

@Suite("AnalyticsClient mocks + AnalyticsClient.Param")
struct AnalyticsClientTests {

    @Test("AnalyticsClient.Param literal conversions")
    func analyticParamLiterals() {
        let s: AnalyticsClient.Param = "hello"
        let i: AnalyticsClient.Param = 42
        let d: AnalyticsClient.Param = 3.14
        let b: AnalyticsClient.Param = true

        #expect(s == .string("hello"))
        #expect(i == .int(42))
        #expect(d == .double(3.14))
        #expect(b == .bool(true))
    }

    @Test("AnalyticsClient.Param stringValue is lossless")
    func analyticParamStringValue() {
        #expect(AnalyticsClient.Param.string("hi").stringValue == "hi")
        #expect(AnalyticsClient.Param.int(42).stringValue == "42")
        #expect(AnalyticsClient.Param.double(3.14).stringValue == "3.14")
        #expect(AnalyticsClient.Param.bool(true).stringValue == "true")
    }

    @Test("AnalyticsClient.Param items round-trips GA4 line-items")
    func analyticParamItems() {
        let lineItems = [["item_id": "pro.yearly", "item_name": "Pro Yearly"]]
        let param = AnalyticsClient.Param.items(lineItems)

        #expect(param.anyValue as? [[String: String]] == lineItems)
        #expect(param.stringValue == #"[{"item_id":"pro.yearly","item_name":"Pro Yearly"}]"#)
    }

    @Test("noop mock can be called without crashing")
    func noopMock() async {
        let client = AnalyticsClient.noop
        await client.trackScreen("Home", [:])
        await client.trackEvent("tap_button", ["id": "start"])
        await client.setUserID("u-123")
        await client.log("diagnostic")
        struct E: Error, Sendable {}
        await client.recordError(E(), ["key": "value", "count": 7])
    }

    @Test("custom client captures typed params")
    func customClientTypedParams() async {
        actor Spy {
            var events: [(String, AnalyticsClient.Params)] = []
            func record(
                event: String,
                params: AnalyticsClient.Params
            ) { events.append((event, params)) }
        }
        let spy = Spy()
        // @DependencyClient generates one all-or-nothing memberwise init, so every
        // closure has to be supplied even when the test only exercises trackEvent.
        let client = AnalyticsClient(
            initialize: { _ in },
            trackScreen: { _, _ in },
            trackEvent: { name, params in await spy.record(event: name, params: params) },
            setUserID: { _ in },
            setUserProperty: { _, _ in },
            setAnalyticsCollectionEnabled: { _ in },
            currentSessionID: { nil },
            log: { _ in },
            recordError: { _, _ in }
        )

        await client.trackEvent(
            "purchase",
            [
                "product_id": "pro.yearly",
                "price": 29.99,
                "count": 1,
                "gifted": false,
            ]
        )
        let events = await spy.events
        #expect(events.count == 1)
        #expect(events[0].0 == "purchase")
        #expect(events[0].1["price"] == .double(29.99))
        #expect(events[0].1["count"] == .int(1))
        #expect(events[0].1["gifted"] == .bool(false))
    }
}
