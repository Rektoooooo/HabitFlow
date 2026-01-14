//
//  DynamicGoalManager.swift
//  HabitTracker
//
//  Created by Claude on 14.01.2026.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class DynamicGoalManager: ObservableObject {
    static let shared = DynamicGoalManager()

    private let calendar = Calendar.current

    private init() {}

    // MARK: - Goal Calculation

    /// Calculate the effective daily goal based on progression type
    func calculateEffectiveGoal(for habit: Habit) -> Double? {
        guard let initialGoal = habit.initialGoal ?? habit.dailyGoal else {
            return habit.dailyGoal
        }

        switch habit.goalProgression {
        case .fixed:
            return habit.dailyGoal ?? initialGoal

        case .rampUp:
            return calculateRampUpGoal(habit: habit, initialGoal: initialGoal)

        case .adaptive:
            return calculateAdaptiveGoal(habit: habit, initialGoal: initialGoal)
        }
    }

    // MARK: - Ramp-Up Goal

    private func calculateRampUpGoal(habit: Habit, initialGoal: Double) -> Double {
        guard let increment = habit.goalIncrement,
              let intervalDays = habit.goalIncrementIntervalDays,
              intervalDays > 0 else {
            return habit.dailyGoal ?? initialGoal
        }

        let daysSinceCreation = calendar.dateComponents([.day], from: habit.createdAt, to: Date()).day ?? 0
        let increments = daysSinceCreation / intervalDays

        let calculatedGoal = initialGoal + (Double(increments) * increment)

        // Cap at current dailyGoal if set as maximum
        if let maxGoal = habit.dailyGoal, calculatedGoal > maxGoal {
            return maxGoal
        }

        return calculatedGoal
    }

    // MARK: - Adaptive Goal

    private func calculateAdaptiveGoal(habit: Habit, initialGoal: Double) -> Double {
        // For adaptive, we use the current dailyGoal which gets adjusted over time
        return habit.dailyGoal ?? initialGoal
    }

    /// Check if an adaptive habit's goal should be adjusted
    func checkAdaptiveAdjustment(for habit: Habit) -> GoalAdjustmentSuggestion? {
        guard habit.goalProgression == .adaptive,
              let currentGoal = habit.dailyGoal,
              currentGoal > 0 else {
            return nil
        }

        // Check last 7 days of performance
        let recentCompletions = getRecentCompletions(for: habit, days: 7)
        let completionRate = calculateCompletionRate(completions: recentCompletions, habit: habit)

        // If consistently exceeding goal (>90% completion with >110% average value)
        if completionRate > 0.9 {
            let avgValue = calculateAverageValue(completions: recentCompletions)
            if let avg = avgValue, avg > currentGoal * 1.1 {
                let suggestedIncrease = min(currentGoal * 0.15, avg - currentGoal)
                return GoalAdjustmentSuggestion(
                    habit: habit,
                    type: .increase,
                    currentGoal: currentGoal,
                    suggestedGoal: currentGoal + suggestedIncrease,
                    reason: "You've been crushing this goal! Ready to level up?"
                )
            }
        }

        // If struggling (<50% completion rate)
        if completionRate < 0.5 && recentCompletions.count >= 3 {
            let suggestedDecrease = currentGoal * 0.2
            return GoalAdjustmentSuggestion(
                habit: habit,
                type: .decrease,
                currentGoal: currentGoal,
                suggestedGoal: max(currentGoal - suggestedDecrease, (habit.initialGoal ?? currentGoal) * 0.5),
                reason: "Let's make this more achievable. Small wins lead to big changes!"
            )
        }

        return nil
    }

    // MARK: - Rest Day Management

    /// Check if a specific date is a rest day for the habit
    func isRestDay(for habit: Habit, on date: Date) -> Bool {
        guard let restDays = habit.restDays, !restDays.isEmpty else {
            return false
        }
        let weekday = calendar.component(.weekday, from: date)
        return restDays.contains(weekday)
    }

    /// Get rest days as formatted string
    func formatRestDays(for habit: Habit) -> String? {
        guard let restDays = habit.restDays, !restDays.isEmpty else {
            return nil
        }

        let dayNames = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let names = restDays.sorted().compactMap { day -> String? in
            guard day >= 1 && day <= 7 else { return nil }
            return dayNames[day]
        }

        return names.joined(separator: ", ")
    }

    /// Check if user has earned a rest day (based on performance)
    func hasEarnedRestDay(for habit: Habit) -> Bool {
        // User earns a rest day if they've completed 5+ days in a row
        return habit.currentStreak >= 5
    }

    // MARK: - Goal Progress Info

    /// Get information about goal progression for display
    func getProgressionInfo(for habit: Habit) -> GoalProgressionInfo? {
        guard habit.goalProgression != .fixed else { return nil }

        switch habit.goalProgression {
        case .rampUp:
            return getRampUpInfo(for: habit)
        case .adaptive:
            return getAdaptiveInfo(for: habit)
        case .fixed:
            return nil
        }
    }

    private func getRampUpInfo(for habit: Habit) -> GoalProgressionInfo? {
        guard let initialGoal = habit.initialGoal,
              let increment = habit.goalIncrement,
              let intervalDays = habit.goalIncrementIntervalDays else {
            return nil
        }

        let currentEffective = calculateEffectiveGoal(for: habit) ?? habit.dailyGoal ?? 0
        let daysSinceCreation = calendar.dateComponents([.day], from: habit.createdAt, to: Date()).day ?? 0

        let daysUntilNextIncrease = intervalDays - (daysSinceCreation % intervalDays)
        let nextGoal = currentEffective + increment

        return GoalProgressionInfo(
            type: .rampUp,
            currentGoal: currentEffective,
            initialGoal: initialGoal,
            nextGoal: nextGoal,
            daysUntilChange: daysUntilNextIncrease,
            message: "Goal increases by \(formatGoalValue(increment, unit: habit.unit)) in \(daysUntilNextIncrease) day\(daysUntilNextIncrease == 1 ? "" : "s")"
        )
    }

    private func getAdaptiveInfo(for habit: Habit) -> GoalProgressionInfo? {
        guard let currentGoal = habit.dailyGoal else { return nil }

        let recentCompletions = getRecentCompletions(for: habit, days: 7)
        let completionRate = calculateCompletionRate(completions: recentCompletions, habit: habit)

        var message: String
        if completionRate > 0.8 {
            message = "Great progress! Goal may increase soon"
        } else if completionRate < 0.5 {
            message = "Taking it easy is okay. Goal may adjust"
        } else {
            message = "Goal adapts based on your performance"
        }

        return GoalProgressionInfo(
            type: .adaptive,
            currentGoal: currentGoal,
            initialGoal: habit.initialGoal,
            nextGoal: nil,
            daysUntilChange: nil,
            message: message
        )
    }

    // MARK: - Apply Adjustment

    /// Apply a goal adjustment suggestion
    func applyAdjustment(_ suggestion: GoalAdjustmentSuggestion, to habit: Habit) {
        habit.dailyGoal = suggestion.suggestedGoal
        habit.lastGoalAdjustment = Date()
    }

    // MARK: - Helpers

    private func getRecentCompletions(for habit: Habit, days: Int) -> [HabitCompletion] {
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return habit.completions.filter { $0.date >= startDate }
    }

    private func calculateCompletionRate(completions: [HabitCompletion], habit: Habit) -> Double {
        let days = 7
        var completedDays = 0

        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }

            // Skip rest days
            if isRestDay(for: habit, on: date) { continue }

            let dayStart = calendar.startOfDay(for: date)
            let hasCompletion = completions.contains { completion in
                calendar.isDate(completion.date, inSameDayAs: dayStart)
            }

            if hasCompletion {
                completedDays += 1
            }
        }

        let activeDays = (0..<days).filter { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { return true }
            return !isRestDay(for: habit, on: date)
        }.count

        return activeDays > 0 ? Double(completedDays) / Double(activeDays) : 0
    }

    private func calculateAverageValue(completions: [HabitCompletion]) -> Double? {
        let values = completions.compactMap { $0.value }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private func formatGoalValue(_ value: Double, unit: String?) -> String {
        if let unit = unit {
            if value == floor(value) {
                return "\(Int(value)) \(unit)"
            }
            return String(format: "%.1f %@", value, unit)
        }
        if value == floor(value) {
            return "\(Int(value))"
        }
        return String(format: "%.1f", value)
    }
}

// MARK: - Supporting Types

struct GoalAdjustmentSuggestion: Identifiable {
    let id = UUID()
    let habit: Habit
    let type: AdjustmentType
    let currentGoal: Double
    let suggestedGoal: Double
    let reason: String

    enum AdjustmentType {
        case increase
        case decrease
    }
}

struct GoalProgressionInfo {
    let type: GoalProgression
    let currentGoal: Double
    let initialGoal: Double?
    let nextGoal: Double?
    let daysUntilChange: Int?
    let message: String
}

// MARK: - Day Picker Helper

struct RestDayOption: Identifiable, Hashable {
    let id: Int  // 1-7 (Sunday-Saturday)
    let name: String
    let shortName: String

    static let allDays: [RestDayOption] = [
        RestDayOption(id: 1, name: "Sunday", shortName: "Sun"),
        RestDayOption(id: 2, name: "Monday", shortName: "Mon"),
        RestDayOption(id: 3, name: "Tuesday", shortName: "Tue"),
        RestDayOption(id: 4, name: "Wednesday", shortName: "Wed"),
        RestDayOption(id: 5, name: "Thursday", shortName: "Thu"),
        RestDayOption(id: 6, name: "Friday", shortName: "Fri"),
        RestDayOption(id: 7, name: "Saturday", shortName: "Sat")
    ]
}
