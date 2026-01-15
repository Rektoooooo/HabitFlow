//
//  HabitHistoryWidget.swift
//  HabitFlowWidget
//
//  Created by Sebastián Kučera on 12.01.2026.
//

import WidgetKit
import SwiftUI

// MARK: - Habit History Widget

struct HabitHistoryWidget: Widget {
    let kind: String = "HabitHistoryWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: HabitHistoryIntent.self, provider: HabitHistoryProvider()) { entry in
            HabitHistoryWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetBackground()
                }
        }
        .configurationDisplayName("Habit History")
        .description("View the activity grid for a specific habit.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Habit History Provider

struct HabitHistoryProvider: AppIntentTimelineProvider {
    private let suiteName = "group.ic-servis.com.HabitTracker"
    private let historyKey = "widgetHabitHistory"

    func placeholder(in context: Context) -> HabitHistoryEntry {
        HabitHistoryEntry(
            date: Date(),
            configuration: HabitHistoryIntent(),
            habitName: "Exercise",
            habitIcon: "figure.run",
            habitColor: "#A855F7",
            completionDates: [],
            currentStreak: 5
        )
    }

    func snapshot(for configuration: HabitHistoryIntent, in context: Context) async -> HabitHistoryEntry {
        return loadEntry(for: configuration)
    }

    func timeline(for configuration: HabitHistoryIntent, in context: Context) async -> Timeline<HabitHistoryEntry> {
        let entry = loadEntry(for: configuration)
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        return Timeline(entries: [entry], policy: .after(refreshDate))
    }

    private func loadEntry(for configuration: HabitHistoryIntent) -> HabitHistoryEntry {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: historyKey),
              let historyData = try? JSONDecoder().decode([HabitHistoryData].self, from: data),
              let selectedHabit = configuration.selectedHabit,
              let habitHistory = historyData.first(where: { $0.id.uuidString == selectedHabit.id }) else {

            if let defaults = UserDefaults(suiteName: suiteName),
               let data = defaults.data(forKey: historyKey),
               let historyData = try? JSONDecoder().decode([HabitHistoryData].self, from: data),
               let firstHabit = historyData.first {
                return HabitHistoryEntry(
                    date: Date(),
                    configuration: configuration,
                    habitName: firstHabit.name,
                    habitIcon: firstHabit.icon,
                    habitColor: firstHabit.color,
                    completionDates: firstHabit.completionDates,
                    currentStreak: firstHabit.currentStreak
                )
            }

            return HabitHistoryEntry(
                date: Date(),
                configuration: configuration,
                habitName: "Select a Habit",
                habitIcon: "questionmark.circle",
                habitColor: "#A855F7",
                completionDates: [],
                currentStreak: 0
            )
        }

        return HabitHistoryEntry(
            date: Date(),
            configuration: configuration,
            habitName: habitHistory.name,
            habitIcon: habitHistory.icon,
            habitColor: habitHistory.color,
            completionDates: habitHistory.completionDates,
            currentStreak: habitHistory.currentStreak
        )
    }
}

// MARK: - Habit History Entry

struct HabitHistoryEntry: TimelineEntry {
    let date: Date
    let configuration: HabitHistoryIntent
    let habitName: String
    let habitIcon: String
    let habitColor: String
    let completionDates: [Date]
    let currentStreak: Int
}

// MARK: - Habit History Data Model

struct HabitHistoryData: Codable {
    let id: UUID
    let name: String
    let icon: String
    let color: String
    let completionDates: [Date]
    let currentStreak: Int
}

// MARK: - Habit History Widget View

struct HabitHistoryWidgetView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.widgetFamily) var widgetFamily
    let entry: HabitHistoryEntry

    private var theme: WidgetTheme {
        WidgetTheme(colorScheme: colorScheme)
    }

    private var habitColor: Color {
        Color(hex: entry.habitColor)
    }

    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallHistoryView(entry: entry, theme: theme, habitColor: habitColor)
        default:
            MediumHistoryView(entry: entry, theme: theme, habitColor: habitColor)
        }
    }
}

// MARK: - Small History View

struct SmallHistoryView: View {
    let entry: HabitHistoryEntry
    let theme: WidgetTheme
    let habitColor: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(habitColor.opacity(0.2))
                        .frame(width: 28, height: 28)

                    Image(systemName: entry.habitIcon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(habitColor)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(entry.habitName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(theme.primaryText)
                        .lineLimit(1)

                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.orange)
                        Text("\(entry.currentStreak)")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(theme.secondaryText)
                    }
                }

                Spacer()
            }

            CompactHistoryGridView(
                completionDates: entry.completionDates,
                habitColor: habitColor,
                theme: theme
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Medium History View

struct MediumHistoryView: View {
    let entry: HabitHistoryEntry
    let theme: WidgetTheme
    let habitColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(habitColor.opacity(0.2))
                        .frame(width: 30, height: 30)

                    Image(systemName: entry.habitIcon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(habitColor)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(entry.habitName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(theme.primaryText)
                        .lineLimit(1)

                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.orange)
                        Text("\(entry.currentStreak) day streak")
                            .font(.system(size: 10))
                            .foregroundStyle(theme.secondaryText)
                    }
                }

                Spacer()
            }

            HistoryGridView(
                completionDates: entry.completionDates,
                habitColor: habitColor,
                theme: theme
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - History Grid View (Medium Widget - 16 weeks)

struct HistoryGridView: View {
    let completionDates: [Date]
    let habitColor: Color
    let theme: WidgetTheme

    private let columns = 16
    private let rows = 7
    private let spacing: CGFloat = 2

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private var completionSet: Set<String> {
        Set(completionDates.map { Self.dateFormatter.string(from: $0) })
    }

    private func dateString(for date: Date) -> String {
        Self.dateFormatter.string(from: date)
    }

    var body: some View {
        let calendar = Calendar.current
        let today = Date()

        GeometryReader { geometry in
            let horizontalSpacing = CGFloat(columns - 1) * spacing
            let verticalSpacing = CGFloat(rows - 1) * spacing
            let cellWidth = (geometry.size.width - horizontalSpacing) / CGFloat(columns)
            let cellHeight = (geometry.size.height - verticalSpacing) / CGFloat(rows)
            let cellSize = min(cellWidth, cellHeight)

            HStack(alignment: .top, spacing: spacing) {
                ForEach(0..<columns, id: \.self) { weekOffset in
                    VStack(spacing: spacing) {
                        ForEach(0..<rows, id: \.self) { dayOffset in
                            let daysAgo = (columns - 1 - weekOffset) * 7 + (6 - dayOffset)
                            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) ?? today
                            let isCompleted = completionSet.contains(dateString(for: date))
                            let isFuture = date > today

                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(
                                    isFuture
                                        ? Color.clear
                                        : isCompleted
                                            ? habitColor
                                            : theme.cardBackground
                                )
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}

// MARK: - Compact History Grid View (Small Widget - 7 weeks)

struct CompactHistoryGridView: View {
    let completionDates: [Date]
    let habitColor: Color
    let theme: WidgetTheme

    private let columns = 7
    private let rows = 7
    private let spacing: CGFloat = 3

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private var completionSet: Set<String> {
        Set(completionDates.map { Self.dateFormatter.string(from: $0) })
    }

    private func dateString(for date: Date) -> String {
        Self.dateFormatter.string(from: date)
    }

    var body: some View {
        let calendar = Calendar.current
        let today = Date()

        GeometryReader { geometry in
            let horizontalSpacing = CGFloat(columns - 1) * spacing
            let verticalSpacing = CGFloat(rows - 1) * spacing
            let cellWidth = (geometry.size.width - horizontalSpacing) / CGFloat(columns)
            let cellHeight = (geometry.size.height - verticalSpacing) / CGFloat(rows)
            let cellSize = min(cellWidth, cellHeight)

            HStack(alignment: .top, spacing: spacing) {
                ForEach(0..<columns, id: \.self) { weekOffset in
                    VStack(spacing: spacing) {
                        ForEach(0..<rows, id: \.self) { dayOffset in
                            let daysAgo = (columns - 1 - weekOffset) * 7 + (6 - dayOffset)
                            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) ?? today
                            let isCompleted = completionSet.contains(dateString(for: date))
                            let isFuture = date > today

                            RoundedRectangle(cornerRadius: 2)
                                .fill(
                                    isFuture
                                        ? Color.clear
                                        : isCompleted
                                            ? habitColor
                                            : theme.cardBackground
                                )
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}
