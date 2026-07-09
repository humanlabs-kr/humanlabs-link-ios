//
//  EventResponse.swift
//  HumanlabsLinkSDK
//
//  Copyright (c) 2025 HumanlabsLink
//  Licensed under the MIT License
//

import Foundation

/// Response from event tracking endpoint
struct EventResponse: Codable {
    /// Whether the event was successfully tracked
    let success: Bool
}
