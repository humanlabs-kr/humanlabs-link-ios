//
//  ClipboardToken.swift
//  HumanlabsLinkSDK
//
//  Copyright (c) 2025 HumanlabsLink
//  Licensed under the MIT License
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Reads the deterministic deferred-deep-link hand-off token from the iOS
/// clipboard — the Apple-compliant analogue of Android's Play Install Referrer.
///
/// At click time the web interstitial writes a URL carrying `hl_cid=<clickId>`
/// to the clipboard on the user's tap; on first launch the SDK reads it back and
/// the server resolves the click id to an exact 1:1 attribution — no
/// fingerprinting, which Apple prohibits on iOS.
enum ClipboardToken {
    /// Extract the `hl_cid` UUID from a clipboard token (a URL or bare token).
    static func parseClickId(_ value: String?) -> String? {
        guard let value = value, !value.isEmpty else { return nil }
        let pattern = "hl_cid=([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(value.startIndex..<value.endIndex, in: value)
        guard let match = regex.firstMatch(in: value, options: [], range: range),
              let captured = Range(match.range(at: 1), in: value) else {
            return nil
        }
        return String(value[captured])
    }

    #if canImport(UIKit)
    /// Read the deferred click id from the general pasteboard.
    ///
    /// Prompt hygiene: gated on a URL being present, checked with
    /// `detectPatterns(for:)` which does NOT trigger the paste prompt (iOS 14+),
    /// so organic installs (no token) never see a prompt. Only when a URL is
    /// present do we read the value — which shows the iOS 16+ "Allow Paste"
    /// prompt. If the user denies it, the value is empty and this returns nil, so
    /// the install simply stays organic. Never throws.
    @MainActor
    static func readClickId() async -> String? {
        let pasteboard = UIPasteboard.general
        if #available(iOS 14.0, *) {
            let hasURL: Bool = await withCheckedContinuation { continuation in
                pasteboard.detectPatterns(for: [.probableWebURL]) { result in
                    switch result {
                    case .success(let patterns):
                        continuation.resume(returning: patterns.contains(.probableWebURL))
                    case .failure:
                        continuation.resume(returning: false)
                    }
                }
            }
            guard hasURL else { return nil }
        } else {
            guard pasteboard.hasStrings else { return nil }
        }
        return parseClickId(pasteboard.string)
    }
    #else
    /// Non-UIKit platforms (e.g. macOS) have no UIPasteboard deferred path.
    static func readClickId() async -> String? { nil }
    #endif
}
