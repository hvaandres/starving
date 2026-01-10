import SwiftUI
import SwiftData

struct ItemsView: View {
    // MARK: - Properties
    @Environment(\.modelContext) private var context
    
    @Query(filter: Day.currentDayPredicate(), sort: \.date) private var today: [Day]
    @Query(filter: #Predicate<Item> { $0.isHidden == false }, sort: [SortDescriptor(\Item.title, order: .forward)]) private var items: [Item]
    
    @State private var showAddInput: Bool = false
    @State private var newItemTitle: String = ""
    @State private var errorMessage: String? = nil
    @State private var showError: Bool = false
    @FocusState private var isInputFocused: Bool
    
    // MARK: - View
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                // Header section
                VStack(spacing: 8) {
                    header
                    messageView
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)
                
                // Inline add input
                if showAddInput {
                    addInputField
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                }
                
                if items.isEmpty {
                    emptyStateView
                } else {
                    itemsList
                }
            }
            
            // Floating + button
            if !items.isEmpty {
                floatingAddButton
            }
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
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Items")
                    .font(.system(size: 32, weight: .bold))
                Text("\(items.count) item\(items.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }
    
    private var messageView: some View {
        Text("Add groceries and select to move to Today")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var addInputField: some View {
        HStack(spacing: 12) {
            // Input field
            HStack(spacing: 12) {
                Image(systemName: "cart.badge.plus")
                    .font(.system(size: 18))
                    .foregroundColor(.green)
                
                TextField("Add grocery item...", text: $newItemTitle)
                    .font(.system(size: 16))
                    .focused($isInputFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        addNewItem()
                    }
                
                if !newItemTitle.isEmpty {
                    Button(action: { 
                        newItemTitle = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.green.opacity(0.4),
                                        Color.green.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
            )
            .shadow(color: Color.green.opacity(0.15), radius: 8, x: 0, y: 4)
            
            // Action buttons
            HStack(spacing: 8) {
                // Add button
                Button(action: { addNewItem() }) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.green, Color.green.opacity(0.85)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(newItemTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(newItemTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
                
                // Cancel button
                Button(action: { 
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showAddInput = false
                        newItemTitle = ""
                        isInputFocused = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.green.opacity(0.15),
                                Color.green.opacity(0.05),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                
                Image(systemName: "cart.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.green, Color.green.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .padding(.bottom, 8)
            
            VStack(spacing: 12) {
                Text("No items yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Start adding your grocery items")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.bottom, 32)
            
            Button(action: { 
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showAddInput = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isInputFocused = true
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 15))
                    Text("Add Item")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.green, Color.green.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1))
                        .shadow(color: Color.green.opacity(0.3), radius: 12, x: 0, y: 6)
                )
            }
            
            Spacer()
        }
    }
    
    private var itemsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(items) { item in
                    ItemRow(item: item, isSelected: isItemSelected(item)) {
                        toggleItem(item)
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
            .padding(.bottom, 80)
        }
    }
    
    private var floatingAddButton: some View {
        Button(action: { 
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showAddInput = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isInputFocused = true
            }
        }) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 56, height: 56)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.green.opacity(0.6),
                                Color.green.opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 35
                        )
                    )
                    .frame(width: 56, height: 56)
                
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }
            .overlay(
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .frame(width: 56, height: 56)
            )
            .shadow(color: Color.green.opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
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
    
    private func addNewItem() {
        let cleanedTitle = newItemTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedTitle.isEmpty else { return }
        
        let newItem = Item(title: cleanedTitle)
        context.insert(newItem)
        
        do {
            try context.save()
            
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            // Reset and close
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                newItemTitle = ""
                showAddInput = false
                isInputFocused = false
            }
        } catch {
            handleError(error)
        }
    }
}

#Preview {
    ItemsView()
}
