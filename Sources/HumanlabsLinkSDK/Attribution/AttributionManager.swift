//
//  AttributionManager.swift
//  HumanlabsLinkSDK
//
//  Copyright (c) 2025 HumanlabsLink
//  Licensed under the MIT License
//

import Foundation

// MARK: - Protocols for Dependency Injection

protocol NetworkManagerProtocol {
    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        body: Encodable?,
        headers: [String: String]?
    ) async throws -> T
}

protocol StorageManagerProtocol {
    func saveInstallId(_ installId: String)
    func saveInstallData(_ data: DeepLinkData)
    func setHasLaunched()
    func getInstallId() -> String?
    func getInstallData() -> DeepLinkData?
    func isFirstLaunch() -> Bool
    func clearAll()
}

protocol FingerprintCollectorProtocol {
    func collectFingerprint(
        attributionWindowHours: Int,
        deviceId: String?,
        appToken: String?
    ) -> DeviceFingerprint
}

// MARK: - Protocol Conformance

@available(iOS 13.0, macOS 10.15, *)
extension NetworkManager: NetworkManagerProtocol {}

extension StorageManager: StorageManagerProtocol {}

extension FingerprintCollector: FingerprintCollectorProtocol {}

/// Manages install attribution and deferred deep linking
@available(iOS 13.0, macOS 10.15, *)
final class AttributionManager {
    // MARK: - Properties

    private let networkManager: NetworkManagerProtocol
    private let storageManager: StorageManagerProtocol
    private let fingerprintCollector: FingerprintCollectorProtocol

    // MARK: - Initialization

    /// Creates an attribution manager
    /// - Parameters:
    ///   - networkManager: Network manager for API requests
    ///   - storageManager: Storage manager for caching data
    ///   - fingerprintCollector: Fingerprint collector for device data
    init(
        networkManager: NetworkManagerProtocol,
        storageManager: StorageManagerProtocol,
        fingerprintCollector: FingerprintCollectorProtocol
    ) {
        self.networkManager = networkManager
        self.storageManager = storageManager
        self.fingerprintCollector = fingerprintCollector
    }

    // MARK: - Install Attribution

    /// Reports an install to the backend and retrieves attribution data
    ///
    /// - Parameters:
    ///   - attributionWindowHours: Attribution window in hours
    ///   - deviceId: Optional device ID (IDFA/IDFV) if user consented
    ///   - appToken: Optional public workspace token (Cloud organic-install scoping)
    /// - Returns: Install response with attribution data
    /// - Throws: HumanlabsLinkError on failure
    func reportInstall(
        attributionWindowHours: Int,
        deviceId: String? = nil,
        appToken: String? = nil
    ) async throws -> InstallResponse {
        // Idempotency: report an install at most once per device install. The SDK is
        // re-created on every process start and the deferred hand-off token (iOS
        // clipboard) resolves to the same click, so without this gate every app
        // launch would POST a duplicate install_event attributed to the same click —
        // inflating install counts many-fold. Mirrors the Expo SDK.
        if !storageManager.isFirstLaunch() {
            HumanlabsLinkLogger.log("Not first launch — returning cached install attribution")
            return buildCachedResponse()
        }

        // Collect device fingerprint
        var fingerprint = fingerprintCollector.collectFingerprint(
            attributionWindowHours: attributionWindowHours,
            deviceId: deviceId,
            appToken: appToken
        )

        // Deterministic deferred-link token (Apple-compliant). Apple prohibits
        // fingerprinting on iOS, so the server never fingerprint-matches iOS
        // installs — the clipboard hand-off token is how an iOS install attributes
        // to a click. When present, the backend resolves it to an exact match.
        if let referrerClickId = await ClipboardToken.readClickId() {
            fingerprint.referrerClickId = referrerClickId
            HumanlabsLinkLogger.log("Deferred clipboard click id found: \(referrerClickId)")
        }

        HumanlabsLinkLogger.log("Reporting install with fingerprint: \(fingerprint)")

        // Send install request to backend
        let response: InstallResponse = try await networkManager.request(
            endpoint: "/api/sdk/v1/install",
            method: .post,
            body: fingerprint,
            headers: nil
        )

        HumanlabsLinkLogger.log("Install response: \(response)")

        // Cache install ID
        storageManager.saveInstallId(response.installId)

        // Cache deep link data if attributed
        if let deepLinkData = response.deepLinkData {
            storageManager.saveInstallData(deepLinkData)
            HumanlabsLinkLogger.log("Install attributed with confidence: \(response.confidenceScore)%")
        } else {
            HumanlabsLinkLogger.log("Organic install (no attribution)")
        }

        // Mark that app has launched
        storageManager.setHasLaunched()

        return response
    }

    /// Builds an install response from cached attribution without hitting the
    /// network — returned on every launch after the first so repeat launches don't
    /// create duplicate install events.
    private func buildCachedResponse() -> InstallResponse {
        let deepLinkData = storageManager.getInstallData()
        return InstallResponse(
            installId: storageManager.getInstallId() ?? "",
            attributed: deepLinkData != nil,
            confidenceScore: deepLinkData != nil ? 100 : 0,
            matchedFactors: [],
            deepLinkData: deepLinkData
        )
    }

    // MARK: - Data Retrieval

    /// Retrieves the install ID
    /// - Returns: Install ID if available, nil otherwise
    func getInstallId() -> String? {
        storageManager.getInstallId()
    }

    /// Retrieves the cached install attribution data
    /// - Returns: Deep link data if available, nil otherwise
    func getInstallData() -> DeepLinkData? {
        storageManager.getInstallData()
    }

    /// Checks if this is the first launch
    /// - Returns: True if first launch, false otherwise
    func isFirstLaunch() -> Bool {
        storageManager.isFirstLaunch()
    }

    // MARK: - Data Management

    /// Clears all cached attribution data
    func clearData() {
        storageManager.clearAll()
        HumanlabsLinkLogger.log("Attribution data cleared")
    }
}
