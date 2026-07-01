// swift-tools-version: 5.9

// HumanlabsLink iOS SDK — open-source alternative to Branch.io, AppsFlyer OneLink,
// and Firebase Dynamic Links. Deferred deep linking, mobile attribution, and
// smart link routing for iOS. Self-hosted, privacy-first, no per-click pricing.
// https://github.com/humanlabs-kr/universal-link

import PackageDescription

let package = Package(
    name: "HumanlabsLinkSDK",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        // The main HumanlabsLink SDK library
        .library(
            name: "HumanlabsLinkSDK",
            targets: ["HumanlabsLinkSDK"]
        ),
    ],
    dependencies: [
        // No external dependencies - keeping it lightweight
    ],
    targets: [
        // Main SDK target
        .target(
            name: "HumanlabsLinkSDK",
            dependencies: [],
            path: "Sources/HumanlabsLinkSDK",
            resources: [
                .process("Resources/PrivacyInfo.xcprivacy")
            ]
        ),

        // Unit tests
        .testTarget(
            name: "HumanlabsLinkSDKTests",
            dependencies: ["HumanlabsLinkSDK"],
            path: "Tests/HumanlabsLinkSDKTests"
        ),
    ]
)
