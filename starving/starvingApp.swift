//
//  starvingApp.swift
//  starving
//
//  Created by Alan Haro on 1/24/25.
//

import SwiftUI
import SwiftData

@main
struct starvingApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
                .modelContainer(for: [Item.self, Day.self])
        }
    }
}
