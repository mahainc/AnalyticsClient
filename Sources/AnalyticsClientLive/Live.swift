import AnalyticsClient
import Dependencies
@preconcurrency import FirebaseAnalytics
@preconcurrency import FirebaseCrashlytics
import OSLog

/// Firebase Analytics silently drops any param whose key starts with one of
/// these prefixes (Firebase reserves them for SDK-internal use; the drop is
/// reported only as `I-ACS013008` inside Firebase's own subsystem). Surface
/// the drop on our own subsystem so call-site bugs are obvious.
private let reservedParamPrefixes: [String] = ["firebase_", "google_", "ga_"]

private func droppedReservedKeys(_ params: [String: AnalyticsClient.Param]) -> [String] {
    params.keys.filter { key in
        reservedParamPrefixes.contains { key.hasPrefix($0) }
    }
}

extension AnalyticsClient: DependencyKey {
    public static var liveValue: Self {
        .init(
            initialize: { config in
                Logger.analyticsClient.info(
                    "initialize — collectionEnabled=\(config.collectionEnabled, privacy: .public) userID=\(config.userID ?? "nil", privacy: .public) properties=\(config.userProperties.count, privacy: .public)"
                )
                Analytics.setAnalyticsCollectionEnabled(config.collectionEnabled)
                if let id = config.userID {
                    Crashlytics.crashlytics().setUserID(id)
                    Analytics.setUserID(id)
                }
                for (name, value) in config.userProperties {
                    Analytics.setUserProperty(value, forName: name)
                }
            },
            trackScreen: { name, params in
                let dropped = droppedReservedKeys(params)
                if !dropped.isEmpty {
                    Logger.analyticsClient.notice(
                        "trackScreen(\(name, privacy: .public)) — Firebase will DROP params with reserved prefix: \(dropped.joined(separator: ","), privacy: .public)"
                    )
                }
                Logger.analyticsClient.info(
                    "trackScreen(\(name, privacy: .public)) paramCount=\(params.count, privacy: .public)"
                )
                var merged: [String: Any] = [
                    AnalyticsParameterScreenName: name,
                    AnalyticsParameterScreenClass: "\(name)View",
                ]
                for (k, v) in params { merged[k] = v.anyValue }
                Analytics.logEvent(AnalyticsEventScreenView, parameters: merged)
            },
            trackEvent: { name, params in
                let dropped = droppedReservedKeys(params)
                if !dropped.isEmpty {
                    Logger.analyticsClient.notice(
                        "trackEvent(\(name, privacy: .public)) — Firebase will DROP params with reserved prefix: \(dropped.joined(separator: ","), privacy: .public)"
                    )
                }
                Logger.analyticsClient.info(
                    "trackEvent(\(name, privacy: .public)) paramCount=\(params.count, privacy: .public)"
                )
                if params.isEmpty {
                    Analytics.logEvent(name, parameters: nil)
                } else {
                    var dict: [String: Any] = [:]
                    for (k, v) in params { dict[k] = v.anyValue }
                    Analytics.logEvent(name, parameters: dict)
                }
            },
            setUserID: { id in
                Logger.analyticsClient.debug("setUserID(\(id ?? "nil", privacy: .public))")
                // Crashlytics clears with `""`; Analytics clears with `nil`.
                Crashlytics.crashlytics().setUserID(id ?? "")
                Analytics.setUserID(id)
            },
            setUserProperty: { value, name in
                Logger.analyticsClient.info(
                    "setUserProperty(\(name, privacy: .public)=\(value ?? "nil", privacy: .public))"
                )
                // Firebase accepts `nil` to clear the property.
                Analytics.setUserProperty(value, forName: name)
            },
            setAnalyticsCollectionEnabled: { enabled in
                Logger.analyticsClient.info(
                    "setAnalyticsCollectionEnabled(\(enabled, privacy: .public))"
                )
                Analytics.setAnalyticsCollectionEnabled(enabled)
            },
            sessionID: {
                try? await Analytics.sessionID()
            },
            log: { message in
                Logger.analyticsClient.debug("crashlytics.log(\(message, privacy: .public))")
                Crashlytics.crashlytics().log(message)
            },
            recordError: { error, userInfo in
                Logger.analyticsClient.notice(
                    "recordError: \(error.localizedDescription, privacy: .public) userInfoKeys=\(userInfo?.keys.joined(separator: ",") ?? "nil", privacy: .public)"
                )
                if let userInfo {
                    var dict: [String: Any] = [:]
                    for (k, v) in userInfo { dict[k] = v.anyValue }
                    Crashlytics.crashlytics().record(error: error, userInfo: dict)
                } else {
                    Crashlytics.crashlytics().record(error: error, userInfo: nil)
                }
            }
        )
    }
}
