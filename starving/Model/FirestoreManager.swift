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

// MARK: - Notification Names
extension Notification.Name {
    static let authStateDidChange = Notification.Name("authStateDidChange")
}

class FirestoreManager: ObservableObject {
    private let db = Firestore.firestore()
    
    @Published var userPreferences = UserPreferences()
    @Published var isCloudSyncEnabled = false
    @Published var syncStatus: SyncStatus = .idle
    @Published var sharedLists: [SharedList] = []
    
    // Cached user ID to avoid race conditions with Auth.auth().currentUser
    private var cachedUserId: String?
    
    init() {
        // Listen for auth state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAuthStateChange),
            name: .authStateDidChange,
            object: nil
        )
        
        // Initialize with current user
        cachedUserId = Auth.auth().currentUser?.uid
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleAuthStateChange(_ notification: Notification) {
        if let userId = notification.userInfo?["userId"] as? String {
            cachedUserId = userId
            print("[FirestoreManager] ✅ Auth state changed - cached user ID updated to: \(userId)")
        } else {
            cachedUserId = nil
            print("[FirestoreManager] ⚠️ Auth state changed - user signed out")
        }
    }
    
    // Update the cached user ID - should be called when auth state changes
    func updateUserId(_ userId: String?) {
        cachedUserId = userId
    }
    
    // Get current user ID with fallback to Auth.auth().currentUser
    private func getCurrentUserId() -> String? {
        // Try cached first, then fall back to Auth.auth().currentUser
        if let cached = cachedUserId {
            return cached
        }
        let userId = Auth.auth().currentUser?.uid
        cachedUserId = userId
        return userId
    }
    
    enum SyncStatus {
        case idle
        case syncing
        case success
        case error(String)
    }
    
    // MARK: - User Preferences
    
    @MainActor
    func loadUserPreferences() async {
        guard let userId = getCurrentUserId() else { return }
        
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
        guard let userId = getCurrentUserId() else { return }
        
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
        guard let userId = getCurrentUserId(),
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
        guard let userId = getCurrentUserId(),
              userPreferences.cloudSyncEnabled else { return }
        
        do {
            try await db.collection("users").document(userId)
                .collection("items").document(itemId).delete()
        } catch {
            print("Error deleting item: \(error)")
        }
    }
    
    func fetchUserItems() async -> [FirestoreItem] {
        guard let userId = getCurrentUserId(),
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
        guard let userId = getCurrentUserId(),
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
        guard let userId = getCurrentUserId(),
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
        print("\n═══════════════════════════════════════════════")
        print("[FirestoreManager] 🚀 createSharedList called")
        print("[FirestoreManager] 📝 Name: \(name)")
        print("[FirestoreManager] 📦 Item count: \(itemIds.count)")
        print("[FirestoreManager] 📋 Items: \(itemTitles)")
        
        
        guard let userId = getCurrentUserId() else {
            print("[FirestoreManager] ❌ FAILED: No authenticated user")
            print("[FirestoreManager] ❌ Cached user ID: \(cachedUserId ?? "nil")")
            print("[FirestoreManager] ❌ Auth.auth().currentUser: \(Auth.auth().currentUser?.uid ?? "nil")")
            print("═══════════════════════════════════════════════\n")
            return nil
        }
        print("[FirestoreManager] ✅ User authenticated: \(userId)")
        
        var sharedList = SharedList(name: name, ownerId: userId, ownerName: ownerName, ownerPhotoURL: ownerPhotoURL)
        sharedList.itemIds = itemIds
        sharedList.itemTitles = itemTitles
        // Populate items array for Firestore rules compatibility
        sharedList.items = zip(itemIds, itemTitles).map { ["id": $0.0, "title": $0.1] }
        // IMPORTANT: Set isPublic = true so recipients can read the shared list via link
        sharedList.isPublic = true
        
        print("[FirestoreManager] 📄 SharedList object created:")
        print("  - ownerId: \(sharedList.ownerId)")
        print("  - ownerName: \(sharedList.ownerName)")
        print("  - sharedWith: \(sharedList.sharedWith)")
        print("  - isPublic: \(sharedList.isPublic)")
        print("  - items count: \(sharedList.items.count)")
        print("  - recipientIds: \(sharedList.recipientIds)")
        print("  - itemIds count: \(sharedList.itemIds.count)")
        print("  - itemTitles count: \(sharedList.itemTitles.count)")
        print("  - createdAt: \(sharedList.createdAt)")
        
        // Log the complete JSON that will be sent to Firestore
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(sharedList)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("[FirestoreManager] 📋 Document JSON to be written:")
                print(jsonString)
            }
        } catch {
            print("[FirestoreManager] ⚠️ Could not encode to JSON: \(error)")
        }
        
        do {
            print("[FirestoreManager] 📤 Attempting to add document to Firestore...")
            print("[FirestoreManager] 🎯 Collection: sharedLists")
            
            // Create document reference first to get ID
            let docRef = db.collection("sharedLists").document()
            let listId = docRef.documentID
            print("[FirestoreManager] 🆔 Generated Document ID: \(listId)")
            
            // Create document data manually to ensure all required fields are present
            let documentData: [String: Any] = [
                "name": sharedList.name,
                "description": sharedList.description as Any,
                "itemIds": sharedList.itemIds,
                "itemTitles": sharedList.itemTitles,
                "items": sharedList.items,
                "ownerId": sharedList.ownerId,
                "ownerName": sharedList.ownerName,
                "ownerPhotoURL": sharedList.ownerPhotoURL as Any,
                "sharedWith": sharedList.sharedWith,
                "isPublic": sharedList.isPublic,
                "recipientIds": sharedList.recipientIds,
                "completionStatus": sharedList.completionStatus,
                "createdAt": sharedList.createdAt,
                "lastUpdated": sharedList.lastUpdated
            ]
            
            print("[FirestoreManager] 📊 Document data dictionary:")
            print(documentData)
            
            // Write the document to Firestore
            print("[FirestoreManager] 💾 Writing document with setData...")
            try await docRef.setData(documentData)
            
            print("[FirestoreManager] ✅ Document added successfully!")
            print("[FirestoreManager] 🆔 Document ID: \(listId)")
            print("[FirestoreManager] 🔗 Document path: sharedLists/\(listId)")
            
            // Update with share link
            print("[FirestoreManager] 🔄 Updating shareLink field...")
            do {
                try await docRef.updateData(["shareLink": "starving://share/\(listId)"])
                print("[FirestoreManager] ✅ shareLink updated successfully")
            } catch {
                print("[FirestoreManager] ⚠️ Failed to update shareLink: \(error)")
                print("[FirestoreManager] ⚠️ Error details: \(error.localizedDescription)")
            }
            
            print("[FirestoreManager] 🔄 Loading shared lists...")
            await loadSharedLists()
            print("[FirestoreManager] ✅ Shared lists loaded")
            
            print("[FirestoreManager] 🎉 SUCCESS! Returning listId: \(listId)")
            print("═══════════════════════════════════════════════\n")
            return listId
        } catch {
            print("[FirestoreManager] ❌ ERROR creating shared list!")
            print("[FirestoreManager] ❌ Error: \(error)")
            print("[FirestoreManager] ❌ Error description: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("[FirestoreManager] ❌ Error domain: \(nsError.domain)")
                print("[FirestoreManager] ❌ Error code: \(nsError.code)")
                print("[FirestoreManager] ❌ Error userInfo: \(nsError.userInfo)")
            }
            print("═══════════════════════════════════════════════\n")
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
        print("[FirestoreManager] 📥 loadSharedLists called")
        guard let userId = getCurrentUserId() else {
            print("[FirestoreManager] ⚠️ loadSharedLists: No authenticated user")
            print("[FirestoreManager] ⚠️ Cached user ID: \(cachedUserId ?? "nil")")
            print("[FirestoreManager] ⚠️ Auth.auth().currentUser: \(Auth.auth().currentUser?.uid ?? "nil")")
            return
        }
        print("[FirestoreManager] 👤 Loading lists for user: \(userId)")
        
        do {
            // Load lists owned by user
            print("[FirestoreManager] 🔍 Querying owned lists...")
            let ownedQuery = try await db.collection("sharedLists")
                .whereField("ownerId", isEqualTo: userId)
                .getDocuments()
            print("[FirestoreManager] 📊 Found \(ownedQuery.documents.count) owned lists")
            
            // Load lists where user is a recipient
            print("[FirestoreManager] 🔍 Querying received lists...")
            let receivedQuery = try await db.collection("sharedLists")
                .whereField("sharedWith", arrayContains: userId)
                .getDocuments()
            print("[FirestoreManager] 📊 Found \(receivedQuery.documents.count) received lists")
            
            var allLists: [SharedList] = []
            
            allLists += ownedQuery.documents.compactMap { try? $0.data(as: SharedList.self) }
            allLists += receivedQuery.documents.compactMap { try? $0.data(as: SharedList.self) }
            
            print("[FirestoreManager] ✅ Total lists loaded: \(allLists.count)")
            for (index, list) in allLists.enumerated() {
                print("  [\(index + 1)] \(list.name) (ID: \(list.id ?? "nil")) - \(list.itemTitles.count) items")
            }
            
            self.sharedLists = allLists
        } catch {
            print("[FirestoreManager] ❌ Error loading shared lists: \(error)")
            print("[FirestoreManager] ❌ Error details: \(error.localizedDescription)")
        }
    }
    
    func addRecipientToSharedList(listId: String, recipientId: String) async {
        do {
            try await db.collection("sharedLists").document(listId).updateData([
                "sharedWith": FieldValue.arrayUnion([recipientId]),
                "recipientIds": FieldValue.arrayUnion([recipientId]), // Keep for backward compat
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
        guard let userId = getCurrentUserId() else { return [] }
        
        do {
            // Get lists where user is a recipient
            let query = try await db.collection("sharedLists")
                .whereField("sharedWith", arrayContains: userId)
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
