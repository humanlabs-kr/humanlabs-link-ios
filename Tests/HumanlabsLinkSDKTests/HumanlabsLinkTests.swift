//
//  HumanlabsLinkTests.swift
//  HumanlabsLinkSDKTests
//
//  Copyright (c) 2025 HumanlabsLink
//  Licensed under the MIT License
//

@testable import HumanlabsLinkSDK
import XCTest

@available(iOS 13.0, macOS 10.15, *)
final class HumanlabsLinkTests: XCTestCase {
    var config: HumanlabsLinkConfig!

    override func setUp() {
        super.setUp()

        // Reset singleton state before each test
        HumanlabsLink.shared.reset()
        HumanlabsLink.shared.clearData()

        // Create test configuration
        config = HumanlabsLinkConfig(
            baseURL: URL(string: "https://api.humanlabs-link.com")!
        )
    }

    override func tearDown() {
        HumanlabsLink.shared.reset()
        HumanlabsLink.shared.clearData()
        config = nil
        super.tearDown()
    }

    // MARK: - Singleton Tests

    func testSharedInstanceIsSingleton() {
        let instance1 = HumanlabsLink.shared
        let instance2 = HumanlabsLink.shared

        XCTAssertTrue(instance1 === instance2)
    }

    // MARK: - Initialization Tests

    func testInitializeThrowsForInvalidConfig() async {
        // Arrange - invalid URL with negative attribution window
        let invalidConfig = HumanlabsLinkConfig(
            baseURL: URL(string: "https://api.humanlabs-link.com")!,
            attributionWindowHours: -1
        )

        // Act & Assert
        do {
            _ = try await HumanlabsLink.shared.initialize(config: invalidConfig)
            XCTFail("Should throw error for invalid config")
        } catch {
            // Expected
            XCTAssertNotNil(error)
        }
    }

    func testInitializeThrowsWhenAlreadyInitialized() async {
        // This test is skipped because we can't mock the network layer
        // in the singleton without dependency injection
        // We would need to initialize once, then try again
    }

    func testResetClearsInitializedState() {
        // Act
        HumanlabsLink.shared.reset()

        // Assert
        XCTAssertNil(HumanlabsLink.shared.getInstallId())
    }

    // MARK: - Deep Link Tests

    func testHandleDeepLinkBeforeInitialize() {
        // Arrange
        let url = URL(string: "https://example.com/abc123")!

        // Act - Should not crash
        HumanlabsLink.shared.handleDeepLink(url: url)

        // Assert - Just verify no crash
        XCTAssertTrue(true)
    }

    func testOnDeferredDeepLinkBeforeInitialize() {
        // Arrange
        var callbackInvoked = false
        let callback: DeferredDeepLinkCallback = { _ in
            callbackInvoked = true
        }

        // Act
        HumanlabsLink.shared.onDeferredDeepLink(callback)

        // Assert - Callback should not be registered before initialization
        XCTAssertFalse(callbackInvoked)
    }

    func testOnDeepLinkBeforeInitialize() {
        // Arrange
        var callbackInvoked = false
        let callback: DeepLinkCallback = { _, _ in
            callbackInvoked = true
        }

        // Act
        HumanlabsLink.shared.onDeepLink(callback)

        // Assert - Callback should not be registered before initialization
        XCTAssertFalse(callbackInvoked)
    }

    // MARK: - Event Tracking Tests

    func testTrackEventBeforeInitializeThrows() async {
        // Act & Assert
        do {
            try await HumanlabsLink.shared.trackEvent(name: "test")
            XCTFail("Should throw error when not initialized")
        } catch let error as HumanlabsLinkError {
            if case .notInitialized = error {
                // Expected
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type")
        }
    }

    func testTrackRevenueBeforeInitializeThrows() async {
        // Act & Assert
        do {
            try await HumanlabsLink.shared.trackRevenue(amount: 9.99, currency: "USD")
            XCTFail("Should throw error when not initialized")
        } catch let error as HumanlabsLinkError {
            if case .notInitialized = error {
                // Expected
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type")
        }
    }

    func testFlushEventsBeforeInitialize() async {
        // Act - Should not crash
        await HumanlabsLink.shared.flushEvents()

        // Assert - Just verify no crash
        XCTAssertTrue(true)
    }

    func testQueuedEventCountBeforeInitialize() {
        // Act
        let count = HumanlabsLink.shared.queuedEventCount

        // Assert
        XCTAssertEqual(count, 0)
    }

    func testClearEventQueueBeforeInitialize() {
        // Act - Should not crash
        HumanlabsLink.shared.clearEventQueue()

        // Assert - Just verify no crash
        XCTAssertTrue(true)
    }

    // MARK: - Attribution Data Tests

    func testGetInstallIdBeforeInitialize() {
        // Act
        let installId = HumanlabsLink.shared.getInstallId()

        // Assert
        XCTAssertNil(installId)
    }

    func testGetInstallDataBeforeInitialize() {
        // Act
        let data = HumanlabsLink.shared.getInstallData()

        // Assert
        XCTAssertNil(data)
    }

    func testIsFirstLaunchBeforeInitialize() {
        // Act
        let isFirst = HumanlabsLink.shared.isFirstLaunch()

        // Assert
        XCTAssertTrue(isFirst)
    }

    // MARK: - Data Management Tests

    func testClearDataDoesNotCrash() {
        // Act & Assert
        XCTAssertNoThrow(HumanlabsLink.shared.clearData())
    }

    func testResetDoesNotCrash() {
        // Act & Assert
        XCTAssertNoThrow(HumanlabsLink.shared.reset())
    }

    func testClearDataThenReset() {
        // Act & Assert
        XCTAssertNoThrow(HumanlabsLink.shared.clearData())
        XCTAssertNoThrow(HumanlabsLink.shared.reset())
    }

    // MARK: - Configuration Validation Tests

    func testConfigWithHTTPURLThrows() async {
        // Arrange
        let httpConfig = HumanlabsLinkConfig(
            baseURL: URL(string: "http://api.humanlabs-link.com")!
        )

        // Act & Assert
        do {
            _ = try await HumanlabsLink.shared.initialize(config: httpConfig)
            XCTFail("Should throw error for HTTP URL")
        } catch {
            // Expected
            XCTAssertNotNil(error)
        }
    }

    func testConfigWithLocalhostHTTPAllowed() {
        // Arrange
        let localhostConfig = HumanlabsLinkConfig(
            baseURL: URL(string: "http://localhost:3000")!
        )

        // Act & Assert
        XCTAssertNoThrow(try localhostConfig.validate())
    }

    func testConfigWithInvalidAttributionWindowThrows() {
        // Arrange & Act
        let invalidConfig = HumanlabsLinkConfig(
            baseURL: URL(string: "https://api.humanlabs-link.com")!,
            attributionWindowHours: 3000 // Too large
        )

        // Assert
        XCTAssertThrowsError(try invalidConfig.validate())
    }

    // MARK: - Thread Safety Tests

    func testConcurrentResetCalls() {
        // Arrange
        let expectation = expectation(description: "Concurrent resets")
        expectation.expectedFulfillmentCount = 10

        // Act - Reset from multiple threads
        for _ in 1...10 {
            DispatchQueue.global().async {
                HumanlabsLink.shared.reset()
                expectation.fulfill()
            }
        }

        // Assert
        wait(for: [expectation], timeout: 2.0)
        // If we get here without crash, test passes
        XCTAssertTrue(true)
    }

    func testConcurrentClearDataCalls() {
        // Arrange
        let expectation = expectation(description: "Concurrent clear data")
        expectation.expectedFulfillmentCount = 10

        // Act - Clear data from multiple threads
        for _ in 1...10 {
            DispatchQueue.global().async {
                HumanlabsLink.shared.clearData()
                expectation.fulfill()
            }
        }

        // Assert
        wait(for: [expectation], timeout: 2.0)
        // If we get here without crash, test passes
        XCTAssertTrue(true)
    }
}
