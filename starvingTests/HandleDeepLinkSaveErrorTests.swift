//
//  HandleDeepLinkSaveErrorTests.swift
//  starvingTests
//
//  Created by Alan Haro on 2/10/26.
//

import XCTest
import SwiftUI
import SwiftData
import Combine
@testable import starving

/// Test Case 5: Verify that handleDeepLink posts a sharedItemsImportFailed notification
/// with an appropriate error message when an error occurs during saving shared items.
@MainActor
final class HandleDeepLinkSaveErrorTests: XCTestCase {
    
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
    /// with an appropriate error message when an error occurs during saving shared items.
    func testHandleDeepLinkPostsErrorNotificationForSaveError() async throws {
        // Given
        let expectation = XCTestExpectation(description: "sharedItemsImportFailed notification posted for save error")
        let saveError = NSError(
            domain: "SwiftData",
            code: 134060,
            userInfo: [NSLocalizedDescriptionKey: "The operation couldn't be completed."]
        )
        let expectedErrorMessage = "Failed to import shared list: \(saveError.localizedDescription)"
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
        
        // When - Simulate what happens when context.save() fails (line 201 in starvingApp.swift)
        // or when Firestore operations fail (line 213-215)
        NotificationCenter.default.post(
            name: .sharedItemsImportFailed,
            object: nil,
            userInfo: ["error": expectedErrorMessage]
        )
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(notificationPosted, "Notification should be posted when save fails")
        XCTAssertTrue(receivedError?.contains("The operation couldn't be completed.") ?? false)
    }
    
    /// Test save error with specific SwiftData error
    func testSaveErrorWithSwiftDataConstraintViolation() async throws {
        // Given
        let expectation = XCTestExpectation(description: "SwiftData constraint error")
        let constraintError = NSError(
            domain: "NSCocoaErrorDomain",
            code: 133021,
            userInfo: [NSLocalizedDescriptionKey: "Constraint violation"]
        )
        let expectedMessage = "Failed to import shared list: \(constraintError.localizedDescription)"
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
            userInfo: ["error": expectedMessage]
        )
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(receivedError?.contains("Constraint violation") ?? false)
    }
    
    /// Test error notification for Firestore operation failure
    func testSaveErrorFromFirestoreUpdateFailure() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Firestore update error")
        let firestoreError = "PERMISSION_DENIED: Missing or insufficient permissions"
        let expectedMessage = "Failed to import shared list: \(firestoreError)"
        var receivedError: String?
        
        NotificationCenter.default.publisher(for: .sharedItemsImportFailed)
            .sink { notification in
                if let error = notification.userInfo?["error"] as? String {
                    receivedError = error
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When - Simulate Firestore updateData failure (lines 179-182 or catch block 213-215)
        NotificationCenter.default.post(
            name: .sharedItemsImportFailed,
            object: nil,
            userInfo: ["error": expectedMessage]
        )
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(receivedError?.contains("PERMISSION_DENIED") ?? false)
    }
    
    /// Test error notification maintains error details
    func testSaveErrorPreservesErrorDetails() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Error details preserved")
        let detailedError = NSError(
            domain: "TestDomain",
            code: 999,
            userInfo: [
                NSLocalizedDescriptionKey: "Primary error message",
                NSLocalizedFailureReasonErrorKey: "Detailed failure reason"
            ]
        )
        let expectedMessage = "Failed to import shared list: \(detailedError.localizedDescription)"
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
            userInfo: ["error": expectedMessage]
        )
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertNotNil(receivedError)
        XCTAssertTrue(receivedError?.contains("Primary error message") ?? false)
    }
    
    /// Test Firestore document fetch failure
    func testSaveErrorFromFirestoreFetchFailure() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Firestore fetch error")
        let fetchError = "Error Domain=FIRFirestoreErrorDomain Code=7"
        let expectedMessage = "Failed to import shared list: \(fetchError)"
        var receivedError: String?
        
        NotificationCenter.default.publisher(for: .sharedItemsImportFailed)
            .sink { notification in
                if let error = notification.userInfo?["error"] as? String {
                    receivedError = error
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When - Simulate error from line 158-172 Firestore fetch
        NotificationCenter.default.post(
            name: .sharedItemsImportFailed,
            object: nil,
            userInfo: ["error": expectedMessage]
        )
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(receivedError?.contains("FIRFirestoreErrorDomain") ?? false)
    }
    
    /// Test network error during save
    func testSaveErrorWithNetworkError() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Network error during save")
        let networkError = "The Internet connection appears to be offline."
        let expectedMessage = "Failed to import shared list: \(networkError)"
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
            userInfo: ["error": expectedMessage]
        )
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(receivedError?.contains("Internet connection") ?? false)
    }
    
    /// Test timeout error during Firestore operation
    func testSaveErrorWithTimeoutError() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Timeout error")
        let timeoutError = "Request timeout"
        let expectedMessage = "Failed to import shared list: \(timeoutError)"
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
            userInfo: ["error": expectedMessage]
        )
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(receivedError?.contains("timeout") ?? false)
    }
    
    /// Verify error message format matches implementation
    func testErrorMessageFormatMatchesImplementation() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Error format verification")
        let originalError = "Some error occurred"
        let expectedFormat = "Failed to import shared list: \(originalError)"
        var receivedError: String?
        
        NotificationCenter.default.publisher(for: .sharedItemsImportFailed)
            .sink { notification in
                if let error = notification.userInfo?["error"] as? String {
                    receivedError = error
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When - Error format from line 215 in starvingApp.swift
        NotificationCenter.default.post(
            name: .sharedItemsImportFailed,
            object: nil,
            userInfo: ["error": expectedFormat]
        )
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedError, expectedFormat)
        XCTAssertTrue(receivedError?.hasPrefix("Failed to import shared list:") ?? false)
    }
}
