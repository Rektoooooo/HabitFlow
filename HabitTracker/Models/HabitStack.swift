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

// MARK: - Template Habit (for pre-built chains)

struct TemplateHabit {
    let name: String
    let icon: String
    let color: String
}

// MARK: - Stack Templates

struct StackTemplate: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let color: String
    let habits: [TemplateHabit] // Pre-defined habits to create

    // Legacy property for backwards compatibility
    var suggestedHabits: [String] {
        habits.map { $0.name }
    }

    static let templates: [StackTemplate] = [
        StackTemplate(
            name: "Morning Routine",
            description: "Start your day right with energy",
            icon: "sunrise.fill",
            color: "#F59E0B",
            habits: [
                TemplateHabit(name: "Wake Up Early", icon: "alarm.fill", color: "#F59E0B"),
                TemplateHabit(name: "Drink Water", icon: "drop.fill", color: "#06B6D4"),
                TemplateHabit(name: "Morning Meditation", icon: "brain.head.profile", color: "#8B5CF6"),
                TemplateHabit(name: "Exercise", icon: "figure.run", color: "#10B981"),
                TemplateHabit(name: "Healthy Breakfast", icon: "fork.knife", color: "#F97316")
            ]
        ),
        StackTemplate(
            name: "Evening Wind-Down",
            description: "Prepare for restful sleep",
            icon: "moon.stars.fill",
            color: "#8B5CF6",
            habits: [
                TemplateHabit(name: "No Screens", icon: "iphone.slash", color: "#EF4444"),
                TemplateHabit(name: "Read a Book", icon: "book.fill", color: "#3B82F6"),
                TemplateHabit(name: "Journal", icon: "pencil.and.scribble", color: "#EC4899"),
                TemplateHabit(name: "Evening Stretch", icon: "figure.flexibility", color: "#10B981"),
                TemplateHabit(name: "Sleep on Time", icon: "bed.double.fill", color: "#8B5CF6")
            ]
        ),
        StackTemplate(
            name: "Productivity Block",
            description: "Deep work session for focus",
            icon: "bolt.fill",
            color: "#3B82F6",
            habits: [
                TemplateHabit(name: "Plan Tasks", icon: "checklist", color: "#F59E0B"),
                TemplateHabit(name: "Focus Session", icon: "timer", color: "#3B82F6"),
                TemplateHabit(name: "Take a Break", icon: "cup.and.saucer.fill", color: "#10B981"),
                TemplateHabit(name: "Review Progress", icon: "chart.bar.fill", color: "#8B5CF6")
            ]
        ),
        StackTemplate(
            name: "Fitness Chain",
            description: "Complete workout routine",
            icon: "figure.run",
            color: "#10B981",
            habits: [
                TemplateHabit(name: "Warm Up", icon: "figure.walk", color: "#F59E0B"),
                TemplateHabit(name: "Cardio", icon: "heart.fill", color: "#EF4444"),
                TemplateHabit(name: "Strength Training", icon: "dumbbell.fill", color: "#3B82F6"),
                TemplateHabit(name: "Cool Down", icon: "wind", color: "#06B6D4"),
                TemplateHabit(name: "Stretch", icon: "figure.flexibility", color: "#10B981")
            ]
        ),
        StackTemplate(
            name: "Mindfulness Practice",
            description: "Mental wellness routine",
            icon: "brain.head.profile",
            color: "#EC4899",
            habits: [
                TemplateHabit(name: "Breathwork", icon: "wind", color: "#06B6D4"),
                TemplateHabit(name: "Meditation", icon: "brain.head.profile", color: "#8B5CF6"),
                TemplateHabit(name: "Gratitude", icon: "heart.fill", color: "#EC4899"),
                TemplateHabit(name: "Journaling", icon: "pencil.and.scribble", color: "#F59E0B")
            ]
        ),
        StackTemplate(
            name: "Self-Care Sunday",
            description: "Weekly self-care ritual",
            icon: "sparkles",
            color: "#EC4899",
            habits: [
                TemplateHabit(name: "Sleep In", icon: "bed.double.fill", color: "#8B5CF6"),
                TemplateHabit(name: "Skincare Routine", icon: "face.smiling.fill", color: "#EC4899"),
                TemplateHabit(name: "Healthy Meal Prep", icon: "carrot.fill", color: "#10B981"),
                TemplateHabit(name: "Relaxing Activity", icon: "leaf.fill", color: "#06B6D4")
            ]
        ),
        StackTemplate(
            name: "Study Session",
            description: "Effective learning routine",
            icon: "book.closed.fill",
            color: "#3B82F6",
            habits: [
                TemplateHabit(name: "Review Notes", icon: "doc.text.fill", color: "#F59E0B"),
                TemplateHabit(name: "Active Learning", icon: "brain.fill", color: "#8B5CF6"),
                TemplateHabit(name: "Practice Problems", icon: "pencil.and.ruler.fill", color: "#3B82F6"),
                TemplateHabit(name: "Quick Quiz", icon: "questionmark.circle.fill", color: "#10B981")
            ]
        )
    ]
}
