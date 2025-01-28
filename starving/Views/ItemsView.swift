import SwiftUI
import SwiftData

struct ItemsView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(filter: Day.currentDayPredicate(),
           sort: \.date) private var today: [Day]
    
    @Query(filter: #Predicate<Item> { $0.isHidden == false })
    private var items: [Item]
    
    @State private var showItemView = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Items")
                    .font(.largeTitle)
                    .bold()
                    .accessibilityAddTraits(.isHeader)
                
                Text("These are the items that you wanted to purchase. Now you can view and remember what you did your last time you went to shop!")
                    .fixedSize(horizontal: false, vertical: true)
                
                List(items) { item in
                    ItemRow(item: item, onCheckmark: {
                        addItemToToday(item)
                    })
                }
                .listStyle(.plain)
                .accessibilityLabel("Shopping items list")
                
                Spacer()
                
                Button(action: {
                    showItemView.toggle()
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add a New Item")
                    }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilityHint("Opens a form to add a new shopping item")
                
                Spacer()
            }
            .padding()
            .alert("Error", isPresented: $showError, presenting: errorMessage) { _ in
                Button("OK") {}
            } message: { message in
                Text(message)
            }
            .sheet(isPresented: $showItemView) {
                AddItemView()
                    .presentationDetents([.fraction(0.2)])
            }
        }
    }
    
    private func addItemToToday(_ item: Item) {
        do {
            let currentDay = try getToday()
            currentDay.item.append(item)
            try modelContext.save()
        } catch {
            errorMessage = "Failed to add item: \(error.localizedDescription)"
            showError = true
        }
    }
    
    private func getToday() throws -> Day {
        if let existingDay = today.first {
            return existingDay
        }
        
        let newDay = Day()
        modelContext.insert(newDay)
        try modelContext.save()
        return newDay
    }
}

private struct ItemRow: View {
    let item: Item
    let onCheckmark: () -> Void
    
    var body: some View {
        HStack {
            Text(item.title)
                .accessibilityLabel("Item: \(item.title)")
            
            Spacer()
            
            Button(action: onCheckmark) {
                Image(systemName: "checkmark.circle")
                    .foregroundColor(.blue)
            }
            .accessibilityLabel("Add \(item.title) to today's list")
        }
    }
}

#Preview {
    ItemsView()
}
