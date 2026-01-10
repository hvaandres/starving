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
        ZStack {
            // Enhanced glass container with shimmer
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    // Inner shimmer layer
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.15),
                                    Color.clear,
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .padding(1)
                )
                .overlay(
                    // Border with glass effect
                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: Color.black.opacity(0.25), radius: 30, x: 0, y: 15)
                .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
            
            // Tab buttons
            HStack(spacing: 20) {
                ForEach(tabs, id: \.self) { tab in
                    TabBarButton(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        isHovered: hoveredTab == tab,
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = tab
                            }
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                        },
                        onHover: { hovering in
                            hoveredTab = hovering ? tab : nil
                        }
                    )
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 18)
        }
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
    @State private var glowPulse: CGFloat = 1.0
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Magnifying lens background for selected tab
                if isSelected {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    tab.color.opacity(0.5),
                                    tab.color.opacity(0.3),
                                    tab.color.opacity(0.15),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 35
                            )
                        )
                        .frame(width: 60, height: 60)
                        .blur(radius: 8)
                        .scaleEffect(glowPulse)
                        .opacity(0.9)
                }
                
                // Glass circle behind icon (magnifying effect)
                if isSelected {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 48, height: 48)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            tab.color.opacity(0.6),
                                            tab.color.opacity(0.3)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .overlay(
                            // Inner light reflection
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.3),
                                            Color.clear
                                        ],
                                        startPoint: .top,
                                        endPoint: .center
                                    )
                                )
                                .padding(2)
                        )
                        .shadow(color: tab.color.opacity(0.4), radius: 12, x: 0, y: 4)
                }
                
                // Subtle glow for hover
                if isHovered && !isSelected {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    tab.color.opacity(0.3),
                                    tab.color.opacity(0.15),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 25
                            )
                        )
                        .frame(width: 50, height: 50)
                        .blur(radius: 6)
                }
                
                // Icon
                Image(systemName: tab.iconName)
                    .font(.system(size: isSelected ? 24 : 22, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? tab.color : .white.opacity(0.6))
                    .scaleEffect(isPressed ? 0.85 : (isHovered && !isSelected ? 1.1 : 1.0))
                    .shadow(color: isSelected ? tab.color.opacity(0.5) : Color.clear, radius: 8, x: 0, y: 2)
            }
            .frame(width: 48, height: 48)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
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
        .onAppear {
            if isSelected {
                startPulseAnimation()
            }
        }
        .onChange(of: isSelected) { newValue in
            if newValue {
                startPulseAnimation()
            }
        }
    }
    
    private func startPulseAnimation() {
        withAnimation(
            .easeInOut(duration: 2.0)
            .repeatForever(autoreverses: true)
        ) {
            glowPulse = 1.15
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
