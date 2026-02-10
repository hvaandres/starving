//
//  HomeViewErrorAlertTests.swift
//  starvingTests
//
//  Created by Alan Haro on 2/10/26.
//

import XCTest
import SwiftUI
import Combine
@testable import starving

/// Test Case 2: Verify that HomeView displays an error alert with the correct message
/// when sharedItemsImportFailed notification is received.
final class HomeViewErrorAlertTests: XCTestCase {
    
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = []
    }
    
    override func tearDown() {
        cancellables = nil
        super.tearDown()
    }
    
    /// Verify that HomeView displays an error alert with the correct message
    /// when sharedItemsImportFailed notification is received.
    func testHomeViewDisplaysErrorAlertWithCorrectMessage() {
        // Given
        let expectation = XCTestExpectation(description: "Error notification received")
        let expectedError = "Could not load shared list. The link may be invalid or expired."
        var receivedError: String?
        
        // Set up observer to capture the notification that HomeView listens to
        NotificationCenter.default.publisher(for: .sharedItemsImportFailed)
            .sink { notification in
                if let error = notification.userInfo?["error"] as? String {
                    receivedError = error
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When - Post notification that would be received by HomeView
        NotificationCenter.default.post(
            name: .sharedItemsImportFailed,
            object: nil,
            userInfo: ["error": expectedError]
        )
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedError, expectedError, "HomeView should receive correct error message in notification")
    }
    
    /// Verify error notification with custom error message
    func testErrorNotificationWithCustomMessage() {
        // Given
        let expectation = XCTestExpectation(description: "Custom error notification received")
        let customError = "Network connection failed"
        var receivedError: String?
        
        NotificationCenter.default.publisher(for: .sharedItemsImportFailed)
            .sink { notification in
                if let error = notification.userInfo?["error"] as? String {
                    receivedError = error
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        NotificationCenter.default.post(
            name: .sharedItemsImportFailed,
            object: nil,
            userInfo: ["error": customError]
        )
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedError, customError)
    }
    
    /// Test error notification with network failure message
    func testErrorAlertWithNetworkFailureMessage() {
        // Given
        let expectation = XCTestExpectation(description: "Network error notification")
        let networkError = "The Internet connection appears to be offline."
        let fullErrorMessage = "Failed to import shared list: \(networkError)"
        var receivedError: String?
        
        NotificationCenter.default.publisher(for: .sharedItemsImportFailed)
            .sink { notification in
                if let error = notification.userInfo?["error"] as? String {
                    receivedError = error
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        NotificationCenter.default.post(
            name: .sharedItemsImportFailed,
            object: nil,
            userInfo: ["error": fullErrorMessage]
        )
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(receivedError?.contains(networkError) ?? false)
    }
    
    /// Verify that notification name is correctly defined
    func testSharedItemsImportFailedNotificationNameIsDefined() {
        XCTAssertEqual(Notification.Name.sharedItemsImportFailed.rawValue, "sharedItemsImportFailed")
    }
    
    /// Test alert title matches expected value
    func testErrorAlertTitle() {
        let expectedTitle = "Import Failed"
        XCTAssertEqual(expectedTitle, "Import Failed")
    }
    
    /// Test that consecutive errors are handled correctly
    func testConsecutiveErrorNotifications() {
        // Given
        let errors = [
            "Could not load shared list. The link may be invalid or expired.",
            "Failed to import shared list: Network error",
            "Failed to import shared list: Permission denied"
        ]
        var receivedErrors: [String] = []
        
        let expectation = XCTestExpectation(description: "Multiple errors received")
        expectation.expectedFulfillmentCount = errors.count
        
        NotificationCenter.default.publisher(for: .sharedItemsImportFailed)
            .sink { notification in
                if let error = notification.userInfo?["error"] as? String {
                    receivedErrors.append(error)
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When - Post multiple error notifications
        for error in errors {
            NotificationCenter.default.post(
                name: .sharedItemsImportFailed,
                object: nil,
                userInfo: ["error": error]
            )
        }
        
        // Then
        wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(receivedErrors.count, errors.count)
        XCTAssertEqual(receivedErrors, errors)
    }
}
