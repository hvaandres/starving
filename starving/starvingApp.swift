//
//  starvingApp.swift
//  starving
//
//  Created by Alan Haro on 1/24/25.
//

import SwiftUI
import SwiftData

@main
struct StarvingApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                HomeView()
                    .modelContainer(for: [Item.self, Day.self])
            } else {
                OnBoardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .modelContainer(for: [Item.self, Day.self])
            }
        }
    }
}
