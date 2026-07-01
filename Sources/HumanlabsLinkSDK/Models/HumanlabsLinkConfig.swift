//
//  HumanlabsLinkConfig.swift
//  HumanlabsLinkSDK
//
//  Copyright (c) 2025 HumanlabsLink
//  Licensed under the MIT License
//

import Foundation

/// Configuration for the HumanlabsLink SDK
public struct HumanlabsLinkConfig {
    // MARK: - Properties

    /// The base URL of your HumanlabsLink instance
    /// - Note: Must be HTTPS in production (HTTP allowed for localhost testing only)
    public let baseURL: URL

    /// Public workspace token for HumanlabsLink Cloud (optional)
    /// - Note: Recommended for Cloud — required for organic installs
    ///   (App Store discovery, social mentions, etc.) to be attributed
    ///   to your workspace. Find it in the dashboard under Workspace
    ///   Settings → App Token. Safe to ship in your app bundle —
    ///   identifies the workspace only, can't authenticate API actions.
    /// - Format: `at_<32 hex chars>`
    public let appToken: String?

    /// Enable debug logging
    /// - Note: Logs network requests, responses, and SDK operations
    public let debug: Bool

    /// Attribution window in hours (1-2160, default: 168 = 7 days)
    /// - Note: How long after a click an install can be attributed
    public let attributionWindowHours: Int

    // MARK: - Initialization

    /// Creates a new HumanlabsLink configuration
    ///
    /// - Parameters:
    ///   - baseURL: The base URL of your HumanlabsLink instance (e.g., https://go.yourdomain.com)
    ///   - appToken: Optional public workspace token (HumanlabsLink Cloud only)
    ///   - debug: Enable debug logging (default: false)
    ///   - attributionWindowHours: Attribution window in hours (default: 168 = 7 days)
    ///
    /// - Note: For self-hosted HumanlabsLink Core, omit the appToken parameter
    public init(
        baseURL: URL = URL(string: "https://link.humanlabs.world")!,
        appToken: String? = nil,
        debug: Bool = false,
        attributionWindowHours: Int = 168
    ) {
        self.baseURL = baseURL
        self.appToken = appToken
        self.debug = debug
        self.attributionWindowHours = attributionWindowHours
    }

    // MARK: - Validation

    /// Validates the configuration
    /// - Throws: `HumanlabsLinkError.invalidConfiguration` if validation fails
    func validate() throws {
        // Validate HTTPS (except localhost)
        if baseURL.scheme != "https" && !isLocalhost {
            throw HumanlabsLinkError.invalidConfiguration(
                "Base URL must use HTTPS (HTTP only allowed for localhost)"
            )
        }

        // Validate attribution window (1 hour to 90 days)
        guard attributionWindowHours >= 1 && attributionWindowHours <= 2160 else {
            throw HumanlabsLinkError.invalidConfiguration(
                "Attribution window must be between 1 and 2160 hours"
            )
        }
    }

    // MARK: - Helpers

    /// Checks if the base URL is localhost
    private var isLocalhost: Bool {
        guard let host = baseURL.host else { return false }
        return host == "localhost" || host == "127.0.0.1" || host == "0.0.0.0"
    }
}

// MARK: - CustomStringConvertible

extension HumanlabsLinkConfig: CustomStringConvertible {
    public var description: String {
        """
        HumanlabsLinkConfig(
            baseURL: \(baseURL.absoluteString),
            appToken: \(appToken != nil ? "***" : "nil"),
            debug: \(debug),
            attributionWindowHours: \(attributionWindowHours)
        )
        """
    }
}
