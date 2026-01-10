//
//  SharingView.swift
//  starving
//
//  Created by Alan Haro on 1/10/25.
//

import SwiftUI
import SwiftData

struct SharingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject var hybridManager: HybridDataManager
    
    @Query(filter: Day.currentDayPredicate(), sort: \.date)
    private var today: [Day]
    
    @State private var listName: String = "My Shared List"
    @State private var userIdToShare: String = ""
    @State private var creating = false
    @State private var errorMessage: String?
    
    private var currentDay: Day? { today.first }
    private var visibleItemsToday: [Item] {
        guard let currentDay else { return [] }
        return currentDay.items.filter { !$0.isHidden }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient background
                Color.clear
                
                Form {
                Section("Create Shared List") {
                    TextField("List name", text: $listName)
                    Button {
                        Task { await createSharedList() }
                    } label: {
                        if creating { ProgressView() } else { Text("Create from today's items ((visibleItemsToday.count))") }
                    }
                    .disabled(creating || visibleItemsToday.isEmpty || !hybridManager.cloudSyncEnabled)
                    if let errorMessage { Text(errorMessage).foregroundColor(.red).font(.footnote) }
                    if !hybridManager.cloudSyncEnabled {
                        Text("Enable Cloud Sync in Settings to use sharing.")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }
                }
                
                Section("Your Shared Lists") {
                    if hybridManager.sharedLists.isEmpty {
                        Text("No shared lists yet")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(hybridManager.sharedLists) { list in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(list.name).font(.headline)
                                HStack(spacing: 12) {
                                    Text("Items: \(list.items.count)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    if !list.sharedWith.isEmpty {
                                        Text("Shared with: \(list.sharedWith.count)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                HStack {
                                    TextField("User ID to share with", text: $userIdToShare)
                                        .textInputAutocapitalization(.never)
                                        .disableAutocorrection(true)
                                    Button("Share") {
                                        Task { await share(listId: list.id, with: userIdToShare) }
                                    }
                                    .disabled((userIdToShare.isEmpty) || !hybridManager.cloudSyncEnabled)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .onAppear {
                            Task { await hybridManager.loadSharedLists() }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Sharing")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    if hybridManager.shouldShowSyncStatus {
                        HStack(spacing: 6) {
                            Circle().fill(hybridManager.syncStatusColor).frame(width: 8, height: 8)
                            Text(hybridManager.syncStatusMessage).font(.footnote)
                        }
                    }
                }
            }
        }
    }
    
    private func createSharedList() async {
        errorMessage = nil
        creating = true
        defer { creating = false }
        let id = await hybridManager.createSharedList(name: listName, items: visibleItemsToday, description: nil)
        if id == nil { errorMessage = "Failed to create shared list." } else {
            await hybridManager.loadSharedLists()
        }
    }
    
    private func share(listId: String?, with userId: String) async {
        guard let listId, !userId.isEmpty else { return }
        await hybridManager.shareList(listId: listId, withUserId: userId)
        await hybridManager.loadSharedLists()
        userIdToShare = ""
    }
}

#Preview {
    SharingView()
}

