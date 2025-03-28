import SwiftUI
import SplineRuntime

struct OnBoardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Replace SplineView with AppIcon
                Image("AppIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 500)
                    .scaledToFill()
                
                VStack(spacing: 12) {
                    Text("Welcome to Starving!")
                        .font(.title.bold())
                        .foregroundColor(.primary)
                    
                    Text("Stay organized and keep your family happy! Create, manage, and check off grocery lists with ease—simplifying your shopping in one smart app.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
                
                Spacer()
                
                Button {
                    // Set the flag to true when the user taps "Get Started"
                    hasCompletedOnboarding = true
                } label: {
                    Text("Get Started")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarHidden(true)
        }
    }
}
