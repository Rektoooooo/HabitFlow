//
//  HabitFlowWidget.swift
//  HabitFlowWidget
//
//  Created by Sebastián Kučera on 12.01.2026.
//

import WidgetKit
import SwiftUI

// MARK: - Provider

struct Provider: AppIntentTimelineProvider {
    private let suiteName = "group.ic-servis.com.HabitTracker"
    private let habitsKey = "widgetHabits"
    private let habitsContainerKey = "widgetHabitsContainer"

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            configuration: ConfigurationAppIntent(),
            habits: [
                WidgetHabitData(id: UUID(), name: "Exercise", icon: "figure.run", color: "#A855F7", isCompletedToday: true, currentStreak: 5),
                WidgetHabitData(id: UUID(), name: "Read", icon: "book.fill", color: "#10B981", isCompletedToday: false, currentStreak: 3),
                WidgetHabitData(id: UUID(), name: "Meditate", icon: "brain.head.profile", color: "#3B82F6", isCompletedToday: true, currentStreak: 7)
            ],
            lastSyncedDate: Date()
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let (habits, lastSynced) = loadHabits()
        return SimpleEntry(date: Date(), configuration: configuration, habits: habits, lastSyncedDate: lastSynced)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let (habits, lastSynced) = loadHabits()
        let currentDate = Date()
        let calendar = Calendar.current

        var entries: [SimpleEntry] = []

        // Current entry
        entries.append(SimpleEntry(date: currentDate, configuration: configuration, habits: habits, lastSyncedDate: lastSynced))

        // Create entry for midnight with reset completion status
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: currentDate),
           let midnight = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: tomorrow) {
            // At midnight, show all habits as not completed (new day)
            let resetHabits = habits.map { habit in
                WidgetHabitData(
                    id: habit.id,
                    name: habit.name,
                    icon: habit.icon,
                    color: habit.color,
                    isCompletedToday: false,
                    currentStreak: habit.currentStreak
                )
            }
            entries.append(SimpleEntry(date: midnight, configuration: configuration, habits: resetHabits, lastSyncedDate: lastSynced))
        }

        // Refresh at midnight to ensure data is fresh for the new day
        let refreshDate: Date
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: currentDate),
           let midnight = calendar.date(bySettingHour: 0, minute: 1, second: 0, of: tomorrow) {
            // Refresh shortly after midnight
            refreshDate = midnight
        } else {
            // Fallback to 15 minutes
            refreshDate = calendar.date(byAdding: .minute, value: 15, to: currentDate) ?? currentDate
        }

        return Timeline(entries: entries, policy: .after(refreshDate))
    }

    private func loadHabits() -> (habits: [WidgetHabitData], lastSynced: Date?) {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            return ([], nil)
        }

        // Try to load from the new container format with timestamp
        if let containerData = defaults.data(forKey: habitsContainerKey),
           let container = try? JSONDecoder().decode(WidgetDataContainer.self, from: containerData) {
            // Check if data is from today
            if container.isFromToday {
                return (container.habits, container.lastUpdatedDate)
            } else {
                // Data is from a previous day - reset completion status
                let resetHabits = container.habits.map { habit in
                    WidgetHabitData(
                        id: habit.id,
                        name: habit.name,
                        icon: habit.icon,
                        color: habit.color,
                        isCompletedToday: false, // Reset for new day
                        currentStreak: habit.currentStreak
                    )
                }
                return (resetHabits, container.lastUpdatedDate)
            }
        }

        // Fall back to legacy format (without timestamp)
        guard let data = defaults.data(forKey: habitsKey),
              let habits = try? JSONDecoder().decode([WidgetHabitData].self, from: data) else {
            return ([], nil)
        }
        return (habits, nil)
    }
}

// MARK: - Widget Data Container

/// Container that wraps habit data with a timestamp for freshness checking
struct WidgetDataContainer: Codable {
    let habits: [WidgetHabitData]
    let lastUpdatedDate: Date

    /// Check if the data is from today
    var isFromToday: Bool {
        Calendar.current.isDateInToday(lastUpdatedDate)
    }
}

// MARK: - Entry

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let habits: [WidgetHabitData]
    let lastSyncedDate: Date?
}

// MARK: - Widget Data Model

struct WidgetHabitData: Codable, Identifiable {
    let id: UUID
    let name: String
    let icon: String
    let color: String
    let isCompletedToday: Bool
    let currentStreak: Int
}

// MARK: - Widget Entry View

struct HabitFlowWidgetEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    @Environment(\.colorScheme) var colorScheme
    var entry: Provider.Entry

    var body: some View {
        let theme = WidgetTheme(colorScheme: colorScheme)

        switch widgetFamily {
        case .systemSmall:
            SmallWidgetView(habits: entry.habits, theme: theme)
        case .systemMedium:
            MediumWidgetView(habits: entry.habits, theme: theme)
        case .systemLarge:
            LargeWidgetView(habits: entry.habits, theme: theme)
        case .accessoryCircular:
            AccessoryCircularView(habits: entry.habits)
        case .accessoryRectangular:
            AccessoryRectangularView(habits: entry.habits)
        case .accessoryInline:
            AccessoryInlineView(habits: entry.habits)
        default:
            SmallWidgetView(habits: entry.habits, theme: theme)
        }
    }
}

// MARK: - Small Widget View

struct SmallWidgetView: View {
    let habits: [WidgetHabitData]
    let theme: WidgetTheme

    var completedToday: Int { habits.filter { $0.isCompletedToday }.count }
    var totalHabits: Int { habits.count }
    var progress: Double {
        guard totalHabits > 0 else { return 0 }
        return Double(completedToday) / Double(totalHabits)
    }
    var allDone: Bool { totalHabits > 0 && completedToday == totalHabits }

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(theme.cardBackground, lineWidth: 10)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            colors: allDone
                                ? [theme.successGreen, theme.successGreen.opacity(0.8)]
                                : [theme.primaryPurple, theme.primaryPink, theme.primaryPurple],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    if allDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(theme.successGreen)
                    } else {
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.primaryText)
                    }
                }
            }

            VStack(spacing: 2) {
                Text(allDone ? "All Done!" : "\(completedToday)/\(totalHabits)")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(allDone ? theme.successGreen : theme.primaryText)

                Text("Today")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(theme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    let habits: [WidgetHabitData]
    let theme: WidgetTheme

    var completedToday: Int { habits.filter { $0.isCompletedToday }.count }
    var totalHabits: Int { habits.count }
    var progress: Double {
        guard totalHabits > 0 else { return 0 }
        return Double(completedToday) / Double(totalHabits)
    }
    var allDone: Bool { totalHabits > 0 && completedToday == totalHabits }

    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .stroke(theme.cardBackground, lineWidth: 7)
                        .frame(width: 65, height: 65)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            AngularGradient(
                                colors: allDone
                                    ? [theme.successGreen, theme.successGreen.opacity(0.8)]
                                    : [theme.primaryPurple, theme.primaryPink, theme.primaryPurple],
                                center: .center,
                                startAngle: .degrees(-90),
                                endAngle: .degrees(270)
                            ),
                            style: StrokeStyle(lineWidth: 7, lineCap: .round)
                        )
                        .frame(width: 65, height: 65)
                        .rotationEffect(.degrees(-90))

                    if allDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(theme.successGreen)
                    } else {
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.primaryText)
                    }
                }

                Text("Today")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(theme.secondaryText)
            }
            .frame(width: 80)

            VStack(alignment: .leading, spacing: 5) {
                if habits.isEmpty {
                    emptyStateView
                } else {
                    ForEach(habits.prefix(3), id: \.id) { habit in
                        HabitRowMedium(habit: habit, theme: theme)
                    }

                    if habits.count > 3 {
                        Text("+\(habits.count - 3) more")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(theme.secondaryText)
                            .padding(.leading, 4)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 4)
    }

    private var emptyStateView: some View {
        VStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [theme.primaryPurple, theme.primaryPink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text("Add habits to start")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(theme.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Habit Row Medium

struct HabitRowMedium: View {
    let habit: WidgetHabitData
    let theme: WidgetTheme

    var habitColor: Color { Color(hex: habit.color) }

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(habitColor.opacity(0.2))
                    .frame(width: 26, height: 26)

                Image(systemName: habit.icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(habitColor)
            }

            Text(habit.name)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(theme.primaryText)
                .lineLimit(1)

            Spacer()

            if habit.isCompletedToday {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(habitColor)
            } else {
                Circle()
                    .stroke(theme.cardBorder, lineWidth: 1.5)
                    .frame(width: 16, height: 16)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(theme.cardBorder, lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Large Widget View

struct LargeWidgetView: View {
    let habits: [WidgetHabitData]
    let theme: WidgetTheme

    var completedToday: Int { habits.filter { $0.isCompletedToday }.count }
    var totalHabits: Int { habits.count }
    var progress: Double {
        guard totalHabits > 0 else { return 0 }
        return Double(completedToday) / Double(totalHabits)
    }
    var allDone: Bool { totalHabits > 0 && completedToday == totalHabits }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .stroke(theme.cardBackground, lineWidth: 5)
                        .frame(width: 44, height: 44)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            AngularGradient(
                                colors: allDone
                                    ? [theme.successGreen, theme.successGreen.opacity(0.8)]
                                    : [theme.primaryPurple, theme.primaryPink, theme.primaryPurple],
                                center: .center,
                                startAngle: .degrees(-90),
                                endAngle: .degrees(270)
                            ),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round)
                        )
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(-90))

                    if allDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(theme.successGreen)
                    } else {
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.primaryText)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(allDone ? "All Done!" : "Today's Progress")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(allDone ? theme.successGreen : theme.primaryText)

                    Text("\(completedToday) of \(totalHabits) habits")
                        .font(.system(size: 10))
                        .foregroundStyle(theme.secondaryText)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(theme.cardBackground)
                                .frame(height: 4)

                            RoundedRectangle(cornerRadius: 2)
                                .fill(
                                    LinearGradient(
                                        colors: allDone
                                            ? [theme.successGreen, theme.successGreen]
                                            : [theme.primaryPurple, theme.primaryPink],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * progress, height: 4)
                        }
                    }
                    .frame(height: 4)
                }

                Spacer()
            }

            if habits.isEmpty {
                emptyStateView
            } else {
                VStack(spacing: 5) {
                    ForEach(habits.prefix(5), id: \.id) { habit in
                        HabitRowLarge(habit: habit, theme: theme)
                    }

                    if habits.count > 5 {
                        Text("+\(habits.count - 5) more habits")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(theme.secondaryText)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.top, 4)
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 32))
                .foregroundStyle(
                    LinearGradient(
                        colors: [theme.primaryPurple, theme.primaryPink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text("Add habits to start tracking")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(theme.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Habit Row Large

struct HabitRowLarge: View {
    let habit: WidgetHabitData
    let theme: WidgetTheme

    var habitColor: Color { Color(hex: habit.color) }

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(habitColor.opacity(0.2))
                    .frame(width: 28, height: 28)

                Image(systemName: habit.icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(habitColor)
            }

            VStack(alignment: .leading, spacing: 0) {
                Text(habit.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(theme.primaryText)
                    .lineLimit(1)

                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.orange)
                    Text("\(habit.currentStreak) day streak")
                        .font(.system(size: 9))
                        .foregroundStyle(theme.secondaryText)
                }
            }

            Spacer()

            if habit.isCompletedToday {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(habitColor)
            } else {
                Circle()
                    .stroke(theme.cardBorder, lineWidth: 1.5)
                    .frame(width: 18, height: 18)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(theme.cardBorder, lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Lock Screen Widgets

struct AccessoryCircularView: View {
    let habits: [WidgetHabitData]

    var completedToday: Int { habits.filter { $0.isCompletedToday }.count }
    var totalHabits: Int { habits.count }
    var progress: Double {
        guard totalHabits > 0 else { return 0 }
        return Double(completedToday) / Double(totalHabits)
    }

    var body: some View {
        Gauge(value: progress) {
            Image(systemName: "flame.fill")
        } currentValueLabel: {
            Text("\(completedToday)")
                .font(.system(.title3, design: .rounded, weight: .bold))
        }
        .gaugeStyle(.accessoryCircular)
    }
}

struct AccessoryRectangularView: View {
    let habits: [WidgetHabitData]

    var completedToday: Int { habits.filter { $0.isCompletedToday }.count }
    var totalHabits: Int { habits.count }
    var progress: Double {
        guard totalHabits > 0 else { return 0 }
        return Double(completedToday) / Double(totalHabits)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.headline)
                Text("Habits")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
            }

            HStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.tertiary)
                            .frame(height: 6)

                        Capsule()
                            .fill(.primary)
                            .frame(width: geo.size.width * progress, height: 6)
                    }
                }
                .frame(height: 6)

                Text("\(completedToday)/\(totalHabits)")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .monospacedDigit()
            }

            if let nextHabit = habits.first(where: { !$0.isCompletedToday }) {
                HStack(spacing: 4) {
                    Image(systemName: nextHabit.icon)
                        .font(.caption2)
                    Text(nextHabit.name)
                        .font(.caption)
                        .lineLimit(1)
                }
                .foregroundStyle(.secondary)
            } else if totalHabits > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                    Text("All done!")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
        }
    }
}

struct AccessoryInlineView: View {
    let habits: [WidgetHabitData]

    var completedToday: Int { habits.filter { $0.isCompletedToday }.count }
    var totalHabits: Int { habits.count }

    var body: some View {
        if totalHabits == 0 {
            Label("No habits", systemImage: "circle.dashed")
        } else if completedToday == totalHabits {
            Label("All \(totalHabits) done!", systemImage: "checkmark.circle.fill")
        } else {
            Label("\(completedToday)/\(totalHabits) habits", systemImage: "flame.fill")
        }
    }
}

// MARK: - Widget Configuration

struct HabitFlowWidget: Widget {
    let kind: String = "HabitFlowWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            HabitFlowWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetBackground()
                }
        }
        .configurationDisplayName("Habits")
        .description("Track your daily habits.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

// MARK: - Previews

extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "😀"
        return intent
    }
}

#Preview(as: .systemSmall) {
    HabitFlowWidget()
} timeline: {
    SimpleEntry(
        date: .now,
        configuration: .smiley,
        habits: [
            WidgetHabitData(id: UUID(), name: "Exercise", icon: "figure.run", color: "#A855F7", isCompletedToday: true, currentStreak: 5),
            WidgetHabitData(id: UUID(), name: "Read", icon: "book.fill", color: "#10B981", isCompletedToday: false, currentStreak: 3),
            WidgetHabitData(id: UUID(), name: "Meditate", icon: "brain.head.profile", color: "#3B82F6", isCompletedToday: true, currentStreak: 7)
        ],
        lastSyncedDate: .now
    )
}

#Preview(as: .systemMedium) {
    HabitFlowWidget()
} timeline: {
    SimpleEntry(
        date: .now,
        configuration: .smiley,
        habits: [
            WidgetHabitData(id: UUID(), name: "Exercise", icon: "figure.run", color: "#A855F7", isCompletedToday: true, currentStreak: 5),
            WidgetHabitData(id: UUID(), name: "Read", icon: "book.fill", color: "#10B981", isCompletedToday: false, currentStreak: 3),
            WidgetHabitData(id: UUID(), name: "Meditate", icon: "brain.head.profile", color: "#3B82F6", isCompletedToday: true, currentStreak: 7),
            WidgetHabitData(id: UUID(), name: "Journal", icon: "pencil.line", color: "#F59E0B", isCompletedToday: false, currentStreak: 2)
        ],
        lastSyncedDate: .now
    )
}

#Preview(as: .systemLarge) {
    HabitFlowWidget()
} timeline: {
    SimpleEntry(
        date: .now,
        configuration: .smiley,
        habits: [
            WidgetHabitData(id: UUID(), name: "Exercise", icon: "figure.run", color: "#A855F7", isCompletedToday: true, currentStreak: 5),
            WidgetHabitData(id: UUID(), name: "Read", icon: "book.fill", color: "#10B981", isCompletedToday: false, currentStreak: 3),
            WidgetHabitData(id: UUID(), name: "Meditate", icon: "brain.head.profile", color: "#3B82F6", isCompletedToday: true, currentStreak: 7),
            WidgetHabitData(id: UUID(), name: "Journal", icon: "pencil.line", color: "#F59E0B", isCompletedToday: false, currentStreak: 2),
            WidgetHabitData(id: UUID(), name: "Water", icon: "drop.fill", color: "#06B6D4", isCompletedToday: true, currentStreak: 12),
            WidgetHabitData(id: UUID(), name: "Sleep", icon: "bed.double.fill", color: "#EC4899", isCompletedToday: false, currentStreak: 4)
        ],
        lastSyncedDate: .now
    )
}
