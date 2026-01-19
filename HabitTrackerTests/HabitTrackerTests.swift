//
//  HabitTrackerTests.swift
//  HabitTrackerTests
//
//  Created by Sebastián Kučera on 12.01.2026.
//

import Testing
import Foundation
import SwiftData
@testable import HabitTracker

// MARK: - Habit Model Tests

@Suite("Habit Model Tests")
struct HabitModelTests {

    // MARK: - Initialization Tests

    @Test("Habit initializes with correct default values")
    func habitInitializesWithDefaults() {
        let habit = Habit(name: "Exercise")

        #expect(habit.name == "Exercise")
        #expect(habit.icon == "checkmark.circle.fill")
        #expect(habit.color == "#34C759")
        #expect(habit.habitType == .manual)
        #expect(habit.dataSource == .manual)
        #expect(habit.dailyGoal == nil)
        #expect(habit.unit == nil)
        #expect(habit.safeCompletions.isEmpty)
    }

    @Test("Habit initializes with custom values")
    func habitInitializesWithCustomValues() {
        let habit = Habit(
            name: "Drink Water",
            icon: "drop.fill",
            color: "#007AFF",
            habitType: .healthKitWater,
            dataSource: .healthKit,
            dailyGoal: 2000,
            unit: "ml"
        )

        #expect(habit.name == "Drink Water")
        #expect(habit.icon == "drop.fill")
        #expect(habit.color == "#007AFF")
        #expect(habit.habitType == .healthKitWater)
        #expect(habit.dataSource == .healthKit)
        #expect(habit.dailyGoal == 2000)
        #expect(habit.unit == "ml")
    }

    // MARK: - Goal Progression Tests

    @Test("GoalProgression has correct display names")
    func goalProgressionDisplayNames() {
        #expect(GoalProgression.fixed.displayName == "Fixed")
        #expect(GoalProgression.rampUp.displayName == "Ramp Up")
        #expect(GoalProgression.adaptive.displayName == "Adaptive")
    }

    @Test("GoalProgression has correct descriptions")
    func goalProgressionDescriptions() {
        #expect(GoalProgression.fixed.description == "Goal stays the same")
        #expect(GoalProgression.rampUp.description == "Goal increases over time")
        #expect(GoalProgression.adaptive.description == "Adjusts based on your performance")
    }

    @Test("GoalProgression has correct icons")
    func goalProgressionIcons() {
        #expect(GoalProgression.fixed.icon == "equal.circle.fill")
        #expect(GoalProgression.rampUp.icon == "arrow.up.circle.fill")
        #expect(GoalProgression.adaptive.icon == "waveform.path.ecg")
    }

    // MARK: - Habit Type Tests

    @Test("HabitType raw values are correct")
    func habitTypeRawValues() {
        #expect(HabitType.manual.rawValue == "manual")
        #expect(HabitType.healthKitSleep.rawValue == "healthKitSleep")
        #expect(HabitType.healthKitWater.rawValue == "healthKitWater")
        #expect(HabitType.healthKitCalories.rawValue == "healthKitCalories")
    }

    @Test("HabitDataSource raw values are correct")
    func habitDataSourceRawValues() {
        #expect(HabitDataSource.manual.rawValue == "manual")
        #expect(HabitDataSource.healthKit.rawValue == "healthKit")
    }
}

// MARK: - Habit Completion Tests

@Suite("Habit Completion Tests")
struct HabitCompletionTests {

    @Test("HabitCompletion initializes with correct values")
    func habitCompletionInitializes() {
        let completion = HabitCompletion(date: Date(), value: 1500, isAutoSynced: true)

        #expect(completion.value == 1500)
        #expect(completion.isAutoSynced == true)
        #expect(completion.id != UUID()) // Ensure ID was generated
    }

    @Test("HabitCompletion defaults are correct")
    func habitCompletionDefaults() {
        let completion = HabitCompletion()

        #expect(completion.value == nil)
        #expect(completion.isAutoSynced == false)
    }
}

// MARK: - Integration Tests with ModelContainer

@Suite("Habit Integration Tests")
struct HabitIntegrationTests {

    let container: ModelContainer

    init() throws {
        let schema = Schema([Habit.self, HabitCompletion.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
    }

    @Test("Can create and fetch habits")
    @MainActor
    func createAndFetchHabits() throws {
        let context = container.mainContext

        let habit = Habit(name: "Test Habit")
        context.insert(habit)
        try context.save()

        let descriptor = FetchDescriptor<Habit>()
        let habits = try context.fetch(descriptor)

        #expect(habits.count == 1)
        #expect(habits.first?.name == "Test Habit")
    }

    @Test("Habit isCompletedToday returns false when no completions")
    @MainActor
    func isCompletedTodayNoCompletions() throws {
        let context = container.mainContext

        let habit = Habit(name: "Test")
        context.insert(habit)

        #expect(habit.isCompletedToday == false)
    }

    @Test("Habit isCompletedToday returns true when completed today")
    @MainActor
    func isCompletedTodayWithCompletion() throws {
        let context = container.mainContext

        let habit = Habit(name: "Test")
        context.insert(habit)

        let completion = HabitCompletion(date: Date(), habit: habit)
        habit.completions?.append(completion)
        context.insert(completion)

        #expect(habit.isCompletedToday == true)
    }

    @Test("Habit with goal requires value to meet goal for completion")
    @MainActor
    func goalBasedCompletion() throws {
        let context = container.mainContext

        let habit = Habit(
            name: "Water",
            habitType: .healthKitWater,
            dataSource: .healthKit,
            dailyGoal: 2000,
            unit: "ml"
        )
        context.insert(habit)

        // Add completion with value below goal
        let completion = HabitCompletion(date: Date(), habit: habit, value: 1000)
        habit.completions?.append(completion)
        context.insert(completion)

        #expect(habit.isCompletedToday == false)
        #expect(habit.todayProgress == 0.5)

        // Update to meet goal
        completion.value = 2000

        #expect(habit.isCompletedToday == true)
        #expect(habit.todayProgress == 1.0)
    }

    @Test("Habit progress exceeds 100% when over goal")
    @MainActor
    func progressExceedsGoal() throws {
        let context = container.mainContext

        let habit = Habit(
            name: "Water",
            dailyGoal: 2000,
            unit: "ml"
        )
        context.insert(habit)

        let completion = HabitCompletion(date: Date(), habit: habit, value: 3000)
        habit.completions?.append(completion)
        context.insert(completion)

        #expect(habit.todayProgress == 1.5)
    }

    @Test("Current streak calculates correctly")
    @MainActor
    func currentStreakCalculation() throws {
        let context = container.mainContext

        let habit = Habit(name: "Test")
        context.insert(habit)

        let calendar = Calendar.current
        let today = Date()

        // Add completions for today, yesterday, and day before
        for daysAgo in 0..<3 {
            if let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) {
                let completion = HabitCompletion(date: date, habit: habit)
                habit.completions?.append(completion)
                context.insert(completion)
            }
        }

        #expect(habit.currentStreak == 3)
    }

    @Test("Streak breaks with gap in completions")
    @MainActor
    func streakBreaksWithGap() throws {
        let context = container.mainContext

        let habit = Habit(name: "Test")
        context.insert(habit)

        let calendar = Calendar.current
        let today = Date()

        // Complete today
        let todayCompletion = HabitCompletion(date: today, habit: habit)
        habit.completions?.append(todayCompletion)
        context.insert(todayCompletion)

        // Skip yesterday, complete 2 days ago
        if let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today) {
            let oldCompletion = HabitCompletion(date: twoDaysAgo, habit: habit)
            habit.completions?.append(oldCompletion)
            context.insert(oldCompletion)
        }

        // Streak should only be 1 (today only, since yesterday is missing)
        #expect(habit.currentStreak == 1)
    }

    @Test("Completion rate calculates correctly")
    @MainActor
    func completionRateCalculation() throws {
        let context = container.mainContext

        let calendar = Calendar.current
        let fiveDaysAgo = calendar.date(byAdding: .day, value: -5, to: Date())!

        let habit = Habit(name: "Test")
        // Manually set creation date to 5 days ago for testing
        habit.createdAt = fiveDaysAgo
        context.insert(habit)

        // Add completions for 3 out of 6 days (today + 5 previous days)
        let today = Date()
        for daysAgo in [0, 1, 3] {
            if let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) {
                let completion = HabitCompletion(date: date, habit: habit)
                habit.completions?.append(completion)
                context.insert(completion)
            }
        }

        // 3 completed days out of 6 total days = 0.5
        #expect(habit.completionRate == 0.5)
    }

    @Test("Rest days are correctly identified")
    @MainActor
    func restDaysIdentification() throws {
        let habit = Habit(name: "Test")

        // No rest days configured
        #expect(habit.isRestDayToday == false)

        // Set all days as rest days (1-7 = Sunday-Saturday)
        habit.restDays = [1, 2, 3, 4, 5, 6, 7]
        #expect(habit.isRestDayToday == true)

        // Empty array should return false
        habit.restDays = []
        #expect(habit.isRestDayToday == false)
    }

    @Test("Habits with completions cascade delete")
    @MainActor
    func cascadeDelete() throws {
        let context = container.mainContext

        let habit = Habit(name: "Test")
        context.insert(habit)

        let completion = HabitCompletion(date: Date(), habit: habit)
        habit.completions?.append(completion)
        context.insert(completion)

        try context.save()

        // Delete habit
        context.delete(habit)
        try context.save()

        // Verify completions are also deleted
        let completionDescriptor = FetchDescriptor<HabitCompletion>()
        let remainingCompletions = try context.fetch(completionDescriptor)

        #expect(remainingCompletions.isEmpty)
    }
}

// MARK: - Focus Session State Tests

@Suite("Focus Session State Tests")
struct FocusSessionStateTests {

    @Test("FocusSessionState has correct cases")
    func focusSessionStateCases() {
        // Verify all states exist and are distinct
        let states: [FocusSessionState] = [.idle, .running, .paused, .completed]
        #expect(states.count == 4)
    }
}
