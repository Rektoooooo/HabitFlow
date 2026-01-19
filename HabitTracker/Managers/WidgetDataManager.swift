//
//  WidgetDataManager.swift
//  HabitTracker
//
//  Created by Sebastián Kučera on 12.01.2026.
//

import Foundation
import WidgetKit

/// Manages data synchronization between the main app and widgets
class WidgetDataManager {
    static let shared = WidgetDataManager()

    private let suiteName = "group.ic-servis.com.HabitTracker"
    private let habitsKey = "widgetHabits"
    private let habitsContainerKey = "widgetHabitsContainer"
    private let historyKey = "widgetHabitHistory"

    private init() {}

    /// Updates widget data with current habits
    func updateWidgetData(habits: [Habit]) {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            #if DEBUG
            print("Failed to access App Group UserDefaults")
            #endif
            return
        }

        // Save basic habit data for main widget
        let widgetData = habits.map { habit in
            WidgetHabitData(
                id: habit.id,
                name: habit.name,
                icon: habit.icon,
                color: habit.color,
                isCompletedToday: habit.isCompletedToday,
                currentStreak: habit.currentStreak
            )
        }

        if let encoded = try? JSONEncoder().encode(widgetData) {
            defaults.set(encoded, forKey: habitsKey)
        }

        // Save container with timestamp for day-change detection
        let container = WidgetDataContainer(habits: widgetData, lastUpdatedDate: Date())
        if let containerEncoded = try? JSONEncoder().encode(container) {
            defaults.set(containerEncoded, forKey: habitsContainerKey)
        }

        // Save history data for history widget (with completion dates)
        let historyData = habits.map { habit in
            WidgetHabitHistoryData(
                id: habit.id,
                name: habit.name,
                icon: habit.icon,
                color: habit.color,
                completionDates: habit.safeCompletions.map { $0.date },
                currentStreak: habit.currentStreak
            )
        }

        if let encoded = try? JSONEncoder().encode(historyData) {
            defaults.set(encoded, forKey: historyKey)
        }

        defaults.synchronize()

        // Reload all widgets
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Clears widget data
    func clearWidgetData() {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        defaults.removeObject(forKey: habitsKey)
        defaults.removeObject(forKey: historyKey)
        WidgetCenter.shared.reloadAllTimelines()
    }
}

/// Data structure for widget encoding (must match widget extension)
struct WidgetHabitData: Codable {
    let id: UUID
    let name: String
    let icon: String
    let color: String
    let isCompletedToday: Bool
    let currentStreak: Int
}

/// Container that wraps habit data with a timestamp for freshness checking
struct WidgetDataContainer: Codable {
    let habits: [WidgetHabitData]
    let lastUpdatedDate: Date

    /// Check if the data is from today
    var isFromToday: Bool {
        Calendar.current.isDateInToday(lastUpdatedDate)
    }
}

/// Data structure for habit history widget (must match widget extension)
struct WidgetHabitHistoryData: Codable {
    let id: UUID
    let name: String
    let icon: String
    let color: String
    let completionDates: [Date]
    let currentStreak: Int
}
