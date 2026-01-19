//
//  MainTabView.swift
//  HabitTracker
//
//  Created by Sebastián Kučera on 12.01.2026.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .tint(themeManager.primaryColor)
        .onChange(of: selectedTab) { _, _ in
            HapticManager.shared.tabChanged()
        }
        .preferredColorScheme(themeManager.appearanceMode.colorScheme)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: Habit.self, inMemory: true)
}
