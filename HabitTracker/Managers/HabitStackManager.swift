//
//  HabitStackManager.swift
//  HabitTracker
//
//  Created by Claude on 14.01.2026.
//

import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
class HabitStackManager: ObservableObject {
    static let shared = HabitStackManager()

    @Published var activeStacks: [HabitStack] = []

    private init() {}

    // MARK: - Stack Operations

    /// Create a new stack
    func createStack(
        name: String,
        icon: String = "link.circle.fill",
        color: String = "#A855F7",
        habits: [Habit],
        in context: ModelContext
    ) -> HabitStack {
        let stack = HabitStack(
            name: name,
            icon: icon,
            color: color,
            habitOrder: habits.map { $0.id }
        )

        // Update habits with stack info
        for (index, habit) in habits.enumerated() {
            habit.stackId = stack.id
            habit.stackOrder = index
        }

        context.insert(stack)
        return stack
    }

    /// Add a habit to an existing stack
    func addHabit(_ habit: Habit, to stack: HabitStack, at position: Int? = nil) {
        let insertPosition = position ?? stack.habitOrder.count

        if insertPosition >= stack.habitOrder.count {
            stack.habitOrder.append(habit.id)
        } else {
            stack.habitOrder.insert(habit.id, at: insertPosition)
        }

        habit.stackId = stack.id
        habit.stackOrder = insertPosition

        // Update order for subsequent habits
        reorderHabitsInStack(stack, habits: [])
    }

    /// Remove a habit from a stack
    func removeHabit(_ habit: Habit, from stack: HabitStack) {
        stack.habitOrder.removeAll { $0 == habit.id }
        habit.stackId = nil
        habit.stackOrder = nil

        // Update order for remaining habits
        reorderHabitsInStack(stack, habits: [])
    }

    /// Reorder habits within a stack
    func reorderHabits(in stack: HabitStack, from source: IndexSet, to destination: Int) {
        stack.habitOrder.move(fromOffsets: source, toOffset: destination)
    }

    /// Update habit stack orders after reordering
    private func reorderHabitsInStack(_ stack: HabitStack, habits: [Habit]) {
        for (index, habitId) in stack.habitOrder.enumerated() {
            if let habit = habits.first(where: { $0.id == habitId }) {
                habit.stackOrder = index
            }
        }
    }

    /// Delete a stack (doesn't delete habits, just removes stack association)
    func deleteStack(_ stack: HabitStack, habits: [Habit], in context: ModelContext) {
        // Remove stack association from all habits
        for habit in habits where habit.stackId == stack.id {
            habit.stackId = nil
            habit.stackOrder = nil
        }

        context.delete(stack)
    }

    // MARK: - Progress Tracking

    /// Get progress for a stack
    func getProgress(for stack: HabitStack, habits: [Habit]) -> StackProgress {
        let stackHabits = habits
            .filter { stack.habitOrder.contains($0.id) }
            .sorted { (stack.habitOrder.firstIndex(of: $0.id) ?? 0) < (stack.habitOrder.firstIndex(of: $1.id) ?? 0) }

        let items = stackHabits.enumerated().map { index, habit in
            StackItem(
                id: habit.id,
                habit: habit,
                order: index,
                isCompleted: habit.isCompletedToday
            )
        }

        let completedCount = items.filter { $0.isCompleted }.count

        return StackProgress(
            stack: stack,
            items: items,
            completedCount: completedCount,
            totalCount: items.count
        )
    }

    /// Get the current (next incomplete) habit in a stack
    func getCurrentHabit(in stack: HabitStack, habits: [Habit]) -> Habit? {
        let progress = getProgress(for: stack, habits: habits)
        return progress.currentItem?.habit
    }

    /// Get all stacks with their progress
    func getAllStackProgress(stacks: [HabitStack], habits: [Habit]) -> [StackProgress] {
        stacks.map { getProgress(for: $0, habits: habits) }
    }

    // MARK: - Notifications

    /// Check if we should notify about next habit in chain
    func shouldNotifyNextInChain(completedHabit: Habit, stacks: [HabitStack], habits: [Habit]) -> (stack: HabitStack, nextHabit: Habit)? {
        guard let stackId = completedHabit.stackId,
              let stack = stacks.first(where: { $0.id == stackId }),
              stack.notifyOnChainProgress else {
            return nil
        }

        let progress = getProgress(for: stack, habits: habits)

        // Find the next habit after the completed one
        if let nextItem = progress.items.first(where: { !$0.isCompleted && $0.habit.id != completedHabit.id }) {
            return (stack, nextItem.habit)
        }

        return nil
    }

    // MARK: - Stack Suggestions

    /// Suggest habits that could be stacked together based on completion patterns
    func suggestStackCombinations(habits: [Habit]) -> [(habit1: Habit, habit2: Habit, correlation: Double)] {
        var suggestions: [(Habit, Habit, Double)] = []

        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date())!

        // Find habits that are often completed on the same day
        for i in 0..<habits.count {
            for j in (i+1)..<habits.count {
                let habit1 = habits[i]
                let habit2 = habits[j]

                // Skip if already in a stack
                guard habit1.stackId == nil && habit2.stackId == nil else { continue }

                // Calculate correlation
                let habit1Dates = Set(habit1.safeCompletions
                    .filter { $0.date >= thirtyDaysAgo }
                    .map { calendar.startOfDay(for: $0.date) })

                let habit2Dates = Set(habit2.safeCompletions
                    .filter { $0.date >= thirtyDaysAgo }
                    .map { calendar.startOfDay(for: $0.date) })

                guard !habit1Dates.isEmpty && !habit2Dates.isEmpty else { continue }

                let intersection = habit1Dates.intersection(habit2Dates).count
                let union = habit1Dates.union(habit2Dates).count

                let correlation = Double(intersection) / Double(union)

                if correlation > 0.5 {
                    suggestions.append((habit1, habit2, correlation))
                }
            }
        }

        return suggestions.sorted { $0.2 > $1.2 }
    }

    // MARK: - Validation

    /// Check if a habit can be added to a stack
    func canAddToStack(_ habit: Habit, stack: HabitStack) -> Bool {
        // Can't add if already in another stack
        guard habit.stackId == nil else { return false }

        // Can't add if already in this stack
        guard !stack.habitOrder.contains(habit.id) else { return false }

        return true
    }

    /// Check if a stack is valid (has at least 2 habits)
    func isValidStack(_ stack: HabitStack) -> Bool {
        stack.habitOrder.count >= 2
    }
}
