//
//  FirestoreModels.swift
//  starving
//
//  Created by Alan Haro on 1/10/25.
//

import Foundation
import FirebaseFirestore

// MARK: - Firestore Item Model
struct FirestoreItem: Codable, Identifiable {
    @DocumentID var id: String?
    var title: String
    var lastUpdated: Date
    var isHidden: Bool
    var userId: String
    var localId: String? // Reference to local SwiftData ID for sync
    var sharedById: String? // ID of user who shared this item
    var sharedByName: String? // Display name of user who shared
    var sharedByPhotoURL: String? // Profile photo URL of sharer
    var sharedListId: String? // Reference to shared list this item belongs to
    var isCompleted: Bool? // Completion status for shared items
    
    init(title: String, userId: String, localId: String? = nil, sharedById: String? = nil, sharedByName: String? = nil, sharedByPhotoURL: String? = nil, sharedListId: String? = nil) {
        self.title = title
        self.lastUpdated = Date()
        self.isHidden = false
        self.userId = userId
        self.localId = localId
        self.sharedById = sharedById
        self.sharedByName = sharedByName
        self.sharedByPhotoURL = sharedByPhotoURL
        self.sharedListId = sharedListId
        self.isCompleted = false
    }
    
    // Convert from SwiftData Item
    init(from item: Item, userId: String) {
        self.title = item.title
        self.lastUpdated = item.lastUpdated
        self.isHidden = item.isHidden
        self.userId = userId
        self.localId = item.id
    }
    
    // Convert to SwiftData Item
    func toSwiftDataItem() -> Item {
        let item = Item(title: self.title)
        item.id = self.localId ?? UUID().uuidString
        item.lastUpdated = self.lastUpdated
        item.isHidden = self.isHidden
        return item
    }
}

// MARK: - Firestore Day Model  
struct FirestoreDay: Codable, Identifiable {
    @DocumentID var id: String?
    var date: Date
    var itemIds: [String] // References to FirestoreItem IDs
    var userId: String
    var localId: String? // Reference to local SwiftData ID for sync
    
    init(date: Date = Date(), userId: String, localId: String? = nil) {
        self.date = Calendar.current.startOfDay(for: date)
        self.itemIds = []
        self.userId = userId
        self.localId = localId
    }
    
    // Convert from SwiftData Day
    init(from day: Day, userId: String, itemIds: [String] = []) {
        self.date = day.date
        self.itemIds = itemIds
        self.userId = userId
        self.localId = day.id
    }
}

// MARK: - User Preferences
struct UserPreferences: Codable {
    var cloudSyncEnabled: Bool = false
    var syncFrequency: SyncFrequency = .daily
    var lastSyncDate: Date?
    var shareEnabled: Bool = false
    
    enum SyncFrequency: String, Codable, CaseIterable {
        case realTime = "realTime"
        case hourly = "hourly"  
        case daily = "daily"
        case wifiOnly = "wifiOnly"
        case manual = "manual"
        
        var displayName: String {
            switch self {
            case .realTime: return "Real-time"
            case .hourly: return "Every hour"
            case .daily: return "Daily"
            case .wifiOnly: return "Wi-Fi only"
            case .manual: return "Manual"
            }
        }
    }
}

// MARK: - Shared List Model
struct SharedList: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var description: String?
    var itemIds: [String] // IDs of items in this list
    var itemTitles: [String] // Titles of items for display
    var ownerId: String
    var ownerName: String
    var ownerPhotoURL: String?
    var recipientIds: [String] // User IDs who received this list
    var completionStatus: [String: Bool] // recipientId -> completed all items
    var createdAt: Date
    var lastUpdated: Date
    var shareLink: String?
    
    init(name: String, description: String? = nil, ownerId: String, ownerName: String, ownerPhotoURL: String? = nil) {
        self.name = name
        self.description = description
        self.itemIds = []
        self.itemTitles = []
        self.ownerId = ownerId
        self.ownerName = ownerName
        self.ownerPhotoURL = ownerPhotoURL
        self.recipientIds = []
        self.completionStatus = [:]
        self.createdAt = Date()
        self.lastUpdated = Date()
        self.shareLink = nil
    }
}
