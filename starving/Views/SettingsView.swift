//
//  SettingsView.swift
//  starving
//
//  Created by Alan Haro on 1/24/25.
//

import SwiftUI

struct SettingsView: View {
    
    private let reviewUrl = URL(string: "https://apps.apple.com/")!
    private let shareUrl = URL(string: "https://apps.apple.com/app/")!
    private let privacyUrl = URL(string: "https://github.com")!
    private let githubProfile = URL(string: "https://github.com/hvaandres")
    private let feedbackEmail = "hello@aharo.dev"
    
    // Developer Info links
    private let spaceCreatorsLink = URL(string: "https://discord.gg/5Psmx9Ew")!
    private let mediumLink = URL(string: "https://medium.com/@ithvaandres")!
    
    // State variables for toggles
    @State private var notificationsEnabled: Bool = false
    @State private var selectedLanguage: String = "English"
    @State private var isNightModeEnabled: Bool = false
    
    var body: some View {
        
        ZStack {
            // Background color change for night mode
            Color(isNightModeEnabled ? .black : .white)
                .edgesIgnoringSafeArea(.all)  // Ensure it fills the entire screen

            VStack(alignment: .leading, spacing: 20) {
                
                // Title
                Text("Settings")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(isNightModeEnabled ? .white : .black)
                    .padding(.top, 40)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 25) {
                        
                        // Created By Section
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Created By")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(isNightModeEnabled ? .white : .black)
                            
                            Text("Made by Andres Haro")
                                .font(.body)
                                .foregroundColor(isNightModeEnabled ? .white : .black)
                                .padding(.bottom, 5)
                            
                            Text("Andres Haro is a developer passionate about building innovative software, teaching others, and contributing to open-source communities.")
                                .font(.body)
                                .foregroundColor(isNightModeEnabled ? .white : .gray)
                                .padding(.bottom, 5)
                            
                            // Links to developer's work
                            linkRow(imageName: "link", label: "Space Creators Community", destination: spaceCreatorsLink)
                            linkRow(imageName: "link", label: "Read on Medium", destination: mediumLink)
                        }
                        .padding(.horizontal)
                        
                        // General Settings Section
                        VStack(alignment: .leading, spacing: 15) {
                            Text("General Settings")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(isNightModeEnabled ? .white : .black)
                            
                            // Notifications Toggle
                            Toggle("Enable Notifications", isOn: $notificationsEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: .green))
                            
                            // Language Picker
                            HStack {
                                Text("Language")
                                    .font(.body)
                                    .foregroundColor(isNightModeEnabled ? .white : .black)
                                Spacer()
                                Picker("Select Language", selection: $selectedLanguage) {
                                    Text("English").tag("English")
                                    Text("Spanish").tag("Spanish")
                                    Text("Portuguese").tag("Portuguese")
                                }
                                .pickerStyle(MenuPickerStyle())
                                .frame(width: 150)
                                Text(selectedLanguage)
                                    .font(.body)
                                    .foregroundColor(isNightModeEnabled ? .white : .gray)
                            }
                            
                            // Night Mode Toggle
                            Toggle("Night Mode", isOn: $isNightModeEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: .green))
                        }
                        .padding(.horizontal)
                        
                        // Read / Rate / Recommend / Feedback Section
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Read / Rate / Recommend / Feedback")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(isNightModeEnabled ? .white : .black)
                            
                            // Rate the app
                            linkRow(imageName: "star.bubble", label: "Rate the app", destination: reviewUrl)
                            
                            // Recommend the app
                            ShareLink(item: shareUrl) {
                                HStack {
                                    Image(systemName: "arrowshape.turn.up.right")
                                    Text("Recommend the app")
                                }
                            }
                            
                            // Submit feedback
                            Button {
                                submitFeedback()
                            } label: {
                                HStack {
                                    Image(systemName: "quote.bubble")
                                    Text("Submit feedback")
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom)
                }
                .background(isNightModeEnabled ? Color.black : Color.white)
            }
        }
    }
    
    private func linkRow(imageName: String, label: String, destination: URL) -> some View {
        Link(destination: destination) {
            HStack {
                Image(systemName: imageName)
                Text(label)
                    .font(.body)
                    .fontWeight(.medium)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(Color(UIColor.systemGray6)) // Slight background for each row
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle()) // To avoid default link behavior
        .foregroundColor(isNightModeEnabled ? .white : .primary) // Text color
    }
    
    private func submitFeedback() {
        guard let mailUrl = createMailUrl() else {
            print("Couldn't create mail URL")
            return
        }
        
        if UIApplication.shared.canOpenURL(mailUrl) {
            UIApplication.shared.open(mailUrl)
        } else {
            print("Couldn't open mail client")
        }
    }
    
    private func createMailUrl() -> URL? {
        var mailUrlComponents = URLComponents()
        mailUrlComponents.scheme = "mailto"
        mailUrlComponents.path = feedbackEmail
        mailUrlComponents.queryItems = [
            URLQueryItem(name: "subject", value: "Feedback for Starving app!")
        ]
        
        return mailUrlComponents.url
    }
}

#Preview {
    SettingsView()
}
