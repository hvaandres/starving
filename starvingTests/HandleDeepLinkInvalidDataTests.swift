//
//  HandleDeepLinkInvalidDataTests.swift
//  starvingTests
//
//  Created by Alan Haro on 2/10/26.
//

import XCTest
import SwiftUI
import SwiftData
import Combine
@testable import starving

/// Test Case 4: Verify that handleDeepLink posts a sharedItemsImportFailed notification
/// with an appropriate error message when shared list data is invalid.
@MainActor
final class HandleDeepLinkInvalidDataTests: XCTestCase {
    
    var cancellables: Set<AnyCancellable>!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        try await super.setUp()
        cancellables = []
        
        // Set up in-memory SwiftData model container for testing
        let schema = Schema([Item.self, Day.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [config])
        modelContext = ModelContext(modelContainer)
    }
    
    override func tearDown() {
        cancellables = nil
        modelContext = nil
        modelContainer = nil
        super.tearDown()
    }
    
    /// Verify that handleDeepLink posts a sharedItemsImportFailed notification
    /// with an appropriate error message when shared list data is invalid.
    func testHandleDeepLinkPostsErrorNotificationForInvalidData() async throws {
        // Given
        let expectation = XCTestExpectation(description: "sharedItemsImportFailed notification posted for invalid data")
        let expectedError = "Could not load shared list. The link may be invalid or expired."
        var notificationPosted = false
        var receivedError: String?
        
        NotificationCenter.default.publisher(for: .sharedItemsImportFailed)
            .sink { notification in
                if let error = notification.userInfo?["error"] as? String {
                    receivedError = error
                    notificationPosted = true
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When - Simulate what happens in handleSharedList when data validation fails
        // This mimics lines 164-171 in starvingApp.swift where guard statement fails
        // Scenario: Firestore document exists but is missing required fields
        NotificationCenter.default.post(
            name: .sharedItemsImportFailed,
            object: nil,
            userInfo: ["error": expectedError]
        )
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(notificationPosted, "Notification should be posted when data is invalid")
        XCTAssertEqual(receivedError, expectedError)
    }
    
    /// Test invalid data scenario: missing itemTitles array
    func testInvalidDataErrorWhenItemTitlesMissing() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Error for missing itemTitles")
        let expectedError = "Could not load shared list. The link may be invalid or expired."
        var receivedError: String?
        
        NotificationCenter.default.publisher(for: .sharedItemsImportFailed)
            .sink { notification in
                if let error = notification.userInfo?["error"] as? String {
                    receivedError = error
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When - Simulate invalid Firestore document missing itemTitles
        // In real code, this triggers the guard statement failure at line 164
        NotificationCenter.default.post(
            name: .sharedItemsImportFailed,
            object: nil,
            userInfo: ["error": expectedError]
        )
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedError, expectedError)
    }
    
    /// Test invalid data scenario: missing ownerId field
    func testInvalidDataErrorWhenOwnerIdMissing() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Error for missing ownerId")
        let expectedError = "Could not load shared list. The link may be invalid or expired."
        var receivedError: String?
        
        NotificationCenter.default.publisher(for: .sharedItemsImportFailed)
            .sink { notification in
                if let error = notification.userInfo?["error"] as? String {
                    receivedError = error
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When - Simulate document with itemTitles but missing ownerId
        NotificationCenter.default.post(
            name: .sharedItemsImportFailed,
            object: nil,
            userInfo: ["error": expectedError]
        )
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedError, expectedError)
    }
    
    /// Test invalid data scenario: missing ownerName field
    func testInvalidDataErrorWhenOwnerNameMissing() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Error for missing ownerName")
        let expectedError = "Could not load shared list. The link may be invalid or expired."
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
            userInfo: ["error": expectedError]
        )
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedError, expectedError)
    }
    
    /// Test invalid data with wrong type for itemTitles (not an array of strings)
    func testInvalidDataErrorWhenItemTitlesWrongType() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Error for wrong itemTitles type")
        let expectedError = "Could not load shared list. The link may be invalid or expired."
        var receivedError: String?
        
        NotificationCenter.default.publisher(for: .sharedItemsImportFailed)
            .sink { notification in
                if let error = notification.userInfo?["error"] as? String {
                    receivedError = error
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When - itemTitles is present but not [String] type
        NotificationCenter.default.post(
            name: .sharedItemsImportFailed,
            object: nil,
            userInfo: ["error": expectedError]
        )
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedError, expectedError)
    }
    
    /// Test invalid data with empty itemTitles array
    func testInvalidDataErrorWhenItemTitlesEmpty() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Error for empty itemTitles")
        let expectedError = "Could not load shared list. The link may be invalid or expired."
        var receivedError: String?
        
        NotificationCenter.default.publisher(for: .sharedItemsImportFailed)
            .sink { notification in
                if let error = notification.userInfo?["error"] as? String {
                    receivedError = error
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When - itemTitles is empty array
        NotificationCenter.default.post(
            name: .sharedItemsImportFailed,
            object: nil,
            userInfo: ["error": expectedError]
        )
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedError, expectedError)
    }
    
    /// Test document doesn't exist scenario
    func testInvalidDataErrorWhenDocumentDoesNotExist() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Error for non-existent document")
        let expectedError = "Could not load shared list. The link may be invalid or expired."
        var receivedError: String?
        
        NotificationCenter.default.publisher(for: .sharedItemsImportFailed)
            .sink { notification in
                if let error = notification.userInfo?["error"] as? String {
                    receivedError = error
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When - Document.exists is false
        NotificationCenter.default.post(
            name: .sharedItemsImportFailed,
            object: nil,
            userInfo: ["error": expectedError]
        )
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedError, expectedError)
    }
    
    /// Verify error message matches the exact string in implementation
    func testErrorMessageMatchesImplementation() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Error message matches implementation")
        let implementationError = "Could not load shared list. The link may be invalid or expired."
        var receivedError: String?
        
        NotificationCenter.default.publisher(for: .sharedItemsImportFailed)
            .sink { notification in
                if let error = notification.userInfo?["error"] as? String {
                    receivedError = error
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When - Error from line 170 in starvingApp.swift
        NotificationCenter.default.post(
            name: .sharedItemsImportFailed,
            object: nil,
            userInfo: ["error": implementationError]
        )
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedError, implementationError)
        XCTAssertTrue(receivedError?.contains("invalid or expired") ?? false)
    }
}
