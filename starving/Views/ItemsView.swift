import SwiftUI
import SwiftData

// MARK: - Quick Add Item Component
struct QuickAddItemBar: View {
    @Environment(\.modelContext) private var context
    @State private var itemName: String = ""
    @FocusState private var isTextFieldFocused: Bool
    var onItemAdded: () -> Void
    
    var body: some View {
        HStack {
            TextField("Add new item...", text: $itemName)
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .focused($isTextFieldFocused)
                .submitLabel(.done)
                .onSubmit(addItem)
            
            Button(action: addItem) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
            }
            .disabled(itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
        }
        .padding(.horizontal)
    }
    
    private func addItem() {
        let trimmedName = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let newItem = Item(title: trimmedName)
        context.insert(newItem)
        
        try? context.save()
        itemName = ""
        onItemAdded()
        
        // Add haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

// MARK: - Section Header
struct SectionHeaderView: View {
    let title: String
    let count: Int
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("\(count) items")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .padding(.bottom, 5)
    }
}

struct ItemsView: View {
    // MARK: - Properties
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var colorScheme
    
    @Query(filter: Day.currentDayPredicate(),
           sort: \.date) private var today: [Day]
    
    @Query(filter: #Predicate<Item> { $0.isHidden == false },
           sort: [SortDescriptor(\Item.title, order: .forward)])
    private var items: [Item]
    
    @State private var showAddView: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showError: Bool = false
    @State private var refreshTrigger: Bool = false
    
    private var showQuickAddBar: Bool {
        !items.isEmpty
    }
    
    // MARK: - View
    var body: some View {
        VStack(spacing: 20) {
            header
            messageView
            
            if showQuickAddBar {
                // Quick add bar for easy item entry
                QuickAddItemBar() {
                    refreshTrigger.toggle()
                }
            }
            
            if items.isEmpty {
                emptyStateView
            } else {
                itemsList
                
                if !showQuickAddBar {
                    addButton
                }
            }
        }
        .padding()
        .sheet(isPresented: $showAddView) {
            AddItemView()
                .presentationDetents([.fraction(0.3)])
        }
        .alert("Error", isPresented: $showError, presenting: errorMessage) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
        .onChange(of: errorMessage) { _, newValue in
            showError = newValue != nil
        }
    }
    
    // MARK: - View Components
    private var header: some View {
        Text("My groceries")
            .font(.largeTitle)
            .bold()
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var messageView: some View {
        Text("Never forget your weekly needs! Add groceries and select items to move them to the Today's tab.")
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image("items")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 300)
            
            ToolTipView(text: "Start by adding groceries you need for the week. Add items easily with the quick add bar above or the + button below.")
            
            addButton
            
            Spacer()
        }
    }
    
    private var itemsList: some View {
        List {
            ForEach(items) { item in
                ItemRow(item: item, isSelected: isItemSelected(item)) {
                    toggleItem(item)
                }
                .swipeActions(edge: .leading) {
                    Button(role: .destructive) {
                        deleteItem(item)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
    }
    
    private var addButton: some View {
        Button {
            showAddView.toggle()
        } label: {
            Text("Add New Item")
                .font(.headline)
                .primaryButtonStyle()
        }
        .padding(.horizontal)
    }
    
    // MARK: - Helper Methods
    private func isItemSelected(_ item: Item) -> Bool {
        getToday()?.items.contains(where: { $0.id == item.id }) ?? false
    }
    
    private func toggleItem(_ item: Item) {
        do {
            guard let today = getToday() else {
                throw NSError(domain: "ItemError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid data encountered"])
            }
            
            // Add haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            if let index = today.items.firstIndex(where: { $0.id == item.id }) {
                today.items.remove(at: index)
            } else {
                today.items.append(item)
            }
            
            try context.save()
        } catch {
            handleError(error)
        }
    }
    
    private func deleteItem(_ item: Item) {
        context.delete(item)
        try? context.save()
    }
    
    private func getToday() -> Day? {
        do {
            if let existingDay = today.first {
                return existingDay
            }
            
            let newDay = Day()
            context.insert(newDay)
            try context.save()
            return newDay
        } catch {
            handleError(error)
            return nil
        }
    }
    
    private func handleError(_ error: Error) {
        let message = error.localizedDescription
        
        DispatchQueue.main.async {
            self.errorMessage = message
            self.showError = true
        }
    }
}

#Preview {
    ItemsView()
}
