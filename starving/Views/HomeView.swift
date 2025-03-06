import SwiftUI

struct HomeView: View {
    @State private var selectedTab: Tab = .today

    var body: some View {
        ZStack {
            Color(.systemGray6) // Set a background color for the entire HomeView
                .edgesIgnoringSafeArea(.all)

            TabView(selection: $selectedTab) {
                TodayView(selectedTab: $selectedTab)
                    .tabItem {
                        Text("Today")
                        Image(systemName: "square.and.pencil")
                    }
                    .tag(Tab.today)
                    .hideBackButton()

                ItemsView()
                    .tabItem {
                        Text("Items")
                        Image(systemName: "carrot")
                    }
                    .tag(Tab.items)
                    .hideBackButton()

                RemindersView()
                    .tabItem {
                        Text("Reminder")
                        Image(systemName: "bell.and.waves.left.and.right")
                    }
                    .tag(Tab.reminders)
                    .hideBackButton()

                SettingsView()
                    .tabItem {
                        Text("Settings")
                        Image(systemName: "gearshape")
                    }
                    .tag(Tab.settings)
                    .hideBackButton()
            }
        }
    }
}

#Preview {
    HomeView()
}
