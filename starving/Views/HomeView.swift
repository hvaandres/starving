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
        HStack(spacing: 16) {
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
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
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
    @State private var glowIntensity: Double = 0
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Background circle
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 56, height: 56)
                
                // Lensing glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                tab.color.opacity(isSelected ? 0.6 : 0.3),
                                tab.color.opacity(isSelected ? 0.3 : 0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: isHovered ? 40 : 30
                        )
                    )
                    .frame(width: 56, height: 56)
                    .opacity(isSelected || isHovered ? 1 : 0)
                    .scaleEffect(isSelected || isHovered ? 1.0 + glowIntensity : 1.0)
                
                // Icon
                Image(systemName: tab.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? tab.color : .primary.opacity(0.6))
                    .scaleEffect(isPressed ? 0.85 : (isHovered ? 1.2 : 1.0))
                    .rotationEffect(.degrees(isPressed ? 5 : 0))
            }
            .overlay(
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: isSelected ? [
                                tab.color.opacity(0.6),
                                tab.color.opacity(0.3)
                            ] : [
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isSelected ? 2 : 1
                    )
                    .frame(width: 56, height: 56)
            )
            .shadow(color: isSelected ? tab.color.opacity(0.4) : Color.black.opacity(0.1), 
                    radius: isSelected ? 12 : 4, x: 0, y: isSelected ? 6 : 2)
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
                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
                ) {
                    glowIntensity = 0.15
                }
            }
        }
        .onChange(of: isSelected) { newValue in
            if newValue {
                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
                ) {
                    glowIntensity = 0.15
                }
            } else {
                glowIntensity = 0
            }
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
