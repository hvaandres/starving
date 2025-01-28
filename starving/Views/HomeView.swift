//
//  ContentView.swift
//  starving
//
//  Created by Alan Haro on 1/24/25.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Text("Today")
                    Image(systemName: "square.and.pencil")
                }
            ItemsView()
                .tabItem {
                    Text("Items")
                    Image(systemName: "carrot")
                }
            
            RemindersView()
                .tabItem {
                    Text("reminder")
                    Image(systemName: "bell.and.waves.left.and.right")
                }
            SettingsView()
                .tabItem {
                    Text("settings")
                    Image(systemName: "gearshape")
                }
        }
        .padding()
    }
}

#Preview {
    HomeView()
}
