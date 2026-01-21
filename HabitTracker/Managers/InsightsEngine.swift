//
//  InsightsEngine.swift
//  HabitTracker
//
//  Created by Claude on 14.01.2026.
//

import Foundation
import SwiftUI
import Combine  

@MainActor
class InsightsEngine: ObservableObject {
    static let shared = InsightsEngine()

    @Published var insights: [Insight] = []

    private let calendar = Calendar.current

    private init() {}

    // MARK: - Generate All Insights

    func generateInsights(for habits: [Habit]) -> [Insight] {
        var allInsights: [Insight] = []

        guard !habits.isEmpty else {
            return [createStarterInsight()]
        }

        // Streak insights
        allInsights.append(contentsOf: generateStreakInsights(habits: habits))

        // Pattern insights (day of week analysis)
        allInsights.append(contentsOf: generatePatternInsights(habits: habits))

        // Milestone insights
        allInsights.append(contentsOf: generateMilestoneInsights(habits: habits))

        // Improvement insights (week over week)
        allInsights.append(contentsOf: generateImprovementInsights(habits: habits))

        // Motivation insights
        allInsights.append(contentsOf: generateMotivationInsights(habits: habits))

        // Sort by priority (highest first) and limit
        allInsights.sort { $0.priority > $1.priority }
        self.insights = Array(allInsights.prefix(15))

        return self.insights
    }

    // MARK: - Starter Insight

    private func createStarterInsight() -> Insight {
        Insight(
            type: .motivation,
            title: "Welcome to Habit Owl!",
            message: "Add your first habit to start tracking and receive personalized insights.",
            priority: .high,
            isPositive: true
        )
    }

    // MARK: - Streak Insights

    private func generateStreakInsights(habits: [Habit]) -> [Insight] {
        var insights: [Insight] = []

        // Best current streak
        if let bestHabit = habits.max(by: { $0.currentStreak < $1.currentStreak }),
           bestHabit.currentStreak > 0 {

            let streakDays = bestHabit.currentStreak

            if streakDays >= 7 {
                insights.append(Insight(
                    type: .streak,
                    title: "On Fire!",
                    message: "\(bestHabit.name) has a \(streakDays)-day streak!",
                    detail: "Keep it going! You're building a strong habit.",
                    priority: streakDays >= 30 ? .urgent : .high,
                    relatedHabitId: bestHabit.id,
                    relatedHabitName: bestHabit.name,
                    value: Double(streakDays),
                    isPositive: true
                ))
            }
        }

        // Streak at risk (completed yesterday but not today)
        let todayStart = calendar.startOfDay(for: Date())
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: todayStart) else {
            return insights
        }

        for habit in habits {
            if habit.currentStreak > 3 && !habit.isCompletedToday {
                // Check if completed yesterday
                let completedYesterday = habit.safeCompletions.contains { completion in
                    calendar.isDate(completion.date, inSameDayAs: yesterday)
                }

                if completedYesterday {
                    insights.append(Insight(
                        type: .streak,
                        title: "Streak at Risk!",
                        message: "Complete \(habit.name) to keep your \(habit.currentStreak)-day streak alive!",
                        priority: .urgent,
                        relatedHabitId: habit.id,
                        relatedHabitName: habit.name,
                        value: Double(habit.currentStreak),
                        isPositive: false,
                        actionable: true
                    ))
                }
            }
        }

        // Close to beating personal record
        for habit in habits {
            let toRecord = habit.longestStreak - habit.currentStreak
            if toRecord > 0 && toRecord <= 3 && habit.currentStreak >= 5 {
                insights.append(Insight(
                    type: .streak,
                    title: "Almost There!",
                    message: "\(toRecord) more day\(toRecord == 1 ? "" : "s") to beat your \(habit.name) record!",
                    detail: "Your current streak: \(habit.currentStreak) days. Personal best: \(habit.longestStreak) days.",
                    priority: .high,
                    relatedHabitId: habit.id,
                    relatedHabitName: habit.name,
                    value: Double(toRecord),
                    isPositive: true,
                    actionable: true
                ))
            }
        }

        return insights
    }

    // MARK: - Pattern Insights

    private func generatePatternInsights(habits: [Habit]) -> [Insight] {
        var insights: [Insight] = []

        // Analyze completions by day of week
        let dayStats = analyzeDayOfWeekPatterns(habits: habits)

        guard !dayStats.isEmpty else { return insights }

        // Find best and worst days
        let sortedByRate = dayStats.sorted { $0.completionRate > $1.completionRate }

        if let bestDay = sortedByRate.first,
           sortedByRate.last != nil,
           bestDay.completionRate > 0 {

            // Best day insight
            let bestPercent = Int(bestDay.completionRate * 100)
            if bestPercent > 60 {
                insights.append(Insight(
                    type: .pattern,
                    title: "Your Power Day",
                    message: "\(bestDay.dayName) is your strongest day with \(bestPercent)% completion rate!",
                    detail: "You've completed \(bestDay.completionCount) habits on \(bestDay.dayName)s.",
                    priority: .medium,
                    value: bestDay.completionRate,
                    isPositive: true
                ))
            }

            // Weekend vs weekday comparison
            let weekendStats = dayStats.filter { $0.dayIndex == 1 || $0.dayIndex == 7 }
            let weekdayStats = dayStats.filter { $0.dayIndex >= 2 && $0.dayIndex <= 6 }

            let weekendAvg = weekendStats.reduce(0.0) { $0 + $1.completionRate } / max(Double(weekendStats.count), 1)
            let weekdayAvg = weekdayStats.reduce(0.0) { $0 + $1.completionRate } / max(Double(weekdayStats.count), 1)

            if weekendAvg > 0 && weekdayAvg > 0 {
                let diff = abs(weekendAvg - weekdayAvg)
                if diff > 0.15 {
                    let betterPeriod = weekendAvg > weekdayAvg ? "weekends" : "weekdays"
                    let percentDiff = Int(diff * 100)
                    insights.append(Insight(
                        type: .pattern,
                        title: "Weekend Warrior" + (weekendAvg > weekdayAvg ? "" : "... Not!"),
                        message: "You complete \(percentDiff)% more habits on \(betterPeriod).",
                        detail: betterPeriod == "weekends"
                            ? "Try scheduling important habits for Saturday and Sunday!"
                            : "Your routine is stronger during the work week.",
                        priority: .medium,
                        value: diff,
                        isPositive: true
                    ))
                }
            }
        }

        return insights
    }

    private func analyzeDayOfWeekPatterns(habits: [Habit]) -> [DayOfWeekStats] {
        var dayCompletions: [Int: Int] = [:] // dayIndex -> completion count
        var dayPossible: [Int: Int] = [:] // dayIndex -> possible completions

        let today = Date()
        guard let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: today) else {
            return []
        }

        for habit in habits {
            let habitCreated = habit.createdAt
            var currentDate = max(habitCreated, thirtyDaysAgo)

            while currentDate <= today {
                let dayIndex = calendar.component(.weekday, from: currentDate)
                dayPossible[dayIndex, default: 0] += 1

                let wasCompleted = habit.safeCompletions.contains { completion in
                    calendar.isDate(completion.date, inSameDayAs: currentDate)
                }
                if wasCompleted {
                    dayCompletions[dayIndex, default: 0] += 1
                }

                guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                    break
                }
                currentDate = nextDate
            }
        }

        let dayNames = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

        return (1...7).compactMap { dayIndex in
            let completions = dayCompletions[dayIndex] ?? 0
            let possible = dayPossible[dayIndex] ?? 0
            guard possible > 0 else { return nil }

            return DayOfWeekStats(
                dayName: dayNames[dayIndex],
                dayIndex: dayIndex,
                completionCount: completions,
                completionRate: Double(completions) / Double(possible)
            )
        }
    }

    // MARK: - Milestone Insights

    private func generateMilestoneInsights(habits: [Habit]) -> [Insight] {
        var insights: [Insight] = []

        // Total completions milestones
        let totalCompletions = habits.reduce(0) { $0 + $1.safeCompletions.count }
        let milestones = [50, 100, 250, 500, 1000, 2500, 5000]

        for milestone in milestones {
            if totalCompletions >= milestone && totalCompletions < milestone + 50 {
                insights.append(Insight(
                    type: .milestone,
                    title: "Milestone Reached!",
                    message: "You've completed \(totalCompletions) habit check-ins!",
                    detail: "Every check-in brings you closer to your goals.",
                    priority: milestone >= 500 ? .high : .medium,
                    value: Double(totalCompletions),
                    isPositive: true
                ))
                break
            }
        }

        // Individual habit milestones (30, 60, 90, 180, 365 day streaks)
        let streakMilestones = [30, 60, 90, 180, 365]
        for habit in habits {
            for milestone in streakMilestones {
                if habit.currentStreak == milestone {
                    insights.append(Insight(
                        type: .milestone,
                        title: "\(milestone)-Day Champion!",
                        message: "Incredible! \(habit.name) streak hit \(milestone) days!",
                        detail: milestone >= 90 ? "You've truly mastered this habit!" : "Keep going, you're building something great!",
                        priority: .urgent,
                        relatedHabitId: habit.id,
                        relatedHabitName: habit.name,
                        value: Double(milestone),
                        isPositive: true
                    ))
                }
            }
        }

        return insights
    }

    // MARK: - Improvement Insights

    private func generateImprovementInsights(habits: [Habit]) -> [Insight] {
        var insights: [Insight] = []

        let comparison = calculateWeeklyComparison(habits: habits)

        if comparison.currentWeekCompletions > 0 || comparison.previousWeekCompletions > 0 {
            if comparison.isImprovement && comparison.changePercent > 10 {
                insights.append(Insight(
                    type: .improvement,
                    title: "You're Improving!",
                    message: "\(Int(comparison.changePercent))% more completions than last week!",
                    detail: "This week: \(comparison.currentWeekCompletions) vs Last week: \(comparison.previousWeekCompletions)",
                    priority: comparison.changePercent > 25 ? .high : .medium,
                    value: comparison.changePercent,
                    isPositive: true
                ))
            } else if !comparison.isImprovement && comparison.changePercent > 20 {
                insights.append(Insight(
                    type: .improvement,
                    title: "Room to Grow",
                    message: "Completions are down \(Int(comparison.changePercent))% from last week.",
                    detail: "It's okay! Every day is a fresh start. You've got this!",
                    priority: .medium,
                    value: comparison.changePercent,
                    isPositive: false,
                    actionable: true
                ))
            }
        }

        // Individual habit improvement
        for habit in habits {
            let habitComparison = calculateHabitWeeklyComparison(habit: habit)
            if habitComparison.isImprovement && habitComparison.changePercent > 50 && habitComparison.currentWeekCompletions >= 3 {
                insights.append(Insight(
                    type: .improvement,
                    title: "\(habit.name) is Soaring!",
                    message: "You've really stepped up this habit this week!",
                    priority: .medium,
                    relatedHabitId: habit.id,
                    relatedHabitName: habit.name,
                    value: habitComparison.changePercent,
                    isPositive: true
                ))
            }
        }

        return insights
    }

    private func calculateWeeklyComparison(habits: [Habit]) -> WeeklyComparison {
        let today = Date()
        guard let thisWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)),
              let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: thisWeekStart) else {
            return WeeklyComparison(currentWeekCompletions: 0, previousWeekCompletions: 0, changePercent: 0, isImprovement: false)
        }

        var currentWeek = 0
        var previousWeek = 0

        for habit in habits {
            for completion in habit.safeCompletions {
                if completion.date >= thisWeekStart {
                    currentWeek += 1
                } else if completion.date >= lastWeekStart && completion.date < thisWeekStart {
                    previousWeek += 1
                }
            }
        }

        let change = previousWeek > 0
            ? Double(currentWeek - previousWeek) / Double(previousWeek) * 100
            : (currentWeek > 0 ? 100 : 0)

        return WeeklyComparison(
            currentWeekCompletions: currentWeek,
            previousWeekCompletions: previousWeek,
            changePercent: abs(change),
            isImprovement: currentWeek >= previousWeek
        )
    }

    private func calculateHabitWeeklyComparison(habit: Habit) -> WeeklyComparison {
        let today = Date()
        guard let thisWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)),
              let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: thisWeekStart) else {
            return WeeklyComparison(currentWeekCompletions: 0, previousWeekCompletions: 0, changePercent: 0, isImprovement: false)
        }

        var currentWeek = 0
        var previousWeek = 0

        for completion in habit.safeCompletions {
            if completion.date >= thisWeekStart {
                currentWeek += 1
            } else if completion.date >= lastWeekStart && completion.date < thisWeekStart {
                previousWeek += 1
            }
        }

        let change = previousWeek > 0
            ? Double(currentWeek - previousWeek) / Double(previousWeek) * 100
            : (currentWeek > 0 ? 100 : 0)

        return WeeklyComparison(
            currentWeekCompletions: currentWeek,
            previousWeekCompletions: previousWeek,
            changePercent: abs(change),
            isImprovement: currentWeek >= previousWeek
        )
    }

    // MARK: - Motivation Insights

    private func generateMotivationInsights(habits: [Habit]) -> [Insight] {
        var insights: [Insight] = []

        // All habits completed today
        let allCompletedToday = habits.allSatisfy { $0.isCompletedToday }
        if allCompletedToday && !habits.isEmpty {
            insights.append(Insight(
                type: .motivation,
                title: "Perfect Day!",
                message: "You've completed all \(habits.count) habits today!",
                detail: "Amazing work! Take a moment to celebrate your dedication.",
                priority: .high,
                isPositive: true
            ))
        }

        // High overall completion rate
        let avgCompletionRate = habits.reduce(0.0) { $0 + $1.completionRate } / Double(habits.count)
        if avgCompletionRate > 0.8 {
            insights.append(Insight(
                type: .motivation,
                title: "Consistency Champion",
                message: "Your average completion rate is \(Int(avgCompletionRate * 100))%!",
                detail: "You're in the top tier of habit builders. Keep it up!",
                priority: .medium,
                value: avgCompletionRate,
                isPositive: true
            ))
        }

        // Habit age celebration
        for habit in habits {
            let daysOld = calendar.dateComponents([.day], from: habit.createdAt, to: Date()).day ?? 0
            let milestones = [30, 90, 180, 365]

            for milestone in milestones {
                if daysOld == milestone {
                    insights.append(Insight(
                        type: .motivation,
                        title: "\(milestone)-Day Anniversary!",
                        message: "You've been tracking \(habit.name) for \(milestone) days!",
                        detail: "Consistency is the key to transformation.",
                        priority: .medium,
                        relatedHabitId: habit.id,
                        relatedHabitName: habit.name,
                        value: Double(milestone),
                        isPositive: true
                    ))
                }
            }
        }

        return insights
    }
}
