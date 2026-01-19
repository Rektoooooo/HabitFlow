//
//  Habit.swift
//  HabitTracker
//
//  Created by Sebastián Kučera on 12.01.2026.
//

import Foundation
import SwiftData

// MARK: - Habit Type

enum HabitType: String, Codable {
    case manual              // Standard binary habit (done/not done)
    case healthKitSleep      // Auto-sync from HKCategoryType.sleepAnalysis
    case healthKitWater      // Auto-sync from HKQuantityType.dietaryWater
    case healthKitCalories   // Auto-sync from HKQuantityType.dietaryEnergyConsumed
}

// MARK: - Data Source

enum HabitDataSource: String, Codable {
    case manual     // User enters value manually
    case healthKit  // Sync from Apple Health
}

// MARK: - Goal Progression

enum GoalProgression: String, Codable, CaseIterable {
    case fixed      // Goal never changes
    case rampUp     // Goal gradually increases over time
    case adaptive   // Goal adjusts based on performance

    var displayName: String {
        switch self {
        case .fixed: return "Fixed"
        case .rampUp: return "Ramp Up"
        case .adaptive: return "Adaptive"
        }
    }

    var description: String {
        switch self {
        case .fixed: return "Goal stays the same"
        case .rampUp: return "Goal increases over time"
        case .adaptive: return "Adjusts based on your performance"
        }
    }

    var icon: String {
        switch self {
        case .fixed: return "equal.circle.fill"
        case .rampUp: return "arrow.up.circle.fill"
        case .adaptive: return "waveform.path.ecg"
        }
    }
}

// MARK: - Habit Model

@Model
class Habit {
    var id: UUID = UUID()
    var name: String = ""
    var icon: String = "checkmark.circle.fill"
    var color: String = "#34C759"
    var createdAt: Date = Date()

    // HealthKit properties
    var habitTypeRaw: String = HabitType.manual.rawValue
    var dataSourceRaw: String = HabitDataSource.manual.rawValue
    var dailyGoal: Double?
    var unit: String?

    // Dynamic Goal properties
    var goalProgressionRaw: String = GoalProgression.fixed.rawValue
    var initialGoal: Double?
    var goalIncrement: Double?
    var goalIncrementIntervalDays: Int?
    var lastGoalAdjustment: Date?
    var restDaysPerWeek: Int?
    var restDays: [Int]? // Days of week (1=Sunday, 7=Saturday)

    // Stack properties
    var stackId: UUID? // ID of the stack this habit belongs to
    var stackOrder: Int? // Order within the stack

    // Focus Session properties
    var focusEnabled: Bool = false // Whether focus sessions are enabled for this habit

    @Relationship(deleteRule: .cascade, inverse: \HabitCompletion.habit)
    var completions: [HabitCompletion]?

    // Computed property wrappers for enums (SwiftData doesn't support enums directly)
    var habitType: HabitType {
        get { HabitType(rawValue: habitTypeRaw) ?? .manual }
        set { habitTypeRaw = newValue.rawValue }
    }

    var dataSource: HabitDataSource {
        get { HabitDataSource(rawValue: dataSourceRaw) ?? .manual }
        set { dataSourceRaw = newValue.rawValue }
    }

    var goalProgression: GoalProgression {
        get { GoalProgression(rawValue: goalProgressionRaw) ?? .fixed }
        set { goalProgressionRaw = newValue.rawValue }
    }

    /// Check if today is a rest day for this habit
    var isRestDayToday: Bool {
        guard let restDays = restDays, !restDays.isEmpty else { return false }
        let todayWeekday = Calendar.current.component(.weekday, from: Date())
        return restDays.contains(todayWeekday)
    }

    /// Get the effective daily goal (may be adjusted for ramp-up/adaptive)
    var effectiveDailyGoal: Double? {
        dailyGoal
    }

    init(
        name: String,
        icon: String = "checkmark.circle.fill",
        color: String = "#34C759",
        habitType: HabitType = .manual,
        dataSource: HabitDataSource = .manual,
        dailyGoal: Double? = nil,
        unit: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.color = color
        self.createdAt = Date()
        self.completions = []
        self.habitTypeRaw = habitType.rawValue
        self.dataSourceRaw = dataSource.rawValue
        self.dailyGoal = dailyGoal
        self.unit = unit
    }

    // MARK: - Computed Properties

    /// Safe accessor for completions (returns empty array if nil)
    var safeCompletions: [HabitCompletion] {
        completions ?? []
    }

    /// Get today's tracked value for HealthKit habits
    var todayValue: Double? {
        let calendar = Calendar.current
        return safeCompletions.first(where: { calendar.isDateInToday($0.date) })?.value
    }

    /// Progress toward daily goal (0.0 to 1.0+)
    var todayProgress: Double {
        guard let goal = dailyGoal, goal > 0 else {
            return isCompletedToday ? 1.0 : 0.0
        }
        guard let value = todayValue else { return 0.0 }
        return value / goal
    }

    var isCompletedToday: Bool {
        let calendar = Calendar.current
        guard let todayCompletion = safeCompletions.first(where: { calendar.isDateInToday($0.date) }) else {
            return false
        }

        // For habits with goals, check if goal is met
        if let goal = dailyGoal, let value = todayCompletion.value {
            return value >= goal
        }

        // For manual habits without goals, just check existence
        return true
    }

    var currentStreak: Int {
        let calendar = Calendar.current

        // Get unique dates where habit was actually completed (goal met for goal-based habits)
        let completedDates = Set(safeCompletions.compactMap { completion -> Date? in
            let date = calendar.startOfDay(for: completion.date)

            // For habits with goals, check if goal was met
            if let goal = dailyGoal, goal > 0 {
                guard let value = completion.value, value >= goal else {
                    return nil  // Goal not met, don't count this day
                }
            }
            return date
        }).sorted(by: >)

        guard !completedDates.isEmpty else { return 0 }

        var streak = 0
        var expectedDate = calendar.startOfDay(for: Date())

        // If not completed today, start checking from yesterday
        if !isCompletedToday {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: expectedDate) else {
                return 0
            }
            expectedDate = yesterday
        }

        for date in completedDates {
            if date == expectedDate {
                streak += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: expectedDate) else {
                    break
                }
                expectedDate = previousDay
            } else if date < expectedDate {
                break
            }
        }

        return streak
    }

    var longestStreak: Int {
        let calendar = Calendar.current

        // Get unique dates where habit was actually completed (goal met for goal-based habits)
        let completedDates = Set(safeCompletions.compactMap { completion -> Date? in
            let date = calendar.startOfDay(for: completion.date)

            // For habits with goals, check if goal was met
            if let goal = dailyGoal, goal > 0 {
                guard let value = completion.value, value >= goal else {
                    return nil  // Goal not met, don't count this day
                }
            }
            return date
        }).sorted()

        guard !completedDates.isEmpty else { return 0 }

        var longest = 1
        var current = 1

        for i in 1..<completedDates.count {
            let previousDate = completedDates[i - 1]
            let currentDate = completedDates[i]

            if let nextDay = calendar.date(byAdding: .day, value: 1, to: previousDate),
               calendar.isDate(nextDay, inSameDayAs: currentDate) {
                current += 1
                longest = max(longest, current)
            } else {
                current = 1
            }
        }

        return longest
    }

    var completionRate: Double {
        let calendar = Calendar.current
        let daysSinceCreation = calendar.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
        guard daysSinceCreation > 0 else { return isCompletedToday ? 1.0 : 0.0 }

        let uniqueDays = Set(safeCompletions.map { calendar.startOfDay(for: $0.date) }).count
        return Double(uniqueDays) / Double(daysSinceCreation + 1)
    }
}
