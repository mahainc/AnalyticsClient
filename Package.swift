// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AnalyticsClient",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .singleTargetLibrary("AnalyticsClient"),
        .singleTargetLibrary("AnalyticsClientLive"),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-dependencies.git", from: "1.9.0"),
        .package(url: "https://github.com/pointfreeco/swift-case-paths.git", from: "1.5.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "12.13.0"),
        .package(url: "https://github.com/mahainc/FunnelClient.git", exact: "7.0.0"),
    ],
    targets: [
        .target(
            name: "AnalyticsClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "DependenciesMacros", package: "swift-dependencies"),
                .product(name: "CasePaths", package: "swift-case-paths"),
            ]
        ),
        .target(
            name: "AnalyticsClientLive",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "DependenciesMacros", package: "swift-dependencies"),
                .product(name: "CasePaths", package: "swift-case-paths"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk"),
                .product(name: "FunnelClient", package: "FunnelClient"),
                "AnalyticsClient",
            ]
        ),
        .testTarget(
            name: "AnalyticsClientTests",
            dependencies: ["AnalyticsClient"]
        ),
    ]
)

extension Product {
    static func singleTargetLibrary(_ name: String) -> Product {
        .library(name: name, targets: [name])
    }
}
