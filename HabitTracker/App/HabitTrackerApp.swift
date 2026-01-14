//
//  HabitTrackerApp.swift
//  HabitTracker
//
//  Created by Sebastián Kučera on 12.01.2026.
//

import SwiftUI
import SwiftData
import WatchConnectivity

@main
struct HabitTrackerApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            // Schema for all models
            let schema = Schema([
                Habit.self,
                HabitCompletion.self,
                HabitStack.self,
                FocusSession.self
            ])

            // Configuration with iCloud sync
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private("iCloud.com.habitflow.app")
            )

            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )

            print("SwiftData with CloudKit initialized successfully")
        } catch {
            // Fallback to local-only storage if CloudKit fails
            print("CloudKit initialization failed: \(error.localizedDescription)")
            print("Falling back to local storage")

            do {
                let schema = Schema([
                    Habit.self,
                    HabitCompletion.self,
                    HabitStack.self,
                    FocusSession.self
                ])

                let localConfig = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    cloudKitDatabase: .none
                )

                modelContainer = try ModelContainer(
                    for: schema,
                    configurations: [localConfig]
                )
            } catch {
                fatalError("Failed to create ModelContainer: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Set model context for Watch connectivity
                    WatchConnectivityManager.shared.setModelContext(modelContainer.mainContext)
                }
        }
        .modelContainer(modelContainer)
    }
}
