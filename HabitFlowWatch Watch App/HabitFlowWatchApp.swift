//
//  HabitFlowWatchApp.swift
//  HabitFlowWatch Watch App
//
//  Created by Sebastián Kučera on 14.01.2026.
//

import SwiftUI
import WatchConnectivity

@main
struct HabitFlowWatch_Watch_AppApp: App {
    @StateObject private var dataManager = WatchDataManager.shared
    @StateObject private var connectivityManager = WatchConnectivityManagerWatch.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
                .environmentObject(connectivityManager)
        }
    }
}
