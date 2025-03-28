import SwiftUI
import SwiftData

struct TodayView: View {
    // MARK: - Properties
    @Environment(\.modelContext) private var context
    @Binding var selectedTab: Tab
    
    @Query(filter: Day.currentDayPredicate(),
           sort: \.date) private var today: [Day]
    
    @State private var completedItems: Set<String> = []
    @State private var showConfetti: Bool = false
    
    // MARK: - Computed Properties
    private var currentDay: Day {
        if let existingDay = today.first {
            return existingDay
        }
        
        let newDay = Day()
        context.insert(newDay)
        try? context.save()
        return newDay
    }
    
    private var hasItemsToday: Bool {
        !currentDay.items.filter { !$0.isHidden }.isEmpty
    }
    
    private var allItemsCompleted: Bool {
        let visibleItems = currentDay.items.filter { !$0.isHidden }
        return !visibleItems.isEmpty && completedItems.count == visibleItems.count
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 20) {
            header
            messageView
            
            if hasItemsToday {
                itemsList
                
                if !currentDay.items.isEmpty {
                    completeButton
                }
            } else {
                emptyStateView
            }
        }
        .padding()
        .overlay {
            if showConfetti {
                ConfettiView()
            }
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
        Text("Before you go, double-check your list! Swipe right to remove unpurchased items—they’ll stay in the Items tab.")
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var itemsList: some View {
        List {
            ForEach(currentDay.items.filter { !$0.isHidden }) { item in
                ItemRow(
                    item: item,
                    isSelected: completedItems.contains(item.id)
                ) {
                    toggleItemCompletion(item)
                }
                .swipeActions(edge: .leading) {
                    Button(role: .destructive) {
                        removeItem(item)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image("today")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 300)
            
            ToolTipView(text: "Take a little of your time to check and review your grocery list!")
            
            logButton
            
            Spacer()
        }
    }
    
    private var logButton: some View {
        Button {
            selectedTab = .items
        } label: {
            Text("Log")
                .font(.headline)
                .primaryButtonStyle()
        }
        .padding(.horizontal)
    }
    
    private var completeButton: some View {
        Button {
            completeList()
        } label: {
            Text("List Completed")
                .frame(maxWidth: .infinity)
                .padding()
                .background(allItemsCompleted ? Color.green : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .disabled(!allItemsCompleted)
        .padding(.horizontal)
    }
    
    // MARK: - Helper Methods
    private func toggleItemCompletion(_ item: Item) {
        if completedItems.contains(item.id) {
            completedItems.remove(item.id)
        } else {
            completedItems.insert(item.id)
        }
    }
    
    private func removeItem(_ item: Item) {
        if let index = currentDay.items.firstIndex(where: { $0.id == item.id }) {
            currentDay.items.remove(at: index)
            completedItems.remove(item.id)
            try? context.save()
        }
    }
    
    private func completeList() {
        showConfetti = true

        // Mark all items as hidden instead of removing them
        for item in currentDay.items {
            item.isHidden = true
        }

        // Save changes
        try? context.save()

        // Reset completed items
        completedItems.removeAll()

        // Hide confetti after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showConfetti = false
        }
    }
}

// MARK: - Confetti View
struct ConfettiView: View {
    @State private var isAnimating = false
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<50) { _ in
                Circle()
                    .fill(Color.random)
                    .frame(width: 10, height: 10)
                    .position(
                        x: .random(in: 0...geometry.size.width),
                        y: isAnimating ? geometry.size.height + 100 : -100
                    )
                    .animation(
                        Animation.linear(duration: .random(in: 2...4))
                            .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Color Extension
extension Color {
    static var random: Color {
        Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }
}
