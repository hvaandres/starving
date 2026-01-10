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
    
    var body: some View {
        HStack(spacing: 24) {
            ForEach(tabs, id: \.self) { tab in
                TabBarButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    isHovered: hoveredTab == tab,
                    action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = tab
                        }
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    },
                    onHover: { hovering in
                        hoveredTab = hovering ? tab : nil
                    }
                )
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .opacity(0.95)
                .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
                .overlay(
                    Capsule()
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
                )
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
    let isHovered: Bool
    let action: () -> Void
    let onHover: (Bool) -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: tab.iconName)
                .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? tab.color : .white.opacity(0.6))
                .scaleEffect(isPressed ? 0.85 : (isHovered ? 1.15 : 1.0))
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                    onHover(true)
                }
                .onEnded { _ in
                    isPressed = false
                    onHover(false)
                }
        )
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
