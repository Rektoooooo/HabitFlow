//
//  HabitSuggestionEngine.swift
//  HabitTracker
//
//  Created by Claude on 14.01.2026.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class HabitSuggestionEngine: ObservableObject {
    static let shared = HabitSuggestionEngine()

    @Published var suggestions: [HabitSuggestion] = []
    @Published var dismissedSuggestionNames: Set<String> = []

    private let dismissedKey = "dismissedSuggestions"

    private init() {
        loadDismissedSuggestions()
    }

    // MARK: - Generate Suggestions

    func generateSuggestions(for habits: [Habit]) -> [HabitSuggestion] {
        var suggestions: [HabitSuggestion] = []

        // Get existing habit names (lowercased for matching)
        let existingNames = Set(habits.map { $0.name.lowercased() })
        let existingCategories = detectCategories(from: habits)

        // 1. Find complementary habits based on what user already has
        for template in HabitTemplate.allTemplates {
            // Skip if user already has this habit
            if existingNames.contains(template.name.lowercased()) {
                continue
            }

            // Skip dismissed suggestions
            if dismissedSuggestionNames.contains(template.name) {
                continue
            }

            // Check if this template complements existing habits
            let (isRelevant, relatedHabits, priority) = calculateRelevance(
                template: template,
                existingHabits: habits,
                existingCategories: existingCategories
            )

            if isRelevant {
                let suggestion = HabitSuggestion(
                    name: template.name,
                    icon: template.icon,
                    color: template.color,
                    category: template.category,
                    reason: generateShortReason(template: template, relatedHabits: relatedHabits),
                    detailedReason: generateDetailedReason(template: template, relatedHabits: relatedHabits),
                    relatedTo: relatedHabits,
                    priority: priority
                )
                suggestions.append(suggestion)
            }
        }

        // 2. Add category gap suggestions
        let gapSuggestions = suggestForCategoryGaps(
            existingCategories: existingCategories,
            existingNames: existingNames
        )
        suggestions.append(contentsOf: gapSuggestions)

        // Sort by priority and return top suggestions
        suggestions.sort { $0.priority > $1.priority }
        self.suggestions = Array(suggestions.prefix(10))
        return self.suggestions
    }

    // MARK: - Relevance Calculation

    private func calculateRelevance(
        template: HabitTemplate,
        existingHabits: [Habit],
        existingCategories: Set<HabitCategory>
    ) -> (isRelevant: Bool, relatedHabits: [String], priority: Int) {
        var priority = 0
        var relatedHabits: [String] = []

        // Check keyword matches with existing habits
        for habit in existingHabits {
            let habitNameLower = habit.name.lowercased()
            for keyword in template.keywords {
                if habitNameLower.contains(keyword.lowercased()) {
                    relatedHabits.append(habit.name)
                    priority += 20
                    break
                }
            }
        }

        // Check category compatibility
        for category in template.complementaryCategories {
            if existingCategories.contains(category) {
                priority += 10
            }
        }

        // Boost priority if user doesn't have any habit in this category
        if !existingCategories.contains(template.category) {
            priority += 5
        }

        // Consider habit completion patterns (boost suggestions for habits that complement high-performing ones)
        let highPerformers = existingHabits.filter { $0.completionRate > 0.7 }
        for performer in highPerformers {
            let performerNameLower = performer.name.lowercased()
            for keyword in template.keywords {
                if performerNameLower.contains(keyword.lowercased()) {
                    priority += 15 // Extra boost for complementing successful habits
                    if !relatedHabits.contains(performer.name) {
                        relatedHabits.append(performer.name)
                    }
                }
            }
        }

        let isRelevant = priority >= 10 || !relatedHabits.isEmpty

        return (isRelevant, Array(Set(relatedHabits)), priority)
    }

    // MARK: - Category Detection

    private func detectCategories(from habits: [Habit]) -> Set<HabitCategory> {
        var categories: Set<HabitCategory> = []

        for habit in habits {
            let nameLower = habit.name.lowercased()

            // Health-related keywords
            if nameLower.contains("water") || nameLower.contains("vitamin") ||
               nameLower.contains("medicine") || nameLower.contains("health") ||
               habit.habitType == .healthKitWater {
                categories.insert(.health)
            }

            // Fitness-related keywords
            if nameLower.contains("exercise") || nameLower.contains("workout") ||
               nameLower.contains("run") || nameLower.contains("gym") ||
               nameLower.contains("walk") || nameLower.contains("stretch") {
                categories.insert(.fitness)
            }

            // Mindfulness-related keywords
            if nameLower.contains("meditat") || nameLower.contains("mindful") ||
               nameLower.contains("gratitude") || nameLower.contains("journal") ||
               nameLower.contains("breathe") {
                categories.insert(.mindfulness)
            }

            // Productivity-related keywords
            if nameLower.contains("plan") || nameLower.contains("goal") ||
               nameLower.contains("work") || nameLower.contains("task") ||
               nameLower.contains("focus") {
                categories.insert(.productivity)
            }

            // Learning-related keywords
            if nameLower.contains("read") || nameLower.contains("learn") ||
               nameLower.contains("study") || nameLower.contains("book") ||
               nameLower.contains("practice") {
                categories.insert(.learning)
            }

            // Self-care keywords
            if nameLower.contains("skin") || nameLower.contains("self") ||
               nameLower.contains("relax") || nameLower.contains("care") {
                categories.insert(.selfCare)
            }

            // Nutrition keywords
            if nameLower.contains("eat") || nameLower.contains("food") ||
               nameLower.contains("meal") || nameLower.contains("diet") ||
               nameLower.contains("vegetable") || nameLower.contains("calorie") ||
               habit.habitType == .healthKitCalories {
                categories.insert(.nutrition)
            }

            // Sleep keywords
            if nameLower.contains("sleep") || nameLower.contains("bed") ||
               nameLower.contains("rest") || nameLower.contains("night") ||
               habit.habitType == .healthKitSleep {
                categories.insert(.sleep)
            }
        }

        return categories
    }

    // MARK: - Category Gap Suggestions

    private func suggestForCategoryGaps(
        existingCategories: Set<HabitCategory>,
        existingNames: Set<String>
    ) -> [HabitSuggestion] {
        var gapSuggestions: [HabitSuggestion] = []

        // Find categories the user doesn't have
        let allCategories = Set(HabitCategory.allCases)
        let missingCategories = allCategories.subtracting(existingCategories)

        // For each missing category, suggest one starter habit
        for category in missingCategories {
            guard let template = HabitTemplate.allTemplates.first(where: {
                $0.category == category &&
                !existingNames.contains($0.name.lowercased()) &&
                !dismissedSuggestionNames.contains($0.name)
            }) else { continue }

            let suggestion = HabitSuggestion(
                name: template.name,
                icon: template.icon,
                color: template.color,
                category: template.category,
                reason: "Start your \(category.displayName.lowercased()) journey",
                detailedReason: "You don't have any \(category.displayName.lowercased()) habits yet. \(template.name) is a great way to start building a balanced routine.",
                relatedTo: [],
                priority: 5
            )
            gapSuggestions.append(suggestion)
        }

        return gapSuggestions
    }

    // MARK: - Reason Generation

    private func generateShortReason(template: HabitTemplate, relatedHabits: [String]) -> String {
        if relatedHabits.isEmpty {
            return "Popular with Dotti users"
        }

        if relatedHabits.count == 1 {
            return "Pairs well with \(relatedHabits[0])"
        }

        return "Complements your \(template.category.displayName.lowercased()) habits"
    }

    private func generateDetailedReason(template: HabitTemplate, relatedHabits: [String]) -> String {
        if relatedHabits.isEmpty {
            return "Users who focus on building healthy routines often find \(template.name.lowercased()) helps them stay consistent and motivated."
        }

        if relatedHabits.count == 1 {
            return "Since you're tracking \(relatedHabits[0]), adding \(template.name.lowercased()) can help reinforce your progress and create a more complete routine."
        }

        let habitList = relatedHabits.prefix(2).joined(separator: " and ")
        return "Based on your habits like \(habitList), we think \(template.name.lowercased()) would be a great addition to your routine."
    }

    // MARK: - Dismiss Suggestions

    func dismissSuggestion(_ suggestion: HabitSuggestion) {
        dismissedSuggestionNames.insert(suggestion.name)
        suggestions.removeAll { $0.name == suggestion.name }
        saveDismissedSuggestions()
    }

    func resetDismissedSuggestions() {
        dismissedSuggestionNames.removeAll()
        saveDismissedSuggestions()
    }

    // MARK: - Persistence

    private func loadDismissedSuggestions() {
        if let data = UserDefaults.standard.data(forKey: dismissedKey),
           let names = try? JSONDecoder().decode(Set<String>.self, from: data) {
            dismissedSuggestionNames = names
        }
    }

    private func saveDismissedSuggestions() {
        if let data = try? JSONEncoder().encode(dismissedSuggestionNames) {
            UserDefaults.standard.set(data, forKey: dismissedKey)
        }
    }
}
