//
//  MainTabView.swift
//  HabitTracker
//
//  Created by Sebastián Kučera on 12.01.2026.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @AppStorage("appearanceMode") private var appearanceMode: String = AppearanceMode.system.rawValue
    @State private var selectedTab = 0

    private var selectedAppearance: AppearanceMode {
        AppearanceMode(rawValue: appearanceMode) ?? .system
    }

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
        .tint(AppTheme.Colors.accentPrimary)
        .onChange(of: selectedTab) { _, _ in
            HapticManager.shared.tabChanged()
        }
        .preferredColorScheme(selectedAppearance.colorScheme)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: Habit.self, inMemory: true)
}
