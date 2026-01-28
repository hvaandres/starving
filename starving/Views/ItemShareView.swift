//
//  ItemShareView.swift
//  starving
//
//  Created by Alan Haro on 1/19/26.
//

import SwiftUI
import SwiftData
import FirebaseAuth

struct ItemShareView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var firestoreManager = FirestoreManager()
    
    @Query(filter: #Predicate<Item> { $0.isHidden == false }, sort: [SortDescriptor(\Item.title, order: .forward)]) private var items: [Item]
    
    @State private var selectedItems: Set<String> = []
    @State private var isSharing = false
    @State private var shareItems: [Any] = []
    @State private var showShareSheet = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header info
                    VStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.up.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.indigo, Color.indigo.opacity(0.7)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        Text("Share Items")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Select items to share with others")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 24)
                    .padding(.horizontal, 20)
                    
                    // Items list
                    if items.isEmpty {
                        emptyStateView
                    } else {
                        itemsList
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Share") {
                        shareSelectedItems()
                    }
                    .disabled(selectedItems.isEmpty || isSharing)
                    .fontWeight(.semibold)
                }
            }
            .alert("Error", isPresented: $showError, presenting: errorMessage) { _ in
                Button("OK", role: .cancel) {}
            } message: { message in
                Text(message)
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: shareItems)
                    .presentationDetents([.medium, .large])
                    .onDisappear {
                        shareItems = []
                        isSharing = false
                    }
            }
        }
    }
    
    // MARK: - View Components
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "tray")
                .font(.system(size: 64))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("No items to share")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Add items to your list first")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
    
    private var itemsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(items) { item in
                    ShareableItemRow(
                        item: item,
                        isSelected: selectedItems.contains(item.id)
                    ) {
                        toggleItemSelection(item)
                    }
                    .padding(.horizontal, 20)
                    
                    if item.id != items.last?.id {
                        Divider()
                            .padding(.leading, 60)
                            .padding(.trailing, 20)
                            .opacity(0.3)
                    }
                }
            }
            .padding(.vertical, 8)
            
            // Selection summary
            if !selectedItems.isEmpty {
                VStack(spacing: 12) {
                    Text("\(selectedItems.count) item\(selectedItems.count == 1 ? "" : "s") selected")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 20)
                    
                    Button(action: selectAll) {
                        Text(selectedItems.count == items.count ? "Deselect All" : "Select All")
                            .font(.subheadline)
                            .foregroundColor(.indigo)
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func toggleItemSelection(_ item: Item) {
        if selectedItems.contains(item.id) {
            selectedItems.remove(item.id)
        } else {
            selectedItems.insert(item.id)
        }
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func selectAll() {
        if selectedItems.count == items.count {
            selectedItems.removeAll()
        } else {
            selectedItems = Set(items.map { $0.id })
        }
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func shareSelectedItems() {
        guard let currentUser = authManager.user else {
            errorMessage = "Not signed in"
            showError = true
            return
        }
        
        isSharing = true
        print("🚀 Starting share process...")
        
        Task {
            do {
                // Get selected items
                let itemsToShare = items.filter { selectedItems.contains($0.id) }
                let itemTitles = itemsToShare.map { $0.title }
                print("📦 Sharing \(itemTitles.count) items: \(itemTitles)")
                
                // Get user info
                let ownerName = currentUser.displayName ?? "Anonymous"
                let ownerPhotoURL = currentUser.photoURL?.absoluteString
                let ownerId = currentUser.uid
                print("👤 Owner: \(ownerName) (\(ownerId))")
                
                // Create shared list in Firestore for tracking
                print("📝 Creating Firestore document...")
                guard let listId = await firestoreManager.createSharedList(
                    name: "Shared Items - \(Date().formatted(date: .abbreviated, time: .shortened))",
                    itemIds: itemsToShare.map { $0.id },
                    itemTitles: itemTitles,
                    ownerName: ownerName,
                    ownerPhotoURL: ownerPhotoURL
                ) else {
                    print("❌ Failed to create shared list - createSharedList returned nil")
                    throw NSError(domain: "ShareError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create shared list. Check Firestore permissions and network connection."])
                }
                print("✅ Created shared list with ID: \(listId)")
                
                // Create JSON data with the Firestore list ID
                let shareData: [String: Any] = [
                    "listId": listId,
                    "items": itemTitles,
                    "ownerId": ownerId,
                    "ownerName": ownerName,
                    "ownerPhotoURL": ownerPhotoURL ?? "",
                    "sharedAt": ISO8601DateFormatter().string(from: Date())
                ]
                
                let jsonData = try JSONSerialization.data(withJSONObject: shareData, options: .prettyPrinted)
                
                // Create shareable text with embedded data  
                let base64Data = jsonData.base64EncodedString()
                let shareText = """
🛒 \(ownerName) shared \(itemTitles.count) grocery items with you!

📝 Items:
\(itemTitles.map { "  • \($0)" }.joined(separator: "\n"))

👆 Tap this link to open in Starving:
starving://import/\(listId)

✨ Items will be added automatically!
"""
                
                await MainActor.run {
                    print("✅ Created share text with \(itemTitles.count) items from \(ownerName)")
                    print("✅ Setting shareItems and showing sheet")
                    
                    shareItems = [shareText]
                    showShareSheet = true
                    isSharing = false
                    print("✅ showShareSheet = \(showShareSheet), shareItems count: \(shareItems.count)")
                }
            } catch {
                await MainActor.run {
                    isSharing = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Shareable Item Row
struct ShareableItemRow: View {
    let item: Item
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Checkbox
                ZStack {
                    Circle()
                        .fill(
                            isSelected
                                ? LinearGradient(
                                    colors: [Color.indigo, Color.indigo.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [Color.secondary.opacity(0.1), Color.secondary.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .stroke(
                                    isSelected ? Color.indigo.opacity(0.5) : Color.secondary.opacity(0.3),
                                    lineWidth: 2
                                )
                        )
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                
                // Item title
                Text(item.title)
                    .font(.system(size: 17))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Share Sheet Wrapper
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> ShareViewController {
        let controller = ShareViewController()
        controller.items = items
        controller.onDismiss = { dismiss() }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: ShareViewController, context: Context) {
        uiViewController.items = items
    }
}

class ShareViewController: UIViewController {
    var items: [Any] = []
    var onDismiss: (() -> Void)?
    private var activityViewController: UIActivityViewController?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard activityViewController == nil else { return }
        
        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        vc.completionWithItemsHandler = { [weak self] _, _, _, _ in
            self?.onDismiss?()
        }
        
        activityViewController = vc
        present(vc, animated: true)
    }
}

#Preview {
    ItemShareView()
}
