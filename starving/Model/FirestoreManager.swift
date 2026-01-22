//
//  FirestoreManager.swift
//  starving
//
//  Created by Alan Haro on 1/10/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import SwiftUI

class FirestoreManager: ObservableObject {
    private let db = Firestore.firestore()
    
    @Published var userPreferences = UserPreferences()
    @Published var isCloudSyncEnabled = false
    @Published var syncStatus: SyncStatus = .idle
    @Published var sharedLists: [SharedList] = []
    
    enum SyncStatus {
        case idle
        case syncing
        case success
        case error(String)
    }
    
    // MARK: - User Preferences
    
    @MainActor
    func loadUserPreferences() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let document = try await db.collection("userPreferences").document(userId).getDocument()
            
            if document.exists {
                let preferences = try document.data(as: UserPreferences.self)
                self.userPreferences = preferences
                self.isCloudSyncEnabled = preferences.cloudSyncEnabled
            }
        } catch {
            print("Error loading user preferences: \(error)")
        }
    }
    
    @MainActor
    func saveUserPreferences() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            try db.collection("userPreferences").document(userId).setData(from: userPreferences)
            self.isCloudSyncEnabled = userPreferences.cloudSyncEnabled
        } catch {
            print("Error saving user preferences: \(error)")
        }
    }
    
    func enableCloudSync() async {
        userPreferences.cloudSyncEnabled = true
        userPreferences.lastSyncDate = Date()
        await saveUserPreferences()
        
        // Trigger initial sync
        await syncLocalDataToCloud()
    }
    
    func disableCloudSync() async {
        userPreferences.cloudSyncEnabled = false
        await saveUserPreferences()
    }
    
    // MARK: - Item Management
    
    @MainActor
    func saveItem(_ item: FirestoreItem) async {
        guard let userId = Auth.auth().currentUser?.uid,
              userPreferences.cloudSyncEnabled else { return }
        
        do {
            syncStatus = .syncing
            
            if let id = item.id {
                // Update existing
                try db.collection("users").document(userId)
                    .collection("items").document(id).setData(from: item)
            } else {
                // Create new
                let _ = try db.collection("users").document(userId)
                    .collection("items").addDocument(from: item)
            }
            
            syncStatus = .success
            
            // Auto-hide success after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if case .success = self.syncStatus {
                    self.syncStatus = .idle
                }
            }
        } catch {
            syncStatus = .error("Failed to save item: \(error.localizedDescription)")
            print("Error saving item: \(error)")
        }
    }
    
    func deleteItem(withId itemId: String) async {
        guard let userId = Auth.auth().currentUser?.uid,
              userPreferences.cloudSyncEnabled else { return }
        
        do {
            try await db.collection("users").document(userId)
                .collection("items").document(itemId).delete()
        } catch {
            print("Error deleting item: \(error)")
        }
    }
    
    func fetchUserItems() async -> [FirestoreItem] {
        guard let userId = Auth.auth().currentUser?.uid,
              userPreferences.cloudSyncEnabled else { return [] }
        
        do {
            let querySnapshot = try await db.collection("users").document(userId)
                .collection("items").getDocuments()
            
            return querySnapshot.documents.compactMap { document in
                try? document.data(as: FirestoreItem.self)
            }
        } catch {
            print("Error fetching items: \(error)")
            return []
        }
    }
    
    // MARK: - Day Management
    
    func saveDay(_ day: FirestoreDay) async {
        guard let userId = Auth.auth().currentUser?.uid,
              userPreferences.cloudSyncEnabled else { return }
        
        do {
            if let id = day.id {
                try db.collection("users").document(userId)
                    .collection("days").document(id).setData(from: day)
            } else {
                let _ = try db.collection("users").document(userId)
                    .collection("days").addDocument(from: day)
            }
        } catch {
            print("Error saving day: \(error)")
        }
    }
    
    func fetchUserDays() async -> [FirestoreDay] {
        guard let userId = Auth.auth().currentUser?.uid,
              userPreferences.cloudSyncEnabled else { return [] }
        
        do {
            let querySnapshot = try await db.collection("users").document(userId)
                .collection("days").order(by: "date", descending: true).getDocuments()
            
            return querySnapshot.documents.compactMap { document in
                try? document.data(as: FirestoreDay.self)
            }
        } catch {
            print("Error fetching days: \(error)")
            return []
        }
    }
    
    // MARK: - Sync Operations
    
    @MainActor
    func syncLocalDataToCloud() async {
        guard userPreferences.cloudSyncEnabled else { return }
        syncStatus = .syncing
        
        // This will be implemented to sync SwiftData to Firestore
        // We'll need to pass in the SwiftData context
        print("Syncing local data to cloud...")
        
        // Update last sync date
        userPreferences.lastSyncDate = Date()
        await saveUserPreferences()
        
        syncStatus = .success
    }
    
    func syncCloudDataToLocal() async {
        guard userPreferences.cloudSyncEnabled else { return }
        
        // Fetch cloud data and update local SwiftData
        let cloudItems = await fetchUserItems()
        let cloudDays = await fetchUserDays()
        
        print("Found \(cloudItems.count) items and \(cloudDays.count) days in cloud")
        // Implementation will be in the HybridDataManager
    }
    
    // MARK: - User Profile Management
    
    func saveUserProfile(userId: String, displayName: String, email: String?, photoURL: String?, provider: UserProfile.AuthProvider) async {
        let profile = UserProfile(userId: userId, displayName: displayName, email: email, photoURL: photoURL, provider: provider)
        
        do {
            try db.collection("users").document(userId).setData(from: profile)
        } catch {
            print("Error saving user profile: \(error)")
        }
    }
    
    func getUserProfile(userId: String) async -> UserProfile? {
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            return try? document.data(as: UserProfile.self)
        } catch {
            print("Error fetching user profile: \(error)")
            return nil
        }
    }
    
    // MARK: - Sharing Functions
    
    func createSharedList(name: String, itemIds: [String], itemTitles: [String], ownerName: String, ownerPhotoURL: String?) async -> String? {
        guard let userId = Auth.auth().currentUser?.uid else { return nil }
        
        var sharedList = SharedList(name: name, ownerId: userId, ownerName: ownerName, ownerPhotoURL: ownerPhotoURL)
        sharedList.itemIds = itemIds
        sharedList.itemTitles = itemTitles
        
        do {
            let docRef = try db.collection("sharedLists").addDocument(from: sharedList)
            let listId = docRef.documentID
            
            // Update with share link
            try await docRef.updateData(["shareLink": "starving://share/\(listId)"])
            
            await loadSharedLists() // Refresh the list
            return listId
        } catch {
            print("Error creating shared list: \(error)")
            return nil
        }
    }
    
    func getSharedList(listId: String) async -> SharedList? {
        do {
            let document = try await db.collection("sharedLists").document(listId).getDocument()
            return try? document.data(as: SharedList.self)
        } catch {
            print("Error fetching shared list: \(error)")
            return nil
        }
    }
    
    @MainActor
    func loadSharedLists() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            // Load lists owned by user
            let ownedQuery = try await db.collection("sharedLists")
                .whereField("ownerId", isEqualTo: userId)
                .getDocuments()
            
            // Load lists where user is a recipient
            let receivedQuery = try await db.collection("sharedLists")
                .whereField("recipientIds", arrayContains: userId)
                .getDocuments()
            
            var allLists: [SharedList] = []
            
            allLists += ownedQuery.documents.compactMap { try? $0.data(as: SharedList.self) }
            allLists += receivedQuery.documents.compactMap { try? $0.data(as: SharedList.self) }
            
            self.sharedLists = allLists
        } catch {
            print("Error loading shared lists: \(error)")
        }
    }
    
    func addRecipientToSharedList(listId: String, recipientId: String) async {
        do {
            try await db.collection("sharedLists").document(listId).updateData([
                "recipientIds": FieldValue.arrayUnion([recipientId]),
                "lastUpdated": Date()
            ])
            await loadSharedLists()
        } catch {
            print("Error adding recipient to shared list: \(error)")
        }
    }
    
    func updateCompletionStatus(listId: String, recipientId: String, completed: Bool) async {
        do {
            try await db.collection("sharedLists").document(listId).updateData([
                "completionStatus.\(recipientId)": completed,
                "lastUpdated": Date()
            ])
            await loadSharedLists()
        } catch {
            print("Error updating completion status: \(error)")
        }
    }
    
    func getSharedListsForUser() async -> [SharedList] {
        guard let userId = Auth.auth().currentUser?.uid else { return [] }
        
        do {
            // Get lists where user is a recipient
            let query = try await db.collection("sharedLists")
                .whereField("recipientIds", arrayContains: userId)
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            return query.documents.compactMap { try? $0.data(as: SharedList.self) }
        } catch {
            print("Error fetching shared lists for user: \(error)")
            return []
        }
    }
}

// MARK: - Convenience Extensions
extension FirestoreManager {
    var shouldShowSyncStatus: Bool {
        switch syncStatus {
        case .syncing, .success, .error:
            return true
        case .idle:
            return false
        }
    }
    
    var syncStatusMessage: String {
        switch syncStatus {
        case .idle:
            return ""
        case .syncing:
            return "Syncing..."
        case .success:
            return "Synced successfully"
        case .error(let message):
            return message
        }
    }
    
    var syncStatusColor: Color {
        switch syncStatus {
        case .idle:
            return .clear
        case .syncing:
            return .blue
        case .success:
            return .green
        case .error:
            return .red
        }
    }
}
