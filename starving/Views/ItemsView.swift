import SwiftUI
import SwiftData

// MARK: - Custom Error
enum ItemError: LocalizedError {
    case saveFailed
    case loadFailed
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "Failed to save changes"
        case .loadFailed:
            return "Failed to load your items"
        case .invalidData:
            return "Invalid data encountered"
        }
    }
}

// MARK: - ToolTipView
struct ToolTipView: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
            )
            .padding(.horizontal)
    }
}

struct ItemsView: View {
    // MARK: - Properties
    @Environment(\.modelContext) private var context
    
    @Query(filter: Day.currentDayPredicate(),
           sort: \.date) private var today: [Day]
    
    @Query(filter: #Predicate<Item> { $0.isHidden == false })
    private var items: [Item]
    
    @State private var showAddView: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showError: Bool = false
    
    // MARK: - View
    var body: some View {
        VStack(spacing: 20) {
            header
            
            if items.isEmpty {
                emptyStateView
            } else {
                itemsList
            }
            
            Spacer()
            
            addButton
            
            Spacer()
        }
        .sheet(isPresented: $showAddView) {
            AddItemView()
                .presentationDetents([.fraction(0.2)])
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
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("My Groceries")
                .font(.largeTitle)
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("Never forget what you need for the week again!")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal)
    }
    
    private var emptyStateView: some View {
        VStack {
            Image("items")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 300)
            
            ToolTipView(text: "Begin by adding groceries you think would be perfect for the week!")
        }
    }
    
    private var itemsList: some View {
        List(items) { item in
            ItemRow(item: item, isSelected: isItemSelected(item)) {
                toggleItem(item)
            }
        }
        .listStyle(.plain)
    }
    
    private var addButton: some View {
        Button(action: { showAddView.toggle() }) {
            Text("Add New Item")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .padding(.horizontal)
    }
    
    private func isItemSelected(_ item: Item) -> Bool {
        getToday()?.items.contains(where: { $0.id == item.id }) ?? false
    }
    
    private func toggleItem(_ item: Item) {
        do {
            guard let today = getToday() else {
                throw ItemError.invalidData
            }
            
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
        let message: String
        if let itemError = error as? ItemError {
            message = itemError.errorDescription ?? "An unknown error occurred"
        } else {
            message = error.localizedDescription
        }
        
        DispatchQueue.main.async {
            self.errorMessage = message
            self.showError = true
        }
    }
}


#Preview {
    ItemsView()
}
