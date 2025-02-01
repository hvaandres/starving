//
//  TodayView.swift
//  starving
//
//  Created by Alan Haro on 1/24/25.
//
import SwiftUI
import SwiftData

struct TodayView: View {
    // MARK: - Properties
    @Environment(\.modelContext) private var context
    @Binding var selectedTab: Tab
    
    @Query(filter: Day.currentDayPredicate(),
           sort: \.date) private var today: [Day]
    
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
        !currentDay.items.isEmpty
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 20) {
            header
            messageView
            
            if hasItemsToday {
                itemsList
            } else {
                emptyStateView
            }
        }
        .padding()
    }
    
    // MARK: - View Components
    private var header: some View {
        Text("My groceries")
            .font(.largeTitle)
            .bold()
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var messageView: some View {
        Text("Don't forget to check one more time if this is all you needed for today or for the week")
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var itemsList: some View {
        List(currentDay.items.filter { !$0.isHidden }) { item in
            Text(item.title)
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
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }
}

// MARK: - Preview
#Preview {
    TodayView(selectedTab: .constant(.today))
        .modelContainer(for: [Day.self, Item.self])
}
