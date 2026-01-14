//
//  HabitStack.swift
//  HabitTracker
//
//  Created by Claude on 14.01.2026.
//

import Foundation
import SwiftData

// MARK: - Habit Stack Model

@Model
class HabitStack {
    var id: UUID = UUID()
    var name: String = ""
    var icon: String = "link.circle.fill"
    var color: String = "#A855F7"
    var createdAt: Date = Date()

    // Ordered list of habit IDs in the stack
    var habitOrder: [UUID] = []

    // Settings
    var isActive: Bool = true
    var notifyOnChainProgress: Bool = true

    init(
        name: String,
        icon: String = "link.circle.fill",
        color: String = "#A855F7",
        habitOrder: [UUID] = []
    ) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.color = color
        self.createdAt = Date()
        self.habitOrder = habitOrder
        self.isActive = true
        self.notifyOnChainProgress = true
    }

    // MARK: - Computed Properties

    /// Number of habits in the stack
    var habitCount: Int {
        habitOrder.count
    }

    /// Check if stack is empty
    var isEmpty: Bool {
        habitOrder.isEmpty
    }
}

// MARK: - Stack Item (for UI representation)

struct StackItem: Identifiable, Equatable {
    let id: UUID
    let habit: Habit
    let order: Int
    var isCompleted: Bool

    static func == (lhs: StackItem, rhs: StackItem) -> Bool {
        lhs.id == rhs.id && lhs.order == rhs.order && lhs.isCompleted == rhs.isCompleted
    }
}

// MARK: - Stack Progress

struct StackProgress {
    let stack: HabitStack
    let items: [StackItem]
    let completedCount: Int
    let totalCount: Int

    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    var isComplete: Bool {
        completedCount == totalCount && totalCount > 0
    }

    var currentItem: StackItem? {
        items.first { !$0.isCompleted }
    }

    var nextItem: StackItem? {
        guard let current = currentItem,
              let currentIndex = items.firstIndex(where: { $0.id == current.id }),
              currentIndex + 1 < items.count else {
            return nil
        }
        return items[currentIndex + 1]
    }
}

// MARK: - Stack Templates

struct StackTemplate: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let color: String
    let suggestedHabits: [String] // Habit names to suggest

    static let templates: [StackTemplate] = [
        StackTemplate(
            name: "Morning Routine",
            description: "Start your day right",
            icon: "sunrise.fill",
            color: "#F59E0B",
            suggestedHabits: ["Wake up early", "Drink water", "Meditate", "Exercise", "Healthy breakfast"]
        ),
        StackTemplate(
            name: "Evening Wind-Down",
            description: "Prepare for restful sleep",
            icon: "moon.stars.fill",
            color: "#8B5CF6",
            suggestedHabits: ["No screens", "Read", "Journal", "Stretch", "Sleep on time"]
        ),
        StackTemplate(
            name: "Productivity Block",
            description: "Deep work session",
            icon: "bolt.fill",
            color: "#3B82F6",
            suggestedHabits: ["Plan tasks", "Focus session", "Take breaks", "Review progress"]
        ),
        StackTemplate(
            name: "Fitness Chain",
            description: "Complete workout routine",
            icon: "figure.run",
            color: "#10B981",
            suggestedHabits: ["Warm up", "Cardio", "Strength training", "Cool down", "Stretch"]
        ),
        StackTemplate(
            name: "Mindfulness Practice",
            description: "Mental wellness routine",
            icon: "brain.head.profile",
            color: "#EC4899",
            suggestedHabits: ["Breathwork", "Meditation", "Gratitude", "Journaling"]
        )
    ]
}
