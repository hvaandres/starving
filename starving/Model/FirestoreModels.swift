//
//  FirestoreModels.swift
//  starving
//
//  Created by Alan Haro on 1/10/25.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

// MARK: - Firestore Item Model
struct FirestoreItem: Codable, Identifiable {
    @DocumentID var id: String?
    var title: String
    var lastUpdated: Date
    var isHidden: Bool
    var userId: String
    var localId: String? // Reference to local SwiftData ID for sync
    
    init(title: String, userId: String, localId: String? = nil) {
        self.title = title
        self.lastUpdated = Date()
        self.isHidden = false
        self.userId = userId
        self.localId = localId
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
    var items: [FirestoreItem]
    var ownerId: String
    var sharedWith: [String] // User IDs
    var createdAt: Date
    var lastUpdated: Date
    var isPublic: Bool
    
    init(name: String, description: String? = nil, ownerId: String) {
        self.name = name
        self.description = description
        self.items = []
        self.ownerId = ownerId
        self.sharedWith = []
        self.createdAt = Date()
        self.lastUpdated = Date()
        self.isPublic = false
    }
}
