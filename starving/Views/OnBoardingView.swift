import SwiftUI
import SplineRuntime

struct OnBoardingView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                OnBoard3DView()
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
                
                NavigationLink(destination: HomeView()) {
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
            .navigationBarBackButtonHidden(true)  // Hide the back button
            .navigationBarHidden(true)            // Hide the navigation bar entirely
        }
    }
}

struct OnBoard3DView: View {
    private let sceneURL: URL
    init(urlString: String = "https://build.spline.design/g13uP1vc88dkrNdSVWc4/scene.splineswift") {
        guard let url = URL(string: urlString) else {
            // Fallback to local resource if URL is invalid
            self.sceneURL = Bundle.main.url(forResource: "scene", withExtension: "splineswift")!
            return
        }
        self.sceneURL = url
    }
    
    var body: some View {
        SplineView(sceneFileURL: sceneURL)
            .ignoresSafeArea()
    }
}
