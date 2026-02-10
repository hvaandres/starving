import SwiftUI

struct HomeView: View {
    @State private var selectedTab: Tab = .today
    @State private var showAddItem: Bool = false
    @State private var showImportSuccess: Bool = false
    @State private var importedCount: Int = 0
    @State private var showImportError: Bool = false
    @State private var importErrorMessage: String = ""
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView(selectedTab: $selectedTab)
                .tag(Tab.today)
                .tabItem {
                    Label("Today", systemImage: "square.and.pencil")
                }
            
            ItemsView(showAddInput: $showAddItem)
                .tag(Tab.items)
                .tabItem {
                    Label("Items", systemImage: "carrot")
                }
            
            RemindersView()
                .tag(Tab.reminders)
                .tabItem {
                    Label("Reminders", systemImage: "bell.and.waves.left.and.right")
                }
            
            SettingsView()
                .tag(Tab.settings)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(selectedTab.color)
        .overlay(alignment: .bottomTrailing) {
            // Liquid Glass floating add button (only for Items tab)
            if selectedTab == .items {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showAddItem = true
                    }
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.green,
                                    Color.green.opacity(0.8)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 56, height: 56)
                }
                .background(
                    ZStack {
                        // Liquid glass effect matching iOS 26 design
                        Circle()
                            .fill(.ultraThinMaterial)
                        
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.green.opacity(0.2),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: 40
                                )
                            )
                        
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                )
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
                .shadow(color: Color.green.opacity(0.2), radius: 15, x: 0, y: 8)
                .padding(.trailing, 20)
                .padding(.bottom, 90)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .sharedItemsImported)) { notification in
            if let count = notification.userInfo?["count"] as? Int {
                importedCount = count
                showImportSuccess = true
                // Navigate to Items tab to show imported items
                withAnimation {
                    selectedTab = .items
                }
            }
        }
        .alert("Items Imported!", isPresented: $showImportSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\(importedCount) item\(importedCount == 1 ? " has" : "s have") been added to your grocery list.")
        }
        .onReceive(NotificationCenter.default.publisher(for: .sharedItemsImportFailed)) { notification in
            if let error = notification.userInfo?["error"] as? String {
                importErrorMessage = error
                showImportError = true
            }
        }
        .alert("Import Failed", isPresented: $showImportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importErrorMessage)
        }
    }
}

// MARK: - Tab Extension
extension Tab {
    var iconName: String {
        switch self {
        case .today: return "square.and.pencil"
        case .items: return "carrot"
        case .reminders: return "bell.and.waves.left.and.right"
        case .settings: return "gearshape"
        }
    }
    
    var label: String {
        switch self {
        case .today: return "Today"
        case .items: return "Items"
        case .reminders: return "Reminders"
        case .settings: return "Settings"
        }
    }
    
    var color: Color {
        switch self {
        case .today: return .blue
        case .items: return .green
        case .reminders: return .orange
        case .settings: return .purple
        }
    }
}

#Preview {
    HomeView()
}
