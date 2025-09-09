//
//  starvingApp.swift
//  starving
//
//  Created by Alan Haro on 1/24/25.
//

import SwiftUI
import SwiftData
import FirebaseCore
import GoogleSignIn

@main
struct StarvingApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    init() {
        FirebaseApp.configure()
        
        // Configure Google Sign-In
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let clientId = plist["CLIENT_ID"] as? String {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(hasCompletedOnboarding: $hasCompletedOnboarding)
                .modelContainer(for: [Item.self, Day.self])
                .withAuthentication()
        }
    }
}

struct ContentView: View {
    @Binding var hasCompletedOnboarding: Bool
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnBoardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            } else if !authManager.isSignedIn {
                LoginView(hasCompletedOnboarding: $hasCompletedOnboarding)
            } else {
                HomeView()
            }
        }
        .onOpenURL { url in
            GIDSignIn.sharedInstance.handle(url)
        }
    }
}
