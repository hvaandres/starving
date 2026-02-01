import SwiftUI
import SwiftData

struct TodayView: View {
    // MARK: - Properties
    @Environment(\.modelContext) private var context
    @Binding var selectedTab: Tab
    @StateObject private var firestoreManager = FirestoreManager()
    
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
    
    // Categorize items
    private var myItems: [Item] {
        currentDay.items.filter { !$0.isHidden && $0.sharedById == nil }
    }
    
    private var sharedWithMeItems: [Item] {
        currentDay.items.filter { !$0.isHidden && $0.sharedById != nil }
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header section
                VStack(spacing: 8) {
                    header
                    messageView
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)
                
                if hasItemsToday {
                    itemsList
                } else {
                    emptyStateView
                }
                
                // Complete button at bottom - only show when items are selected
                if hasItemsToday && !completedItems.isEmpty {
                    completeButton
                }
            }
        }
        .overlay {
            if showConfetti {
                ConfettiView()
            }
        }
    }
    
    // MARK: - View Components
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Today")
                    .font(.system(size: 32, weight: .bold))
                let visibleItems = currentDay.items.filter { !$0.isHidden }
                Text("\(visibleItems.count) item\(visibleItems.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }
    
    private var messageView: some View {
        Text("Select items for today's shopping")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var itemsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // My Items Section
                if !myItems.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        SectionHeaderView(title: "My Items", icon: "person.fill", color: .green)
                            .padding(.horizontal, 20)
                        
                        ForEach(myItems) { item in
                            TodayItemRow(
                                item: item,
                                isCompleted: completedItems.contains(item.id),
                                onToggle: { toggleItemCompletion(item) },
                                onDelete: { removeItem(item) },
                                accentColor: .green
                            )
                            .padding(.horizontal, 20)
                        }
                    }
                }
                
                // Shared With Me Section
                if !sharedWithMeItems.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        SectionHeaderView(title: "Shared With Me", icon: "person.2.fill", color: .blue)
                            .padding(.horizontal, 20)
                        
                        ForEach(sharedWithMeItems) { item in
                            SharedItemRow(
                                item: item,
                                isCompleted: completedItems.contains(item.id),
                                onToggle: { 
                                    toggleItemCompletion(item)
                                    updateSharedItemCompletion(item)
                                },
                                onDelete: { removeItem(item) }
                            )
                            .padding(.horizontal, 20)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon with gradient
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.blue.opacity(0.15),
                                Color.blue.opacity(0.05),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                
                Image(systemName: "list.clipboard.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .padding(.bottom, 8)
            
            // Title and description
            VStack(spacing: 12) {
                Text("No items for today")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Add items from your groceries list to start shopping")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.bottom, 32)
            
            // Action button
            logButton
            
            Spacer()
        }
    }
    
    private var logButton: some View {
        Button(action: {
            selectedTab = .items
        }) {
            HStack(spacing: 8) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 15))
                Text("Add Items")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: Color.blue.opacity(0.3), radius: 12, x: 0, y: 6)
            )
        }
    }
    
    private var completeButton: some View {
        Button(action: {
            completeList()
        }) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                Text("Complete Shopping")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: allItemsCompleted 
                                ? [Color.green, Color.green.opacity(0.85)]
                                : [Color.secondary.opacity(0.3), Color.secondary.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Capsule()
                            .stroke(
                                Color.white.opacity(allItemsCompleted ? 0.3 : 0.15),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: allItemsCompleted ? Color.green.opacity(0.3) : Color.black.opacity(0.1), radius: 12, x: 0, y: 6)
            )
        }
        .disabled(!allItemsCompleted)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
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
            
            // Update completion status for shared items
            if let sharedListId = item.sharedListId, let userId = firestoreManager.userPreferences.shareEnabled ? "userId" : nil {
                Task {
                    await firestoreManager.updateCompletionStatus(listId: sharedListId, recipientId: userId, completed: true)
                }
            }
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
    
    private func updateSharedItemCompletion(_ item: Item) {
        guard let sharedListId = item.sharedListId else { return }
        
        Task {
            // Get current user ID from AuthManager (we'll need to access it)
            // For now, we'll update based on completion status
            let allSharedItemsFromList = sharedWithMeItems.filter { $0.sharedListId == sharedListId }
            let completedCount = allSharedItemsFromList.filter { completedItems.contains($0.id) }.count
            let allCompleted = completedCount == allSharedItemsFromList.count
            
            // Update in Firestore (would need actual user ID from auth)
            // await firestoreManager.updateCompletionStatus(listId: sharedListId, recipientId: userId, completed: allCompleted)
        }
    }
}

// MARK: - Enhanced Confetti View
struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var explosionTriggered = false
    
    var body: some View {
        ZStack {
            // Success glow burst
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.green.opacity(explosionTriggered ? 0 : 0.6),
                            Color.green.opacity(0)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: explosionTriggered ? 500 : 50
                    )
                )
                .scaleEffect(explosionTriggered ? 3 : 0.5)
                .opacity(explosionTriggered ? 0 : 1)
                .animation(.easeOut(duration: 0.8), value: explosionTriggered)
                .allowsHitTesting(false)
            
            // Confetti particles
            ForEach(particles) { particle in
                ParticleView(particle: particle)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            generateParticles()
            withAnimation {
                explosionTriggered = true
            }
        }
    }
    
    private func generateParticles() {
        particles = (0..<100).map { index in
            ConfettiParticle(
                id: index,
                shape: ConfettiShape.allCases.randomElement()!,
                color: ConfettiColor.allCases.randomElement()!.color,
                size: CGFloat.random(in: 8...16),
                startX: CGFloat.random(in: -200...200),
                startY: CGFloat.random(in: -800...(-400)),
                velocityX: CGFloat.random(in: -200...200),
                velocityY: CGFloat.random(in: 400...800),
                rotation: CGFloat.random(in: 0...360),
                rotationSpeed: CGFloat.random(in: -720...720),
                delay: Double.random(in: 0...0.5)
            )
        }
    }
}

// MARK: - Confetti Particle Model
struct ConfettiParticle: Identifiable {
    let id: Int
    let shape: ConfettiShape
    let color: Color
    let size: CGFloat
    let startX: CGFloat
    let startY: CGFloat
    let velocityX: CGFloat
    let velocityY: CGFloat
    let rotation: CGFloat
    let rotationSpeed: CGFloat
    let delay: Double
}

enum ConfettiShape: CaseIterable {
    case circle, square, triangle, star, heart
}

enum ConfettiColor: CaseIterable {
    case red, orange, yellow, green, blue, purple, pink
    
    var color: Color {
        switch self {
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .blue: return .blue
        case .purple: return .purple
        case .pink: return .pink
        }
    }
}

// MARK: - Particle View
struct ParticleView: View {
    let particle: ConfettiParticle
    @State private var offsetX: CGFloat = 0
    @State private var offsetY: CGFloat = 0
    @State private var rotation: CGFloat = 0
    @State private var opacity: Double = 1
    @State private var scale: CGFloat = 1
    
    var body: some View {
        GeometryReader { geometry in
            Group {
                switch particle.shape {
                case .circle:
                    Circle()
                        .fill(particle.color)
                case .square:
                    RoundedRectangle(cornerRadius: 2)
                        .fill(particle.color)
                case .triangle:
                    Triangle()
                        .fill(particle.color)
                case .star:
                    Star()
                        .fill(particle.color)
                case .heart:
                    Heart()
                        .fill(particle.color)
                }
            }
            .frame(width: particle.size, height: particle.size)
            .rotationEffect(.degrees(rotation))
            .scaleEffect(scale)
            .opacity(opacity)
            .position(
                x: geometry.size.width / 2 + offsetX,
                y: geometry.size.height / 2 + offsetY
            )
            .shadow(color: particle.color.opacity(0.6), radius: 4, x: 0, y: 2)
            .onAppear {
                animateParticle()
            }
        }
    }
    
    private func animateParticle() {
        // Initial position at top of screen
        offsetX = particle.startX
        offsetY = particle.startY
        rotation = particle.rotation
        
        // Physics-based animation with gravity falling from top
        withAnimation(
            .timingCurve(0.25, 0.1, 0.25, 1, duration: 3.5)
            .delay(particle.delay)
        ) {
            // Horizontal movement (drifting left/right as it falls)
            offsetX = particle.startX + particle.velocityX * 0.6
            
            // Vertical movement (falls down from top to bottom)
            offsetY = particle.startY + particle.velocityY * 2.5
            
            // Rotation
            rotation = particle.rotation + particle.rotationSpeed * 3
            
            // Fade out near the end
            opacity = 0
        }
        
        // Scale pulse at the beginning
        withAnimation(
            .spring(response: 0.3, dampingFraction: 0.5)
            .delay(particle.delay)
        ) {
            scale = 1.3
        }
        
        withAnimation(
            .easeOut(duration: 0.4)
            .delay(particle.delay + 0.2)
        ) {
            scale = 1.0
        }
    }
}

// MARK: - Custom Shapes
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct Star: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * 0.4
        let angle = CGFloat.pi / 5
        
        for i in 0..<10 {
            let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius
            let x = center.x + radius * cos(CGFloat(i) * angle - CGFloat.pi / 2)
            let y = center.y + radius * sin(CGFloat(i) * angle - CGFloat.pi / 2)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
}

struct Heart: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: width * 0.5, y: height * 0.3))
        path.addCurve(
            to: CGPoint(x: width * 0.1, y: height * 0.2),
            control1: CGPoint(x: width * 0.5, y: height * 0.15),
            control2: CGPoint(x: width * 0.2, y: height * 0.05)
        )
        path.addArc(
            center: CGPoint(x: width * 0.2, y: height * 0.3),
            radius: width * 0.15,
            startAngle: .degrees(225),
            endAngle: .degrees(45),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.9))
        path.addLine(to: CGPoint(x: width * 0.8, y: height * 0.45))
        path.addArc(
            center: CGPoint(x: width * 0.8, y: height * 0.3),
            radius: width * 0.15,
            startAngle: .degrees(135),
            endAngle: .degrees(315),
            clockwise: false
        )
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height * 0.3),
            control1: CGPoint(x: width * 0.8, y: height * 0.05),
            control2: CGPoint(x: width * 0.5, y: height * 0.15)
        )
        return path
    }
}

// MARK: - Section Header View
struct SectionHeaderView: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Today Item Row
struct TodayItemRow: View {
    let item: Item
    let isCompleted: Bool
    let onToggle: () -> Void
    let onDelete: () -> Void
    var accentColor: Color = .blue
    
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Checkbox button
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                onToggle()
            }) {
                ZStack {
                    Circle()
                        .fill(
                            isCompleted 
                                ? LinearGradient(
                                    colors: [accentColor, accentColor.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [Color.secondary.opacity(0.1), Color.secondary.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .stroke(
                                    isCompleted ? accentColor.opacity(0.5) : Color.secondary.opacity(0.3),
                                    lineWidth: 2
                                )
                        )
                    
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCompleted)
            }
            .buttonStyle(PlainButtonStyle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
            
            // Item title
            Text(item.title)
                .font(.system(size: 17))
                .foregroundColor(isCompleted ? .secondary : .primary)
                .strikethrough(isCompleted, color: .secondary)
                .animation(.easeInOut(duration: 0.2), value: isCompleted)
            
            Spacer()
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
            .swipeActions(edge: .leading) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Shared Item Row
struct SharedItemRow: View {
    let item: Item
    let isCompleted: Bool
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Checkbox button
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                onToggle()
            }) {
                ZStack {
                    Circle()
                        .fill(
                            isCompleted 
                                ? LinearGradient(
                                    colors: [Color.blue, Color.blue.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [Color.secondary.opacity(0.1), Color.secondary.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .stroke(
                                    isCompleted ? Color.blue.opacity(0.5) : Color.secondary.opacity(0.3),
                                    lineWidth: 2
                                )
                        )
                    
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCompleted)
            }
            .buttonStyle(PlainButtonStyle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
            
            // Item content with sender info
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.system(size: 17))
                    .foregroundColor(isCompleted ? .secondary : .primary)
                    .strikethrough(isCompleted, color: .secondary)
                
                // Sender info
                HStack(spacing: 6) {
                    // Profile picture or placeholder
                    if let photoURL = item.sharedByPhotoURL, let url = URL(string: photoURL) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 8))
                                        .foregroundColor(.blue)
                                )
                        }
                        .frame(width: 20, height: 20)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.blue.opacity(0.3), lineWidth: 1))
                    } else {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 20, height: 20)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(.blue)
                            )
                            .overlay(Circle().stroke(Color.blue.opacity(0.3), lineWidth: 1))
                    }
                    
                    Text("from \(item.sharedByName ?? "Unknown")")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Completion badge
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.2), value: isCompleted)
        .swipeActions(edge: .leading) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
