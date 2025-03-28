import SwiftUI
import SplineRuntime

struct OnBoardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image("starving-black")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 500)
                    .clipped()
                    .ignoresSafeArea()
                
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

#Preview {
    @State var hasCompletedOnboarding = false
    return OnBoardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
}
