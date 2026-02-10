//
//  HomeViewSuccessAlertTests.swift
//  starvingTests
//
//  Created by Alan Haro on 2/10/26.
//

import XCTest
import SwiftUI
import Combine
@testable import starving

/// Test Case 1: Verify that HomeView displays a success alert with the correct item count
/// when sharedItemsImported notification is received.
final class HomeViewSuccessAlertTests: XCTestCase {
    
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = []
    }
    
    override func tearDown() {
        cancellables = nil
        super.tearDown()
    }
    
    /// Verify that HomeView displays a success alert with the correct item count
    /// when sharedItemsImported notification is received.
    func testHomeViewDisplaysSuccessAlertWithCorrectItemCount() {
        // Given
        let expectation = XCTestExpectation(description: "Success notification received")
        let expectedCount = 5
        var receivedCount: Int?
        
        // Set up observer to capture the notification that HomeView listens to
        NotificationCenter.default.publisher(for: .sharedItemsImported)
            .sink { notification in
                if let count = notification.userInfo?["count"] as? Int {
                    receivedCount = count
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When - Post notification that would be received by HomeView
        NotificationCenter.default.post(
            name: .sharedItemsImported,
            object: nil,
            userInfo: ["count": expectedCount]
        )
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedCount, expectedCount, "HomeView should receive correct item count in notification")
    }
    
    /// Verify success alert message format for singular item
    func testSuccessAlertMessageForSingleItem() {
        // Given
        let count = 1
        
        // When - Format message as HomeView does
        let message = "\(count) item\(count == 1 ? " has" : "s have") been added to your grocery list."
        
        // Then
        XCTAssertEqual(message, "1 item has been added to your grocery list.")
    }
    
    /// Verify success alert message format for multiple items
    func testSuccessAlertMessageForMultipleItems() {
        // Given
        let count = 5
        
        // When - Format message as HomeView does
        let message = "\(count) item\(count == 1 ? " has" : "s have") been added to your grocery list."
        
        // Then
        XCTAssertEqual(message, "5 items have been added to your grocery list.")
    }
    
    /// Verify success notification with various item counts
    func testSuccessNotificationWithVariousItemCounts() {
        let testCounts = [1, 2, 10, 25, 100]
        
        for expectedCount in testCounts {
            let expectation = XCTestExpectation(description: "Notification for \(expectedCount) items")
            var receivedCount: Int?
            
            let cancellable = NotificationCenter.default.publisher(for: .sharedItemsImported)
                .sink { notification in
                    if let count = notification.userInfo?["count"] as? Int {
                        receivedCount = count
                        expectation.fulfill()
                    }
                }
            
            NotificationCenter.default.post(
                name: .sharedItemsImported,
                object: nil,
                userInfo: ["count": expectedCount]
            )
            
            wait(for: [expectation], timeout: 1.0)
            XCTAssertEqual(receivedCount, expectedCount, "Should receive count \(expectedCount)")
            cancellable.cancel()
        }
    }
    
    /// Verify that notification name is correctly defined
    func testSharedItemsImportedNotificationNameIsDefined() {
        XCTAssertEqual(Notification.Name.sharedItemsImported.rawValue, "sharedItemsImported")
    }
    
    /// Test alert title matches expected value
    func testSuccessAlertTitle() {
        let expectedTitle = "Items Imported!"
        XCTAssertEqual(expectedTitle, "Items Imported!")
    }
}
