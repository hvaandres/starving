import SwiftUI
import StoreKit

struct SettingsView: View {
    @Environment(\.openURL) var openURL
    @Environment(\.colorScheme) var colorScheme

    // MARK: - URLs
    // Changed to use regular https URLs, we'll handle the App Store opening differently
    private let appId = "6742771179"
    private let shareUrl = URL(string: "https://apps.apple.com/us/app/starving-shopping-list/id6742771179")!
    private let githubProfile = URL(string: "https://github.com/hvaandres")!
    private let feedbackEmail = "hello@aharo.dev"

    // MARK: - Developer Info URLs
    private let spaceCreatorsLink = URL(string: "https://discord.gg/2fUzJkvVuE")!
    private let mediumLink = URL(string: "https://medium.com/@ithvaandres")!

    // MARK: - Constants
    private let appName = "Starving App"
    private let appVersion = "Version 1.3.0"
    private let developerName = "Andres Haro"
    private let developerBio = "Software engineer passionate about building innovative apps and teaching others."
    private let feedbackSubject = "Feedback for Starving app!"
    
    // MARK: - State
    @State private var showShareSheet = false
    @State private var showStoreProductView = false

    var body: some View {
        ZStack {
            // Solid background color (white)
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header (Outside the ScrollView)
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.top)
                    .padding(.bottom, 8)
                    .background(Color(.systemBackground))

                // Content (with opaque white background)
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        // MARK: - Developer Profile Card
                        developerProfileCard
                            .padding(.top, 8)

                        // MARK: - App Options Section
                        appOptionsSection

                        // MARK: - Connect Section
                        connectSection

                        // MARK: - App Info Footer
                        appInfoFooter
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                    .background(Color(.systemBackground)) //Ensure the scrollview fills the screen with color white
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [shareUrl])
        }
        .fullScreenCover(isPresented: $showStoreProductView) {
            StoreProductView(appId: appId)
        }
    }
    
    // MARK: - Developer Profile Card
    private var developerProfileCard: some View {
        VStack(spacing: 16) {
            // Developer avatar
            Circle()
                .fill(Color(UIColor.systemBlue).opacity(0.2))
                .frame(width: 115, height: 80)
                .overlay(
                    Image("icon-profile")
                        .resizable()
                        .scaledToFill()
                        .padding(20)
                        .foregroundColor(.blue)
                )
            
            VStack(spacing: 8) {
                Text(developerName)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(developerBio)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Link(destination: githubProfile) {
                Label("GitHub Profile", systemImage: "link")
                    .font(.footnote)
                    .foregroundColor(.blue)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
    
    // MARK: - App Options Section
    private var appOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "App Options", icon: "gearshape")
            
            SettingsButton(icon: "star.fill", text: "Rate on App Store", backgroundColor: Color.yellow.opacity(0.2), iconColor: .yellow) {
                // Using the StoreKit review request method instead
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    SKStoreReviewController.requestReview(in: windowScene)
                }
            }
            
            SettingsButton(icon: "square.and.arrow.up", text: "Share App", backgroundColor: Color.blue.opacity(0.2), iconColor: .blue) {
                showShareSheet = true
            }
            
            SettingsButton(icon: "envelope.fill", text: "Send Feedback", backgroundColor: Color.green.opacity(0.2), iconColor: .green) {
                submitFeedback()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
    
    // MARK: - Connect Section
    private var connectSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Connect", icon: "person.2")
            
            SettingsButton(icon: "ellipsis.message.fill", text: "Join Space Creators", backgroundColor: Color.purple.opacity(0.2), iconColor: .purple) {
                openURL(spaceCreatorsLink)
            }
            
            SettingsButton(icon: "doc.text.fill", text: "Read on Medium", backgroundColor: Color.orange.opacity(0.2), iconColor: .orange) {
                openURL(mediumLink)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
    
    // MARK: - App Info Footer
    private var appInfoFooter: some View {
        VStack(spacing: 4) {
            Image(systemName: "fork.knife")
                .font(.title)
                .foregroundColor(.secondary)
                .padding(.bottom, 4)
            
            Text(appName)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(appVersion)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private func submitFeedback() {
        guard let mailUrl = createMailUrl() else {
            return
        }
        if UIApplication.shared.canOpenURL(mailUrl) {
            UIApplication.shared.open(mailUrl)
        }
    }

    private func createMailUrl() -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = feedbackEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: feedbackSubject)
        ]
        return components.url
    }
}

// MARK: - Supporting Views
struct StoreProductView: UIViewControllerRepresentable {
    let appId: String
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> SKStoreProductViewController {
        let controller = SKStoreProductViewController()
        controller.delegate = context.coordinator
        
        let parameters = [SKStoreProductParameterITunesItemIdentifier: appId]
        controller.loadProduct(withParameters: parameters) { success, error in
            if !success {
                print("Failed to load product: \(String(describing: error))")
                // Dismiss the view if there's an error
                DispatchQueue.main.async {
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: SKStoreProductViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, SKStoreProductViewControllerDelegate {
        let parent: StoreProductView
        
        init(_ parent: StoreProductView) {
            self.parent = parent
        }
        
        func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct SettingsButton: View {
    let icon: String
    let text: String
    let backgroundColor: Color
    let iconColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(backgroundColor)
                    )
                    .foregroundColor(iconColor)
                
                Text(text)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color.clear) // Prevent highlighting on tap
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
            
            Text(title.uppercased())
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(.secondary)
    }
}

// MARK: - ShareSheet
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
}
