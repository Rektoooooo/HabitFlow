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
    @Published var isPremium: Bool = false

    private let suiteName = "group.ic-servis.com.HabitTracker"
    private let habitsKey = "watchHabits"
    private let lastSyncKey = "watchLastSync"
    private let premiumKey = "isPremium"

    init() {
        loadHabits()
    }

    // MARK: - Load Habits from App Group

    func loadHabits() {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            #if DEBUG
            print("Could not access App Group")
            #endif
            return
        }

        // Load premium status
        isPremium = defaults.bool(forKey: premiumKey)

        // If not premium, don't load habits (Watch is premium feature)
        guard isPremium else {
            habits = []
            #if DEBUG
            print("Not premium, Watch app locked")
            #endif

            #if targetEnvironment(simulator)
            // For simulator testing, allow sample data
            isPremium = true
            loadSampleDataForSimulator()
            #endif
            return
        }

        guard let data = defaults.data(forKey: habitsKey),
              let decoded = try? JSONDecoder().decode([WatchHabitData].self, from: data) else {
            #if DEBUG
            print("No habits found in App Group")
            #endif
            return
        }

        habits = decoded
        lastSyncDate = defaults.object(forKey: lastSyncKey) as? Date
        #if DEBUG
        print("Loaded \(habits.count) habits from App Group")
        #endif
    }

    #if targetEnvironment(simulator)
    private func loadSampleDataForSimulator() {
        #if DEBUG
        print("Loading sample data for simulator")
        #endif
        habits = [
            WatchHabitData(id: UUID(), name: "Morning Meditation", icon: "brain.head.profile", color: "#A855F7", isCompletedToday: false, currentStreak: 5),
            WatchHabitData(id: UUID(), name: "Exercise", icon: "figure.run", color: "#10B981", isCompletedToday: true, currentStreak: 12),
            WatchHabitData(id: UUID(), name: "Read 30 min", icon: "book.fill", color: "#3B82F6", isCompletedToday: false, currentStreak: 3),
            WatchHabitData(id: UUID(), name: "Drink Water", icon: "drop.fill", color: "#06B6D4", isCompletedToday: true, currentStreak: 20)
        ]
    }
    #endif

    // MARK: - Update Premium Status

    func updatePremiumStatus(_ premium: Bool) {
        isPremium = premium

        if let defaults = UserDefaults(suiteName: suiteName) {
            defaults.set(premium, forKey: premiumKey)
        }

        // If no longer premium, clear habits
        if !premium {
            habits = []
        }

        #if DEBUG
        print("Premium status updated: \(premium)")
        #endif
    }

    // MARK: - Save Habits to App Group

    func saveHabits(_ newHabits: [WatchHabitData], isPremium premium: Bool? = nil) {
        // Update premium status if provided
        if let premium = premium {
            updatePremiumStatus(premium)
        }

        // Only save habits if premium
        guard isPremium else {
            habits = []
            #if DEBUG
            print("Not premium, not saving habits")
            #endif
            return
        }

        habits = newHabits

        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = try? JSONEncoder().encode(newHabits) else {
            #if DEBUG
            print("Failed to save habits")
            #endif
            return
        }

        defaults.set(data, forKey: habitsKey)
        defaults.set(Date(), forKey: lastSyncKey)
        lastSyncDate = Date()

        // Reload complications
        WidgetCenter.shared.reloadAllTimelines()

        #if DEBUG
        print("Saved \(newHabits.count) habits to App Group")
        #endif
    }

    // MARK: - Toggle Habit Completion

    func toggleCompletion(for habitId: UUID) {
        guard let index = habits.firstIndex(where: { $0.id == habitId }) else {
            #if DEBUG
            print("Habit not found: \(habitId)")
            #endif
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
