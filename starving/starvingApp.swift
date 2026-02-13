//
//  starvingApp.swift
//  starving
//
//  Created by Alan Haro on 1/24/25.
//

import SwiftUI
import SwiftData
import FirebaseCore
import GoogleSignIn
import FirebaseAuth
import FirebaseFirestore

extension Notification.Name {
    static let sharedItemsImported = Notification.Name("sharedItemsImported")
    static let sharedItemsImportFailed = Notification.Name("sharedItemsImportFailed")
}

@main
struct StarvingApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    init() {
        // Enable verbose Firebase logging
        FirebaseConfiguration.shared.setLoggerLevel(.debug)
        
        FirebaseApp.configure()
        
        // Configure Firestore with memory-only cache to disable offline persistence
        let settings = FirestoreSettings()
        settings.cacheSettings = MemoryCacheSettings()
        Firestore.firestore().settings = settings
        print("✅ Firestore configured with memory-only cache (no offline persistence)")
        
        // Configure Google Sign-In
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let clientId = plist["CLIENT_ID"] as? String {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(hasCompletedOnboarding: $hasCompletedOnboarding)
                .modelContainer(for: [Item.self, Day.self])
                .withAuthentication()
        }
    }
}

struct ContentView: View {
    @Binding var hasCompletedOnboarding: Bool
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.modelContext) private var context
    @State private var pendingShareURL: URL?
    // DEBUG: Uncomment these to debug deep link handling
    // @State private var debugMessage: String = ""
    // @State private var showDebugAlert: Bool = false
    
    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnBoardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            } else if authManager.isRestoringSession {
                // Show loading while Firebase restores the persisted session
                ZStack {
                    Color.black.ignoresSafeArea()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            } else if !authManager.isSignedIn {
                LoginView(hasCompletedOnboarding: $hasCompletedOnboarding)
            } else {
                HomeView()
                    .onAppear {
                        if let url = pendingShareURL {
                            handleDeepLink(url)
                            pendingShareURL = nil
                        }
                    }
            }
        }
        // DEBUG: Uncomment this alert to debug deep link handling
        // .alert("Debug", isPresented: $showDebugAlert) {
        //     Button("OK", role: .cancel) { }
        // } message: {
        //     Text(debugMessage)
        // }
        .onOpenURL { url in
            // Handle Google Sign In URLs
            if url.scheme == "com.googleusercontent.apps.375815412704-e48jluq7lrdb1u1ogivqqc7j8f5hn446" {
                GIDSignIn.sharedInstance.handle(url)
            }
            // Handle Starving deep links
            else if url.scheme == "starving" {
                // DEBUG: Uncomment these to show debug alert
                // debugMessage = "Deep link received: \(url.absoluteString), signed in: \(authManager.isSignedIn)"
                // showDebugAlert = true
                if authManager.isSignedIn {
                    handleDeepLink(url)
                } else {
                    pendingShareURL = url
                }
            }
            // Handle grocery list file imports (.starvinglist or .json)
            else if url.pathExtension == "starvinglist" || url.pathExtension == "json" {
                if authManager.isSignedIn {
                    handleJSONFileImport(url)
                } else {
                    pendingShareURL = url
                }
            }
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        print("🔗 Deep link URL: \(url)")
        print("🔗 Path components: \(url.pathComponents)")
        print("🔗 Host: \(url.host ?? "none")")
        print("🔗 Path: \(url.path)")
        
        // For starving://import/listId, host is "import" and path is "/listId"
        if let host = url.host, host == "import" {
            let listId = String(url.path.dropFirst()) // Remove leading /
            print("🔗 Importing list: \(listId)")
            handleBase64Import(base64Data: listId)
            return
        }
        
        guard url.pathComponents.count >= 2 else { return }
        
        let action = url.pathComponents[1]
        
        switch action {
        case "share":
            if url.pathComponents.count >= 3 {
                let listId = url.pathComponents[2]
                handleSharedList(listId: listId)
            }
        case "import":
            if url.pathComponents.count >= 3 {
                let base64Data = url.pathComponents[2]
                handleBase64Import(base64Data: base64Data)
            }
        default:
            print("Unknown deep link action: \(action)")
        }
    }
    
    private func handleSharedList(listId: String) {
        print("📦 handleSharedList called with listId: \(listId)")
        guard let userId = authManager.user?.uid else {
            print("❌ No authenticated user")
            NotificationCenter.default.post(name: .sharedItemsImportFailed, object: nil, userInfo: ["error": "Please sign in to import shared items."])
            return
        }
        print("✅ Current user ID: \(userId)")
        
        Task { @MainActor in
            let db = Firestore.firestore()
            
            // Step 1: Fetch the shared list from Firestore
            print("🔍 Step 1: Fetching document from Firestore: sharedLists/\(listId)")
            let document: DocumentSnapshot
            do {
                document = try await db.collection("sharedLists").document(listId).getDocument()
            } catch {
                print("❌ Failed to fetch document: \(error)")
                NotificationCenter.default.post(name: .sharedItemsImportFailed, object: nil, userInfo: ["error": "Could not access shared list. Please check your internet connection."])
                return
            }
            
            print("📄 Document exists: \(document.exists)")
            
            // Step 2: Validate document data
            print("🔍 Step 2: Validating document data")
            guard document.exists else {
                print("❌ Document does not exist")
                NotificationCenter.default.post(name: .sharedItemsImportFailed, object: nil, userInfo: ["error": "Shared list not found. The link may be invalid or expired."])
                return
            }
            
            guard let data = document.data() else {
                print("❌ Document has no data")
                NotificationCenter.default.post(name: .sharedItemsImportFailed, object: nil, userInfo: ["error": "Shared list is empty or corrupted."])
                return
            }
            
            print("📄 Document data keys: \(data.keys)")
            
            guard let itemTitles = data["itemTitles"] as? [String], !itemTitles.isEmpty else {
                print("❌ No itemTitles in document or empty")
                NotificationCenter.default.post(name: .sharedItemsImportFailed, object: nil, userInfo: ["error": "Shared list contains no items."])
                return
            }
            
            guard let ownerId = data["ownerId"] as? String,
                  let ownerName = data["ownerName"] as? String else {
                print("❌ Missing owner information")
                NotificationCenter.default.post(name: .sharedItemsImportFailed, object: nil, userInfo: ["error": "Shared list is missing owner information."])
                return
            }
            
            print("✅ Found \(itemTitles.count) items from \(ownerName)")
            
            let ownerPhotoURL = data["ownerPhotoURL"] as? String
            let itemIds = data["itemIds"] as? [String] ?? []
            
            // Step 3: Try to update recipient tracking (non-critical - don't fail if this errors)
            print("🔍 Step 3: Updating recipient tracking (non-critical)")
            do {
                try await db.collection("sharedLists").document(listId).updateData([
                    "recipientIds": FieldValue.arrayUnion([userId]),
                    "lastUpdated": Date()
                ])
                print("✅ Recipient tracking updated")
            } catch {
                // This is expected to fail for non-owners due to Firestore rules
                // It's non-critical - we can still import the items
                print("⚠️ Could not update recipient tracking (expected for non-owners): \(error.localizedDescription)")
            }
            
            // Step 4: Create items in local database
            print("🔍 Step 4: Creating \(itemTitles.count) items in local database")
            var createdCount = 0
            for (index, itemTitle) in itemTitles.enumerated() {
                let newItem = Item(
                    title: itemTitle,
                    sharedById: ownerId,
                    sharedByName: ownerName,
                    sharedByPhotoURL: ownerPhotoURL,
                    sharedListId: listId
                )
                context.insert(newItem)
                createdCount += 1
                print("  ✏️ Created item: \(itemTitle) (sharedById: \(ownerId))")
            }
            
            // Step 5: Save to SwiftData
            print("🔍 Step 5: Saving to SwiftData")
            do {
                try context.save()
                print("✅ Successfully saved \(createdCount) shared items to SwiftData")
                
                // Haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
                // Notify UI to refresh
                print("📢 Posting sharedItemsImported notification with count: \(createdCount)")
                NotificationCenter.default.post(name: .sharedItemsImported, object: nil, userInfo: ["count": createdCount])
            } catch {
                print("❌ Error saving shared items to SwiftData: \(error)")
                NotificationCenter.default.post(name: .sharedItemsImportFailed, object: nil, userInfo: ["error": "Failed to save items locally: \(error.localizedDescription)"])
            }
        }
    }
    
    private func handleJSONFileImport(_ url: URL) {
        Task { @MainActor in
            do {
                // Read JSON file
                let jsonData = try Data(contentsOf: url)
                guard let shareData = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                      let itemTitles = shareData["items"] as? [String],
                      let ownerId = shareData["ownerId"] as? String,
                      let ownerName = shareData["ownerName"] as? String else {
                    print("Invalid JSON format")
                    return
                }
                
                let ownerPhotoURL = shareData["ownerPhotoURL"] as? String
                let listId = shareData["listId"] as? String ?? url.lastPathComponent
                
                // Report to Firestore that this user received the shared list
                if let currentUserId = Auth.auth().currentUser?.uid {
                    let db = Firestore.firestore()
                    try? await db.collection("sharedLists").document(listId).updateData([
                        "recipientIds": FieldValue.arrayUnion([currentUserId]),
                        "lastUpdated": Date()
                    ])
                }
                
                // Create items in local database with sharing metadata
                for itemTitle in itemTitles {
                    let newItem = Item(
                        title: itemTitle,
                        sharedById: ownerId,
                        sharedByName: ownerName,
                        sharedByPhotoURL: ownerPhotoURL,
                        sharedListId: listId
                    )
                    context.insert(newItem)
                }
                
                try context.save()
                
                // Haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
                // Notify UI to refresh
                print("📢 Posting sharedItemsImported notification (JSON) with count: \(itemTitles.count)")
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .sharedItemsImported, object: nil, userInfo: ["count": itemTitles.count])
                }
                
                print("✅ Successfully imported \(itemTitles.count) shared items from \(ownerName)")
                print("✅ Reported receipt to Firestore list: \(listId)")
            } catch {
                print("❌ Error importing JSON file: \(error)")
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .sharedItemsImportFailed, object: nil, userInfo: ["error": error.localizedDescription])
                }
            }
        }
    }
    
    private func handleBase64Import(base64Data: String) {
        // The base64Data is actually the listId
        let listId = base64Data
        handleSharedList(listId: listId)
    }
}
