//
//  InstallResponseTests.swift
//  HumanlabsLinkSDKTests
//
//  Copyright (c) 2025 HumanlabsLink
//  Licensed under the MIT License
//

@testable import HumanlabsLinkSDK
import XCTest

final class InstallResponseTests: XCTestCase {

    private let decoder = JSONDecoder()

    // MARK: - Tolerant deepLinkData decoding

    func testOrganicInstallWithEmptyDeepLinkDataObjectDecodesToNil() throws {
        // Older Core servers return `deepLinkData: {}` for organic installs.
        // That must decode as nil, not fail the whole response.
        let json = """
        {"installId":"c7cb4810-c9e4-4570-acd6-f38d40082801","attributed":false,
         "confidenceScore":0,"matchedFactors":[],"deepLinkData":{}}
        """.data(using: .utf8)!

        let response = try decoder.decode(InstallResponse.self, from: json)

        XCTAssertFalse(response.attributed)
        XCTAssertNil(response.deepLinkData)
    }

    func testOrganicInstallWithNullDeepLinkDataDecodesToNil() throws {
        let json = """
        {"installId":"c7cb4810-c9e4-4570-acd6-f38d40082801","attributed":false,
         "confidenceScore":0,"matchedFactors":[],"deepLinkData":null}
        """.data(using: .utf8)!

        let response = try decoder.decode(InstallResponse.self, from: json)

        XCTAssertNil(response.deepLinkData)
    }

    func testOrganicInstallWithMissingDeepLinkDataDecodesToNil() throws {
        let json = """
        {"installId":"c7cb4810-c9e4-4570-acd6-f38d40082801","attributed":false,
         "confidenceScore":0,"matchedFactors":[]}
        """.data(using: .utf8)!

        let response = try decoder.decode(InstallResponse.self, from: json)

        XCTAssertNil(response.deepLinkData)
    }

    func testAttributedInstallWithFullDeepLinkDataDecodesNormally() throws {
        let json = """
        {"installId":"id","attributed":true,"confidenceScore":95,
         "matchedFactors":["referrer"],
         "deepLinkData":{"shortCode":"abc123","deepLinkPath":"/product/1",
                         "customParameters":{"referral_code":"AB12CD34"}}}
        """.data(using: .utf8)!

        let response = try decoder.decode(InstallResponse.self, from: json)

        XCTAssertTrue(response.attributed)
        XCTAssertEqual(response.deepLinkData?.shortCode, "abc123")
        XCTAssertEqual(response.deepLinkData?.deepLinkPath, "/product/1")
        XCTAssertEqual(response.deepLinkData?.customParameters?["referral_code"], "AB12CD34")
    }

    // MARK: - Memberwise init

    func testMemberwiseInit() {
        let response = InstallResponse(
            installId: "id",
            attributed: true,
            confidenceScore: 80,
            matchedFactors: ["ip"],
            deepLinkData: DeepLinkData(shortCode: "xyz789")
        )

        XCTAssertEqual(response.installId, "id")
        XCTAssertEqual(response.deepLinkData?.shortCode, "xyz789")
    }
}
