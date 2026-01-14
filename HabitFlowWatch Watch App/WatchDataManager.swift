//
//  WatchDataManager.swift
//  HabitFlowWatch
//
//  Created by Claude on 14.01.2026.
//

import Foundation
import SwiftUI
import WidgetKit
import Combine

// MARK: - Watch Data Manager

class WatchDataManager: ObservableObject {
    @MainActor static let shared = WatchDataManager()

    @Published var habits: [WatchHabitData] = []
    @Published var lastSyncDate: Date?

    private let suiteName = "group.ic-servis.com.HabitTracker"
    private let habitsKey = "watchHabits"
    private let lastSyncKey = "watchLastSync"

    init() {
        loadHabits()
    }

    // MARK: - Load Habits from App Group

    func loadHabits() {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: habitsKey),
              let decoded = try? JSONDecoder().decode([WatchHabitData].self, from: data) else {
            print("No habits found in App Group")

            #if targetEnvironment(simulator)
            // Load sample data for simulator testing
            if habits.isEmpty {
                loadSampleDataForSimulator()
            }
            #endif
            return
        }

        habits = decoded
        lastSyncDate = defaults.object(forKey: lastSyncKey) as? Date
        print("Loaded \(habits.count) habits from App Group")
    }

    #if targetEnvironment(simulator)
    private func loadSampleDataForSimulator() {
        print("Loading sample data for simulator")
        habits = [
            WatchHabitData(id: UUID(), name: "Morning Meditation", icon: "brain.head.profile", color: "#A855F7", isCompletedToday: false, currentStreak: 5),
            WatchHabitData(id: UUID(), name: "Exercise", icon: "figure.run", color: "#10B981", isCompletedToday: true, currentStreak: 12),
            WatchHabitData(id: UUID(), name: "Read 30 min", icon: "book.fill", color: "#3B82F6", isCompletedToday: false, currentStreak: 3),
            WatchHabitData(id: UUID(), name: "Drink Water", icon: "drop.fill", color: "#06B6D4", isCompletedToday: true, currentStreak: 20)
        ]
    }
    #endif

    // MARK: - Save Habits to App Group

    func saveHabits(_ newHabits: [WatchHabitData]) {
        habits = newHabits

        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = try? JSONEncoder().encode(newHabits) else {
            print("Failed to save habits")
            return
        }

        defaults.set(data, forKey: habitsKey)
        defaults.set(Date(), forKey: lastSyncKey)
        lastSyncDate = Date()

        // Reload complications
        WidgetCenter.shared.reloadAllTimelines()

        print("Saved \(newHabits.count) habits to App Group")
    }

    // MARK: - Toggle Habit Completion

    func toggleCompletion(for habitId: UUID) {
        guard let index = habits.firstIndex(where: { $0.id == habitId }) else {
            print("Habit not found: \(habitId)")
            return
        }

        // Toggle locally
        habits[index].isCompletedToday.toggle()

        // Save to App Group
        if let defaults = UserDefaults(suiteName: suiteName),
           let data = try? JSONEncoder().encode(habits) {
            defaults.set(data, forKey: habitsKey)
        }

        // Reload complications
        WidgetCenter.shared.reloadAllTimelines()

        // Send to iPhone
        WatchConnectivityManagerWatch.shared.sendCompletion(
            habitId: habitId,
            completed: habits[index].isCompletedToday
        )
    }

    // MARK: - Computed Properties

    var completedCount: Int {
        habits.filter { $0.isCompletedToday }.count
    }

    var totalCount: Int {
        habits.count
    }

    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    var nextIncompleteHabit: WatchHabitData? {
        habits.first { !$0.isCompletedToday }
    }
}

// MARK: - Watch Habit Data

struct WatchHabitData: Codable, Identifiable {
    let id: UUID
    let name: String
    let icon: String
    let color: String
    var isCompletedToday: Bool
    let currentStreak: Int
}
