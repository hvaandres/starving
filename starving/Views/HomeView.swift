import SwiftUI

struct HomeView: View {
    @State private var selectedTab: Tab = .today
    @State private var hoveredTab: Tab? = nil
    @State private var dragOffset: CGFloat = 0
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: colorScheme == .dark
                    ? [Color(red: 0.1, green: 0.1, blue: 0.15), Color(red: 0.15, green: 0.15, blue: 0.2)]
                    : [Color(red: 0.95, green: 0.96, blue: 0.98), Color(red: 0.88, green: 0.9, blue: 0.95)]
                ),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Content area
            ZStack {
                // Tab content
                Group {
                    switch selectedTab {
                    case .today:
                        TodayView(selectedTab: $selectedTab)
                            .transition(.opacity)
                    case .items:
                        ItemsView()
                            .transition(.opacity)
                    case .reminders:
                        RemindersView()
                            .transition(.opacity)
                    case .settings:
                        SettingsView()
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: selectedTab)
                
                // Floating tab bar
                FloatingTabBar(
                    selectedTab: $selectedTab,
                    hoveredTab: $hoveredTab
                )
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        handleSwipe(value.translation.width)
                        dragOffset = 0
                    }
            )
        }
        .onAppear {
            setupTabBarAppearance()
        }
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    private func handleSwipe(_ width: CGFloat) {
        let threshold: CGFloat = 30
        
        if width > threshold {
            // Swipe right - previous tab
            switch selectedTab {
            case .items: selectedTab = .today
            case .reminders: selectedTab = .items
            case .settings: selectedTab = .reminders
            default: break
            }
        } else if width < -threshold {
            // Swipe left - next tab
            switch selectedTab {
            case .today: selectedTab = .items
            case .items: selectedTab = .reminders
            case .reminders: selectedTab = .settings
            default: break
            }
        }
    }
}

// MARK: - Floating Tab Bar
struct FloatingTabBar: View {
    @Binding var selectedTab: Tab
    @Binding var hoveredTab: Tab?
    
    let tabs: [Tab] = [.today, .items, .reminders, .settings]
    @State private var draggedTab: Tab? = nil
    @State private var isDragging = false
    
    var body: some View {
        GeometryReader { containerGeometry in
            HStack(spacing: 8) {
                ForEach(Array(tabs.enumerated()), id: \.element) { index, tab in
                    TabBarButton(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        isMagnified: draggedTab == tab && isDragging,
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = tab
                            }
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                        }
                    )
                    .frame(width: 48, height: 48)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        // Calculate which tab is under the finger
                        let x = value.location.x - 8 // Account for padding
                        let tabWidth: CGFloat = 56 // 48 + 8 spacing
                        let index = Int(x / tabWidth)
                        
                        if index >= 0 && index < tabs.count {
                            let newTab = tabs[index]
                            if draggedTab != newTab {
                                draggedTab = newTab
                                let generator = UISelectionFeedbackGenerator()
                                generator.selectionChanged()
                            }
                        }
                    }
                    .onEnded { _ in
                        isDragging = false
                        draggedTab = nil
                    }
            )
        }
        .frame(height: 48)
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            ZStack {
                // Blur effect
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)
                    .opacity(0.7)
                
                // Subtle gradient overlay for depth
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.08),
                                Color.white.opacity(0.02)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                // Border
                RoundedRectangle(cornerRadius: 28)
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
            .shadow(color: Color.black.opacity(0.15), radius: 25, x: 0, y: 12)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .padding(.leading, 20)
        .padding(.bottom, 20)
    }
}

// MARK: - Tab Bar Button
struct TabBarButton: View {
    let tab: Tab
    let isSelected: Bool
    let isMagnified: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: tab.iconName)
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(isSelected ? tab.color : .white.opacity(0.7))
                .scaleEffect(isMagnified ? 1.3 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isMagnified)
                .frame(width: 48, height: 48)
                .background(
                    ZStack {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(tab.color.opacity(0.18))
                            
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.15),
                                            Color.clear
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }
                    }
                )
        }
        .buttonStyle(PlainButtonStyle())
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
