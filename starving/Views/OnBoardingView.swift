import SwiftUI
import SplineRuntime

struct OnBoardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    
    var body: some View {
        VStack {
            LogoView()
                .frame(height: UIScreen.main.bounds.height * 0.5)
            
            VStack {
                ContentView()
                
                Spacer(minLength: 20) // Fixed space between text and button
                
                GetStartedButton(action: completeOnboarding)
                    .padding(.bottom, 150) // Adds a little space at the bottom
            }
            .frame(maxHeight: .infinity) // Makes ContentView and button stretch to fill space
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
    }
    
    private func completeOnboarding() {
        hasCompletedOnboarding = true
    }
}

struct LogoView: View {
    var body: some View {
        Image("starving-black")
            .resizable()
            .scaledToFit() // Ensures image is fully visible without distortion
            .ignoresSafeArea(edges: .top) // Removes white space at the top
    }
}

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("Welcome to Starving!")
                .font(.title.bold())
                .foregroundColor(.primary)
    
            Text("Stay organized and keep your family happy! Create, manage, and check off grocery lists with ease—simplifying your shopping in one smart app.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Spacer() // Ensures the text is more centered vertically
        }
        .padding(.horizontal, 40)
    }
}

struct GetStartedButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("Get Started")
            
        }
        .primaryButtonStyle() // Applies custom button style
    }
}

#Preview {
    @State var hasCompletedOnboarding = false
    return OnBoardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
}
