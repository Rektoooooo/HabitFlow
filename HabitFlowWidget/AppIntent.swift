//
//  AppIntent.swift
//  HabitFlowWidget
//
//  Created by Sebastián Kučera on 12.01.2026.
//

import WidgetKit
import AppIntents

// MARK: - Main Widget Configuration

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { "Configure your habit tracker widget." }

    @Parameter(title: "Favorite Emoji", default: "😃")
    var favoriteEmoji: String
}

// MARK: - Habit Selection Intent for History Widget

struct HabitHistoryIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Habit History" }
    static var description: IntentDescription { "Select a habit to show its history grid." }

    @Parameter(title: "Habit")
    var selectedHabit: HabitEntity?
}

// MARK: - Habit Entity for Widget Selection

struct HabitEntity: AppEntity {
    var id: String
    var name: String
    var icon: String
    var color: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Habit")
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            image: .init(systemName: icon)
        )
    }

    static var defaultQuery = HabitEntityQuery()
}

// MARK: - Habit Entity Query

struct HabitEntityQuery: EntityQuery {
    private let suiteName = "group.ic-servis.com.HabitTracker"
    private let habitsKey = "widgetHabits"

    func entities(for identifiers: [String]) async throws -> [HabitEntity] {
        let allHabits = loadHabits()
        return allHabits.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [HabitEntity] {
        return loadHabits()
    }

    func defaultResult() async -> HabitEntity? {
        return loadHabits().first
    }

    private func loadHabits() -> [HabitEntity] {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: habitsKey),
              let habits = try? JSONDecoder().decode([WidgetHabitData].self, from: data) else {
            return []
        }

        return habits.map { habit in
            HabitEntity(
                id: habit.id.uuidString,
                name: habit.name,
                icon: habit.icon,
                color: habit.color
            )
        }
    }
}

// Note: WidgetHabitData is defined in HabitFlowWidget.swift
