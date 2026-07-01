//
//  StorageKeys.swift
//  HumanlabsLinkSDK
//
//  Copyright (c) 2025 HumanlabsLink
//  Licensed under the MIT License
//

import Foundation

/// UserDefaults keys used by the SDK
enum StorageKeys {
    /// Prefix for all HumanlabsLink SDK keys
    private static let prefix = "world.humanlabs.link.sdk"

    /// Install ID key
    static let installId = "\(prefix).installId"

    /// Install data key (DeepLinkData JSON)
    static let installData = "\(prefix).installData"

    /// First launch flag key
    static let firstLaunch = "\(prefix).firstLaunch"

    /// Active last-click attribution context key (ActiveAttribution JSON)
    static let attribution = "\(prefix).attribution"
}
