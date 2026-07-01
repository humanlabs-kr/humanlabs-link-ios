# HumanlabsLink iOS SDK

Native iOS SDK for [HumanlabsLink](https://github.com/humanlabs-kr/universal-link) — the open-source alternative to Branch.io, AppsFlyer OneLink, and Firebase Dynamic Links. Add deferred deep linking, mobile attribution, and smart link routing to your iOS app. Self-hosted, privacy-first, no per-click pricing. 100% Swift with modern async/await APIs.

[![Swift Version](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![iOS Version](https://img.shields.io/badge/iOS-16.0+-blue.svg)](https://www.apple.com/ios)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![SPM Compatible](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager)

## Features

- **Deferred Deep Linking**: Match app installs to link clicks via a privacy-compliant clipboard hand-off token (no device fingerprinting — Apple prohibits it on iOS)
- **Universal Links**: Full support for iOS Universal Links (HTTPS deep links)
- **Custom URL Schemes**: Handle custom app URL schemes
- **Event Tracking**: Track in-app events and conversions
- **Last-Click Attribution**: In-app events are automatically credited to the deep link that most recently opened the app
- **Screen-Flow Tracking**: Report screen views to see what users do after clicking a link
- **Offline Support**: Queue events when offline with automatic retry
- **Privacy-First**: No IDFA collection, complies with Apple's privacy requirements
- **Programmatic Link Creation**: Create short links directly from your app
- **Zero Dependencies**: Lightweight, no third-party dependencies
- **Swift-Native**: 100% Swift, modern async/await APIs

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+

## Installation

### Swift Package Manager (Recommended)

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/humanlabs-kr/universal-link.git", from: "1.0.0")
]
```

Or in Xcode:
1. File > Add Package Dependencies
2. Enter: `https://github.com/humanlabs-kr/universal-link.git`
3. Select version and add to your target

### CocoaPods

```ruby
pod 'HumanlabsLinkSDK', '~> 1.0'
```

### Carthage

```
github "humanlabs-kr/universal-link" ~> 1.0
```

## Quick Start

### 1. Initialize the SDK

In your `AppDelegate.swift` or `@main` App struct:

```swift
import HumanlabsLinkSDK

// In AppDelegate
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    Task {
        do {
            let config = HumanlabsLinkConfig(
                baseURL: URL(string: "https://go.yourdomain.com")!,
                apiKey: "your-api-key",         // Optional for self-hosted
                appToken: "at_a1b2c3d4...",     // Recommended for Cloud — enables organic-install attribution
                debug: true,
                attributionWindowHours: 168 // 7 days
            )
            try await HumanlabsLink.shared.initialize(config: config)
        } catch {
            print("HumanlabsLink initialization failed: \(error)")
        }
    }
    return true
}
```

### 2. Handle Deferred Deep Links (Install Attribution)

```swift
HumanlabsLink.shared.onDeferredDeepLink { deepLinkData in
    if let data = deepLinkData {
        // User installed from a link - navigate to content
        print("Install attributed to: \(data.shortCode)")
        print("UTM Source: \(data.utmParameters?.source ?? "none")")

        // Navigate to the right content
        if let productId = data.customParameters?["productId"] {
            navigateToProduct(id: productId)
        }
    } else {
        // Organic install - no attribution
        print("Organic install")
    }
}
```

**How iOS deferred attribution works (clipboard hand-off, automatic).** Apple
prohibits device fingerprinting regardless of ATT consent, so iOS installs are
never probabilistically matched. Instead, when the user taps a HumanlabsLink,
the web interstitial writes a URL carrying `hl_cid=<clickId>` to the clipboard;
on first launch the SDK reads it back (`ClipboardToken` via `UIPasteboard`) and
sends it as `referrerClickId`, which the server resolves to an exact 1:1
attribution — the Apple-compliant analogue of Android's Play Install Referrer.

Prompt hygiene: the SDK gates the read on a URL being present using
`UIPasteboard.detectPatterns(.probableWebURL)`, which does **not** prompt, and
only calls the value getter (which shows the iOS 16+ "Allow Paste" prompt) when
a URL is actually on the clipboard — so organic installs never see a prompt.
**If the user denies the paste prompt, the install simply stays organic** (no
crash, no attribution). No setup or extra dependency is required — UIKit is
built in.

### 3. Handle Direct Deep Links (Universal Links)

First, enable Associated Domains in your Xcode project:
1. Select your target > Signing & Capabilities
2. Add "Associated Domains"
3. Add domain: `applinks:go.yourdomain.com`

Then handle Universal Links:

```swift
// In AppDelegate or SceneDelegate
func application(_ application: UIApplication,
                continue userActivity: NSUserActivity,
                restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
          let url = userActivity.webpageURL else {
        return false
    }

    HumanlabsLink.shared.handleDeepLink(url: url)
    return true
}

// Or in SwiftUI
.onOpenURL { url in
    HumanlabsLink.shared.handleDeepLink(url: url)
}

// Register callback
HumanlabsLink.shared.onDeepLink { url, deepLinkData in
    print("Deep link opened: \(url)")
    if let data = deepLinkData {
        print("Link data: \(data)")
        // Navigate using deep link path
        if let path = data.deepLinkPath {
            navigateToPath(path)
        }
    }
}
```

> **Server-side resolution:** When the SDK is initialized, deep links are automatically resolved via the server to provide enriched data including `deepLinkPath`, `appScheme`, and `linkId`. If the server is unreachable, the SDK falls back to local URL parsing.

### 4. Track Events

```swift
// Track a simple event
try await HumanlabsLink.shared.trackEvent(name: "button_clicked")

// Track event with properties
try await HumanlabsLink.shared.trackEvent(
    name: "purchase",
    properties: [
        "product_id": "123",
        "amount": 29.99,
        "currency": "USD"
    ]
)

// Track revenue
try await HumanlabsLink.shared.trackRevenue(
    amount: 29.99,
    currency: "USD",
    properties: ["product_id": "123"]
)
```

Every event is automatically stamped with the deep link that most recently opened the app (last-click attribution), so the dashboard can show what users do *after* clicking a link. Events with no preceding deep-link open are reported as organic. No extra code is required.

### 5. Track Screen Views

Reporting screen views lets the dashboard build a per-link screen-flow funnel — which screens users reach after opening a deep link. Each `screen_view` carries the same last-click attribution stamp as other events.

**SwiftUI** — add the `.humanlabs-linkScreen(_:)` modifier to a screen:

```swift
ProductView()
    .humanlabs-linkScreen("ProductDetail")
```

**UIKit** — call from `viewDidAppear`:

```swift
override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    Task { try? await HumanlabsLink.shared.trackScreenView(name: "ProductDetail") }
}
```

> There is no navigation swizzling: you mark the screens you care about, which keeps screen names meaningful and predictable. The SDK records the previous screen automatically so transitions appear in the funnel.

### 6. Create Links Programmatically

```swift
let result = try await HumanlabsLink.shared.createLink(
    options: CreateLinkOptions(
        deepLinkParameters: ["route": "VIDEO_VIEWER", "id": "vid123"],
        title: "Check this out!",
        utmParameters: UTMParameters(source: "app", campaign: "share")
    )
)

print("Share this link: \(result.url)")
// e.g., "https://go.yourdomain.com/tmpl/abc123"
```

> **Note:** Requires an API key in `HumanlabsLinkConfig`. See [API Reference](API.md#createlinkoptions) for all options.

## Advanced Usage

### Self-Hosted HumanlabsLink Core

If you're running your own HumanlabsLink Core instance:

```swift
let config = HumanlabsLinkConfig(
    baseURL: URL(string: "https://links.yourcompany.com")!,
    apiKey: nil, // No API key needed for self-hosted
    debug: false
)
try await HumanlabsLink.shared.initialize(config: config)
```

### Custom Attribution Window

```swift
let config = HumanlabsLinkConfig(
    baseURL: URL(string: "https://go.yourdomain.com")!,
    attributionWindowHours: 24 // 1 day instead of default 7 days
)
```

### Retrieve Install Data

```swift
if let installData = HumanlabsLink.shared.getInstallData() {
    print("Short code: \(installData.shortCode)")
    print("UTM source: \(installData.utmParameters?.source ?? "none")")
}

if let installId = HumanlabsLink.shared.getInstallId() {
    print("Install ID: \(installId)")
}
```

### Event Queue Management

```swift
// Check queued events count
let count = HumanlabsLink.shared.queuedEventCount

// Manually flush event queue
await HumanlabsLink.shared.flushEvents()

// Clear event queue
HumanlabsLink.shared.clearEventQueue()
```

### Clear Data (for testing)

```swift
HumanlabsLink.shared.clearData()

// Reset SDK to uninitialized state
HumanlabsLink.shared.reset()
```

## Universal Links Setup

### 1. Create AASA File

Your backend must serve an Apple App Site Association file at:
`https://go.yourdomain.com/.well-known/apple-app-site-association`

Example:
```json
{
  "applinks": {
    "apps": [],
    "details": [{
      "appID": "TEAM_ID.com.yourcompany.yourapp",
      "paths": ["*"]
    }]
  }
}
```

### 2. Configure Xcode

1. Enable "Associated Domains" capability
2. Add domain: `applinks:go.yourdomain.com`
3. Handle Universal Links in AppDelegate (see Quick Start)

### 3. Test Universal Links

Use Apple's validation tool:
- https://search.developer.apple.com/appsearch-validation-tool

Or test manually:
1. Create a link in HumanlabsLink
2. Open link in Safari on device
3. Long press the link
4. Verify "Open in YourApp" appears

## Privacy & Security

### Privacy-First Design

- **No IDFA**: Does not collect Identifier for Advertisers
- **No Persistent IDs**: Uses probabilistic fingerprinting only
- **Data Minimization**: Collects only necessary attribution data
- **User Control**: Provides `clearData()` for user data deletion
- **Privacy Manifest**: Includes `PrivacyInfo.xcprivacy` file

### Data Collected (for attribution only)

- Device timezone
- Device language
- Screen resolution
- iOS version
- Device model
- App version
- User-Agent string
- Clipboard hand-off token (`hl_cid` click id, deferred deep linking only) — read once on first launch, gated on a URL being present so organic installs see no paste prompt

> **No device fingerprinting on iOS.** Apple prohibits fingerprinting regardless of ATT consent, so the server never probabilistically matches iOS installs. iOS deferred attribution is deterministic via the clipboard hand-off token (see "Deferred Deep Linking" below); an unreferred install stays organic.

### HTTPS Required

The SDK enforces HTTPS for all API endpoints (except localhost for testing).

## Testing

### Unit Tests

```bash
swift test
```

Or in Xcode:
`Cmd+U` to run all tests

### Integration Tests

See `Tests/HumanlabsLinkSDKIntegrationTests/README.md` for setup instructions.

## Documentation

- [Architecture Guide](docs/ARCHITECTURE.md)
- [HumanlabsLink Docs](https://docs.humanlabs.world)
- [Testing Strategy](docs/TESTING_STRATEGY.md)


## Example Apps

- [Basic Example](Examples/BasicExample/) - Simple SwiftUI app demonstrating all SDK features


## Requirements

### Backend

This SDK requires a running HumanlabsLink backend:
- **HumanlabsLink Core** (open source): Self-host for free
- **HumanlabsLink Cloud** (SaaS): Managed service with advanced features

See: https://github.com/humanlabs-kr/universal-link

## Support

- **Documentation**: [docs.humanlabs.world](https://docs.humanlabs.world)
- **Issues**: [GitHub Issues](https://github.com/humanlabs-kr/universal-link/issues)
- **Discussions**: [GitHub Discussions](https://github.com/humanlabs-kr/universal-link/discussions)

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.

## License

HumanlabsLink iOS SDK is available under the MIT license. See [LICENSE](LICENSE) for more info.

## Other SDKs

| Platform | Package |
|----------|---------|
| React Native | [`@humanlabs-kr/link-expo-sdk`](https://github.com/humanlabs-kr/universal-link) |
| Expo | [`@humanlabs-kr/link-expo-sdk`](https://github.com/humanlabs-kr/universal-link) |
| Android (Kotlin) | [HumanlabsLinkSDK](https://github.com/humanlabs-kr/universal-link) |

## Related Projects

- [HumanlabsLink Core](https://github.com/humanlabs-kr/universal-link) — open-source self-hosted deep linking engine
- [HumanlabsLink Cloud](https://humanlabs-link.com) — hosted Core with additional features
