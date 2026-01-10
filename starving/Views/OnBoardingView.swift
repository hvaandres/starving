import SwiftUI

struct OnBoardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Black background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Icon
                Image(systemName: "cart.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .padding(.bottom, 40)
                
                // Title and description
                VStack(spacing: 16) {
                    Text("Welcome to Starving")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Stay organized with your grocery lists. Never forget what you need.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.bottom, 60)
                
                // Get started button
                GetStartedButton(action: completeOnboarding)
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
    
    private func completeOnboarding() {
        hasCompletedOnboarding = true
    }
}

struct GetStartedButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("Get Started")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: Color.accentColor.opacity(0.4), radius: 12, x: 0, y: 6)
                )
        }
        .padding(.horizontal, 20)
        .buttonStyle(PlainButtonStyle())
    }
}



#Preview {
    @State var hasCompletedOnboarding = false
    return OnBoardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
}
