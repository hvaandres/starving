//
//  starvingApp.swift
//  starving
//
//  Created by Alan Haro on 1/24/25.
//

import SwiftUI
import SwiftData
import FirebaseCore

@main
struct StarvingApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    init() {
        FirebaseApp.configure()
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
    }
}
