//
//  HybridDataManager.swift
//  starving
//
//  Created by Alan Haro on 1/10/25.
//

import Foundation
import SwiftData
import SwiftUI
import FirebaseAuth

@MainActor
class HybridDataManager: ObservableObject {
    private var modelContext: ModelContext?
    private let firestoreManager = FirestoreManager()
    
    @Published var cloudSyncEnabled: Bool = false
    @Published var syncStatus: FirestoreManager.SyncStatus = .idle
    
    init() {
        // Observe Firestore manager changes
        firestoreManager.$isCloudSyncEnabled
            .assign(to: &$cloudSyncEnabled)
        
        firestoreManager.$syncStatus
            .assign(to: &$syncStatus)
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        
        // Load user preferences when context is set
        Task {
            await firestoreManager.loadUserPreferences()
        }
    }
    
    // MARK: - Cloud Sync Controls
    
    func enableCloudSync() async {
        await firestoreManager.enableCloudSync()
        await syncAllLocalDataToCloud()
    }
    
    func disableCloudSync() async {
        await firestoreManager.disableCloudSync()
    }
    
    // MARK: - Item Operations (Hybrid)
    
    func addItem(title: String) async {
        guard let context = modelContext else { return }
        
        // Always save to local SwiftData first
        let localItem = Item(title: title)
        context.insert(localItem)
        
        do {
            try context.save()
            
            // If cloud sync is enabled, also save to Firestore
            if cloudSyncEnabled {
                if let userId = Auth.auth().currentUser?.uid {
                    let firestoreItem = FirestoreItem(from: localItem, userId: userId)
                    await firestoreManager.saveItem(firestoreItem)
                }
            }
        } catch {
            print("Error saving item locally: \(error)")
        }
    }
    
    func updateItem(_ item: Item) async {
        guard let context = modelContext else { return }
        
        // Update locally first
        item.lastUpdated = Date()
        
        do {
            try context.save()
            
            // Sync to cloud if enabled
            if cloudSyncEnabled {
                if let userId = Auth.auth().currentUser?.uid {
                    let firestoreItem = FirestoreItem(from: item, userId: userId)
                    await firestoreManager.saveItem(firestoreItem)
                }
            }
        } catch {
            print("Error updating item locally: \(error)")
        }
    }
    
    func deleteItem(_ item: Item) async {
        guard let context = modelContext else { return }
        
        // Delete from cloud first (if enabled)
        if cloudSyncEnabled {
            // Find corresponding Firestore item and delete it
            let cloudItems = await firestoreManager.fetchUserItems()
            if let cloudItem = cloudItems.first(where: { $0.localId == item.id }),
               let cloudItemId = cloudItem.id {
                await firestoreManager.deleteItem(withId: cloudItemId)
            }
        }
        
        // Delete locally
        context.delete(item)
        
        do {
            try context.save()
        } catch {
            print("Error deleting item locally: \(error)")
        }
    }
    
    // MARK: - Day Operations (Hybrid)
    
    func updateDay(_ day: Day) async {
        guard let context = modelContext else { return }
        
        do {
            try context.save()
            
            // Sync to cloud if enabled
            if cloudSyncEnabled {
                if let userId = Auth.auth().currentUser?.uid {
                    // Get item IDs for the day (this would need to be implemented)
                    let firestoreDay = FirestoreDay(from: day, userId: userId)
                    await firestoreManager.saveDay(firestoreDay)
                }
            }
        } catch {
            print("Error updating day locally: \(error)")
        }
    }
    
    // MARK: - Sync Operations
    
    func syncAllLocalDataToCloud() async {
        guard cloudSyncEnabled,
              let context = modelContext,
              let userId = Auth.auth().currentUser?.uid else { return }
        
        firestoreManager.syncStatus = .syncing
        
        do {
            // Fetch all local items
            let itemDescriptor = FetchDescriptor<Item>()
            let localItems = try context.fetch(itemDescriptor)
            
            // Sync items to Firestore
            for item in localItems {
                let firestoreItem = FirestoreItem(from: item, userId: userId)
                await firestoreManager.saveItem(firestoreItem)
            }
            
            // Fetch all local days
            let dayDescriptor = FetchDescriptor<Day>()
            let localDays = try context.fetch(dayDescriptor)
            
            // Sync days to Firestore
            for day in localDays {
                let firestoreDay = FirestoreDay(from: day, userId: userId)
                await firestoreManager.saveDay(firestoreDay)
            }
            
            firestoreManager.syncStatus = .success
            print("Successfully synced \(localItems.count) items and \(localDays.count) days to cloud")
            
        } catch {
            firestoreManager.syncStatus = .error("Sync failed: \(error.localizedDescription)")
            print("Error syncing to cloud: \(error)")
        }
    }
    
    func syncCloudDataToLocal() async {
        guard cloudSyncEnabled, let context = modelContext else { return }
        
        // Fetch cloud data
        let cloudItems = await firestoreManager.fetchUserItems()
        let cloudDays = await firestoreManager.fetchUserDays()
        
        do {
            // Sync items from cloud to local
            for cloudItem in cloudItems {
                // Check if item already exists locally
                let itemDescriptor = FetchDescriptor<Item>(
                    predicate: #Predicate { $0.id == cloudItem.localId }
                )
                
                let existingItems = try context.fetch(itemDescriptor)
                
                if existingItems.isEmpty {
                    // Create new local item
                    let localItem = cloudItem.toSwiftDataItem()
                    context.insert(localItem)
                } else if let existingItem = existingItems.first {
                    // Update existing item if cloud version is newer
                    if cloudItem.lastUpdated > existingItem.lastUpdated {
                        existingItem.title = cloudItem.title
                        existingItem.lastUpdated = cloudItem.lastUpdated
                        existingItem.isHidden = cloudItem.isHidden
                    }
                }
            }
            
            try context.save()
            print("Successfully synced \(cloudItems.count) items from cloud to local")
            
        } catch {
            print("Error syncing from cloud to local: \(error)")
        }
    }
    
    func performBidirectionalSync() async {
        await syncAllLocalDataToCloud()
        await syncCloudDataToLocal()
    }
    
    // MARK: - Sharing Operations
    
    func createSharedList(name: String, items: [Item], description: String? = nil) async -> String? {
        guard cloudSyncEnabled, let userId = Auth.auth().currentUser?.uid else {
            // Prompt user to enable cloud sync for sharing
            return nil
        }
        
        let firestoreItems = items.map { FirestoreItem(from: $0, userId: userId) }
        return await firestoreManager.createSharedList(
            name: name,
            items: firestoreItems,
            description: description
        )
    }
    
    func loadSharedLists() async {
        guard cloudSyncEnabled else { return }
        await firestoreManager.loadSharedLists()
    }
    
    func shareList(listId: String, withUserId: String) async {
        guard cloudSyncEnabled else { return }
        await firestoreManager.shareList(listId: listId, withUserId: withUserId)
    }
    
    // MARK: - Computed Properties
    
    var sharedLists: [SharedList] {
        firestoreManager.sharedLists
    }
    
    var userPreferences: UserPreferences {
        firestoreManager.userPreferences
    }
    
    var shouldShowSyncStatus: Bool {
        firestoreManager.shouldShowSyncStatus
    }
    
    var syncStatusMessage: String {
        firestoreManager.syncStatusMessage
    }
    
    var syncStatusColor: Color {
        firestoreManager.syncStatusColor
    }
}
