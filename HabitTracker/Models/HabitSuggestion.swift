//
//  HabitSuggestion.swift
//  HabitTracker
//
//  Created by Claude on 14.01.2026.
//

import Foundation
import SwiftUI

// MARK: - Habit Category

enum HabitCategory: String, CaseIterable, Codable {
    case health
    case fitness
    case mindfulness
    case productivity
    case learning
    case selfCare
    case nutrition
    case sleep

    var displayName: String {
        switch self {
        case .health: return "Health"
        case .fitness: return "Fitness"
        case .mindfulness: return "Mindfulness"
        case .productivity: return "Productivity"
        case .learning: return "Learning"
        case .selfCare: return "Self Care"
        case .nutrition: return "Nutrition"
        case .sleep: return "Sleep"
        }
    }

    var icon: String {
        switch self {
        case .health: return "heart.fill"
        case .fitness: return "figure.run"
        case .mindfulness: return "brain.head.profile"
        case .productivity: return "checkmark.circle.fill"
        case .learning: return "book.fill"
        case .selfCare: return "sparkles"
        case .nutrition: return "leaf.fill"
        case .sleep: return "bed.double.fill"
        }
    }

    var color: Color {
        switch self {
        case .health: return Color(hex: "#EC4899")
        case .fitness: return Color(hex: "#F97316")
        case .mindfulness: return Color(hex: "#8B5CF6")
        case .productivity: return Color(hex: "#3B82F6")
        case .learning: return Color(hex: "#10B981")
        case .selfCare: return Color(hex: "#F472B6")
        case .nutrition: return Color(hex: "#22C55E")
        case .sleep: return Color(hex: "#6366F1")
        }
    }
}

// MARK: - Habit Suggestion

struct HabitSuggestion: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let icon: String
    let color: String
    let category: HabitCategory
    let reason: String
    let detailedReason: String
    let relatedTo: [String] // Names of related habits that triggered this suggestion
    let priority: Int // Higher = more relevant

    static func == (lhs: HabitSuggestion, rhs: HabitSuggestion) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Predefined Habit Templates

struct HabitTemplate {
    let name: String
    let icon: String
    let color: String
    let category: HabitCategory
    let keywords: [String] // Keywords to match against existing habits
    let complementaryCategories: [HabitCategory] // Categories this pairs well with

    static let allTemplates: [HabitTemplate] = [
        // Health & Fitness
        HabitTemplate(
            name: "Morning Stretch",
            icon: "figure.flexibility",
            color: "#F97316",
            category: .fitness,
            keywords: ["exercise", "workout", "gym", "run", "yoga"],
            complementaryCategories: [.fitness, .health, .sleep]
        ),
        HabitTemplate(
            name: "Evening Walk",
            icon: "figure.walk",
            color: "#10B981",
            category: .fitness,
            keywords: ["exercise", "run", "steps"],
            complementaryCategories: [.fitness, .mindfulness, .health]
        ),
        HabitTemplate(
            name: "Drink Water",
            icon: "drop.fill",
            color: "#06B6D4",
            category: .health,
            keywords: ["water", "hydration", "health"],
            complementaryCategories: [.fitness, .nutrition, .health]
        ),
        HabitTemplate(
            name: "Take Vitamins",
            icon: "pill.fill",
            color: "#F59E0B",
            category: .health,
            keywords: ["vitamin", "supplement", "health", "medicine"],
            complementaryCategories: [.health, .nutrition]
        ),

        // Mindfulness
        HabitTemplate(
            name: "Meditate",
            icon: "brain.head.profile",
            color: "#8B5CF6",
            category: .mindfulness,
            keywords: ["meditation", "mindful", "calm", "breathe"],
            complementaryCategories: [.sleep, .selfCare, .productivity]
        ),
        HabitTemplate(
            name: "Gratitude Journal",
            icon: "heart.text.square.fill",
            color: "#EC4899",
            category: .mindfulness,
            keywords: ["journal", "gratitude", "write", "diary"],
            complementaryCategories: [.mindfulness, .selfCare, .productivity]
        ),
        HabitTemplate(
            name: "Deep Breathing",
            icon: "wind",
            color: "#06B6D4",
            category: .mindfulness,
            keywords: ["breathe", "relax", "stress", "anxiety"],
            complementaryCategories: [.mindfulness, .health, .sleep]
        ),

        // Productivity
        HabitTemplate(
            name: "Plan Tomorrow",
            icon: "calendar.badge.clock",
            color: "#3B82F6",
            category: .productivity,
            keywords: ["plan", "organize", "schedule", "todo"],
            complementaryCategories: [.productivity, .learning]
        ),
        HabitTemplate(
            name: "Review Goals",
            icon: "target",
            color: "#8B5CF6",
            category: .productivity,
            keywords: ["goal", "review", "progress", "track"],
            complementaryCategories: [.productivity, .mindfulness]
        ),
        HabitTemplate(
            name: "No Phone First Hour",
            icon: "iphone.slash",
            color: "#EF4444",
            category: .productivity,
            keywords: ["phone", "digital", "detox", "morning"],
            complementaryCategories: [.productivity, .mindfulness, .selfCare]
        ),

        // Learning
        HabitTemplate(
            name: "Read 20 Pages",
            icon: "book.fill",
            color: "#10B981",
            category: .learning,
            keywords: ["read", "book", "learn", "study"],
            complementaryCategories: [.learning, .productivity, .mindfulness]
        ),
        HabitTemplate(
            name: "Learn Language",
            icon: "globe",
            color: "#3B82F6",
            category: .learning,
            keywords: ["language", "learn", "duolingo", "study"],
            complementaryCategories: [.learning, .productivity]
        ),
        HabitTemplate(
            name: "Practice Skill",
            icon: "star.fill",
            color: "#F59E0B",
            category: .learning,
            keywords: ["practice", "skill", "hobby", "instrument"],
            complementaryCategories: [.learning, .selfCare]
        ),

        // Self Care
        HabitTemplate(
            name: "Skincare Routine",
            icon: "sparkles",
            color: "#F472B6",
            category: .selfCare,
            keywords: ["skin", "face", "beauty", "routine"],
            complementaryCategories: [.selfCare, .health]
        ),
        HabitTemplate(
            name: "Screen-Free Evening",
            icon: "moon.stars.fill",
            color: "#6366F1",
            category: .selfCare,
            keywords: ["screen", "evening", "relax", "sleep"],
            complementaryCategories: [.selfCare, .sleep, .mindfulness]
        ),
        HabitTemplate(
            name: "Connect with Friend",
            icon: "person.2.fill",
            color: "#EC4899",
            category: .selfCare,
            keywords: ["friend", "social", "call", "connect"],
            complementaryCategories: [.selfCare, .mindfulness]
        ),

        // Nutrition
        HabitTemplate(
            name: "Eat Vegetables",
            icon: "leaf.fill",
            color: "#22C55E",
            category: .nutrition,
            keywords: ["vegetable", "healthy", "eat", "food", "diet"],
            complementaryCategories: [.nutrition, .health, .fitness]
        ),
        HabitTemplate(
            name: "No Sugar",
            icon: "xmark.circle.fill",
            color: "#EF4444",
            category: .nutrition,
            keywords: ["sugar", "diet", "healthy", "food"],
            complementaryCategories: [.nutrition, .health]
        ),
        HabitTemplate(
            name: "Meal Prep",
            icon: "fork.knife",
            color: "#F97316",
            category: .nutrition,
            keywords: ["meal", "cook", "prep", "food"],
            complementaryCategories: [.nutrition, .health, .productivity]
        ),

        // Sleep
        HabitTemplate(
            name: "Sleep by 11 PM",
            icon: "bed.double.fill",
            color: "#6366F1",
            category: .sleep,
            keywords: ["sleep", "bed", "rest", "night"],
            complementaryCategories: [.sleep, .health, .selfCare]
        ),
        HabitTemplate(
            name: "No Caffeine After 2 PM",
            icon: "cup.and.saucer.fill",
            color: "#78716C",
            category: .sleep,
            keywords: ["caffeine", "coffee", "sleep", "energy"],
            complementaryCategories: [.sleep, .health]
        ),
        HabitTemplate(
            name: "Wind Down Routine",
            icon: "moon.fill",
            color: "#8B5CF6",
            category: .sleep,
            keywords: ["wind", "evening", "relax", "sleep", "night"],
            complementaryCategories: [.sleep, .selfCare, .mindfulness]
        )
    ]
}
