//
//  ClipboardTokenTests.swift
//  HumanlabsLinkSDKTests
//
//  Copyright (c) 2025 HumanlabsLink
//  Licensed under the MIT License
//

@testable import HumanlabsLinkSDK
import XCTest

final class ClipboardTokenTests: XCTestCase {
    private let uuid = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"

    func testParsesClickIdFromInterstitialURLToken() {
        XCTAssertEqual(
            ClipboardToken.parseClickId("https://link.humanlabs.world/_hlcb?hl_cid=\(uuid)"),
            uuid
        )
    }

    func testParsesClickIdRegardlessOfSurroundingParams() {
        XCTAssertEqual(
            ClipboardToken.parseClickId("https://x.io/_hlcb?utm_source=a&hl_cid=\(uuid)&b=1"),
            uuid
        )
    }

    func testAcceptsBareToken() {
        XCTAssertEqual(ClipboardToken.parseClickId("hl_cid=\(uuid)"), uuid)
    }

    func testReturnsNilForUnrelatedContent() {
        XCTAssertNil(ClipboardToken.parseClickId("just some copied text"))
        XCTAssertNil(ClipboardToken.parseClickId("https://example.com/page"))
    }

    func testReturnsNilForEmptyOrMissingInput() {
        // Mirrors the iOS paste-denied case (empty string) and no-clipboard case.
        XCTAssertNil(ClipboardToken.parseClickId(""))
        XCTAssertNil(ClipboardToken.parseClickId(nil))
    }

    func testDoesNotMatchMalformedClickId() {
        XCTAssertNil(ClipboardToken.parseClickId("hl_cid=not-a-uuid"))
    }
}
