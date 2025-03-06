//
//  SettingsView.swift
//  starving
//
//  Created by Alan Haro on 1/24/25.
//

import SwiftUI

// Create an environment object to manage app-wide theme
class ThemeSettings: ObservableObject {
    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        }
    }
    
    init() {
        self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
    }
}

struct SettingsView: View {
    @StateObject private var themeSettings = ThemeSettings()
    @Environment(\.openURL) var openURL
    
    private let reviewUrl = URL(string: "https://apps.apple.com/us/app/starving-shopping-list/id6742771179")!
    private let shareUrl = URL(string: "https://apps.apple.com/us/app/starving-shopping-list/id6742771179")!
    private let privacyUrl = URL(string: "https://ithvaandres.medium.com")!
    private let githubProfile = URL(string: "https://github.com/hvaandres")!
    private let feedbackEmail = "hello@aharo.dev"
    
    // Developer Info links
    private let spaceCreatorsLink = URL(string: "https://discord.gg/2fUzJkvVuE")!
    private let mediumLink = URL(string: "https://medium.com/@ithvaandres")!
    
    var body: some View {
        NavigationView {
            ZStack {
                Group {
                    if themeSettings.isDarkMode {
                        Color.black
                    } else {
                        Color.white
                    }
                }
                .edgesIgnoringSafeArea(.all)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Appearance Section
//                        SettingsSection(title: "Appearance", isDarkMode: themeSettings.isDarkMode) {
//                            Toggle("Dark Mode", isOn: $themeSettings.isDarkMode)
//                                .toggleStyle(SwitchToggleStyle(tint: .blue))
//                        }
                        
                        // Developer Section
                        SettingsSection(title: "Developer", isDarkMode: themeSettings.isDarkMode) {
                            Text("Andres Haro")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(themeSettings.isDarkMode ? .white : .black)
                            
                            Text("Software engineer passionate about building innovative apps and teaching others.")
                                .font(.subheadline)
                                .foregroundColor(Color(.systemGray))
                                .padding(.bottom, 8)
                            
                            LinkButton(icon: "ellipsis.message", text: "Join Space Creators", url: spaceCreatorsLink, isDarkMode: themeSettings.isDarkMode)
                            LinkButton(icon: "doc.text", text: "Read on Medium", url: mediumLink, isDarkMode: themeSettings.isDarkMode)
                            LinkButton(icon: "link", text: "GitHub Profile", url: githubProfile, isDarkMode: themeSettings.isDarkMode)
                        }
                        
                        // App Section
                        SettingsSection(title: "App", isDarkMode: themeSettings.isDarkMode) {
                            LinkButton(icon: "star", text: "Rate on App Store", url: reviewUrl, isDarkMode: themeSettings.isDarkMode)
                            LinkButton(icon: "square.and.arrow.up", text: "Share App", url: shareUrl, isDarkMode: themeSettings.isDarkMode)
                            
                            // Custom LinkButton for email feedback
                            Button {
                                submitFeedback()
                            } label: {
                                HStack {
                                    Image(systemName: "envelope")
                                    Text("Send Feedback")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(Color(.systemGray))
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(themeSettings.isDarkMode ? Color(.systemGray6) : Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .foregroundColor(themeSettings.isDarkMode ? .white : .primary)
                        }
                        
                        // App Info
                        VStack(spacing: 4) {
                            Text("Starving App")
                                .font(.footnote)
                                .foregroundColor(Color(.systemGray))
                            Text("Version 1.1")
                                .font(.caption)
                                .foregroundColor(Color(.systemGray))
                        }
                        .padding(.top, 24)
                    }
                    .padding()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .environmentObject(themeSettings)
    }
    
    private func submitFeedback() {
        guard let mailUrl = createMailUrl() else { return }
        if UIApplication.shared.canOpenURL(mailUrl) {
            UIApplication.shared.open(mailUrl)
        }
    }
    
    private func createMailUrl() -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = feedbackEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: "Feedback for Starving app!")
        ]
        return components.url
    }
}

// MARK: - Supporting Views
struct SettingsSection<Content: View>: View {
    let title: String
    let isDarkMode: Bool
    let content: Content
    
    init(title: String, isDarkMode: Bool, @ViewBuilder content: () -> Content) {
        self.title = title
        self.isDarkMode = isDarkMode
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .foregroundColor(isDarkMode ? .white : .black)
            
            content
        }
        .padding()
        .background(isDarkMode ? Color(.systemGray6) : Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct LinkButton: View {
    let icon: String
    let text: String
    let url: URL
    let isDarkMode: Bool
    
    var body: some View {
        Link(destination: url) {
            HStack {
                Image(systemName: icon)
                Text(text)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color(.systemGray))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isDarkMode ? Color(.systemGray6) : Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .foregroundColor(isDarkMode ? .white : .primary)
    }
}

#Preview {
    SettingsView()
}
