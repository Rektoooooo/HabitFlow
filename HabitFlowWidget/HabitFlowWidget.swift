//
//  HabitFlowWidget.swift
//  HabitFlowWidget
//
//  Created by Sebastián Kučera on 12.01.2026.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    private let suiteName = "group.ic-servis.com.HabitTracker"
    private let habitsKey = "widgetHabits"

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            configuration: ConfigurationAppIntent(),
            habits: [
                WidgetHabitData(id: UUID(), name: "Exercise", icon: "figure.run", color: "#A855F7", isCompletedToday: true, currentStreak: 5),
                WidgetHabitData(id: UUID(), name: "Read", icon: "book.fill", color: "#10B981", isCompletedToday: false, currentStreak: 3),
                WidgetHabitData(id: UUID(), name: "Meditate", icon: "brain.head.profile", color: "#3B82F6", isCompletedToday: true, currentStreak: 7)
            ]
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let habits = loadHabits()
        return SimpleEntry(date: Date(), configuration: configuration, habits: habits)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let habits = loadHabits()
        let currentDate = Date()
        let calendar = Calendar.current

        var entries: [SimpleEntry] = []
        entries.append(SimpleEntry(date: currentDate, configuration: configuration, habits: habits))

        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: currentDate),
           let midnight = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: tomorrow) {
            entries.append(SimpleEntry(date: midnight, configuration: configuration, habits: habits))
        }

        let refreshDate = calendar.date(byAdding: .minute, value: 15, to: currentDate) ?? currentDate
        return Timeline(entries: entries, policy: .after(refreshDate))
    }

    private func loadHabits() -> [WidgetHabitData] {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: habitsKey),
              let habits = try? JSONDecoder().decode([WidgetHabitData].self, from: data) else {
            return []
        }
        return habits
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let habits: [WidgetHabitData]
}

// MARK: - Theme Colors

struct WidgetTheme {
    let colorScheme: ColorScheme

    var primaryPurple: Color { Color(hex: "#A855F7") }
    var primaryPink: Color { Color(hex: "#EC4899") }
    var successGreen: Color { Color(hex: "#10B981") }

    var primaryText: Color {
        colorScheme == .dark ? .white : Color(hex: "#1F1535")
    }

    var secondaryText: Color {
        colorScheme == .dark ? .white.opacity(0.6) : Color(hex: "#6B5B7A")
    }

    var cardBackground: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.08)
            : Color.white.opacity(0.7)
    }

    var cardBorder: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.1)
            : Color(hex: "#A855F7").opacity(0.15)
    }
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
            // Progress Ring
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
            // Left side - Progress Ring
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

            // Right side - Habits list
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

struct HabitRowMedium: View {
    let habit: WidgetHabitData
    let theme: WidgetTheme

    var habitColor: Color { Color(hex: habit.color) }

    var body: some View {
        HStack(spacing: 8) {
            // Icon
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

            // Completion
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
            // Header - more compact
            HStack(spacing: 10) {
                // Progress Ring - smaller
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

                    // Progress bar
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

            // Habits list
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

struct HabitRowLarge: View {
    let habit: WidgetHabitData
    let theme: WidgetTheme

    var habitColor: Color { Color(hex: habit.color) }

    var body: some View {
        HStack(spacing: 8) {
            // Icon - smaller
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

            // Completion - smaller
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
                Text("HabitFlow")
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

// MARK: - Widget Data Model

struct WidgetHabitData: Codable, Identifiable {
    let id: UUID
    let name: String
    let icon: String
    let color: String
    let isCompletedToday: Bool
    let currentStreak: Int
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
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
        .configurationDisplayName("HabitFlow")
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

            // Return placeholder if no habit selected
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
            // Header
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

            // Compact Grid - 7 weeks x 7 days
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
            // Header
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

            // Full width grid
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

    private let columns = 16 // 16 weeks for medium widget
    private let rows = 7 // 7 days
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

    private let columns = 7 // 7 weeks for small widget
    private let rows = 7 // 7 days
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

// MARK: - Widget Background

struct WidgetBackground: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        if colorScheme == .dark {
            // Dark mode: deep purple gradient
            LinearGradient(
                colors: [
                    Color(hex: "#1a1625"),
                    Color(hex: "#140f1f")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay(
                RadialGradient(
                    colors: [
                        Color(hex: "#A855F7").opacity(0.15),
                        Color.clear
                    ],
                    center: .topTrailing,
                    startRadius: 0,
                    endRadius: 200
                )
            )
            .overlay(
                RadialGradient(
                    colors: [
                        Color(hex: "#EC4899").opacity(0.1),
                        Color.clear
                    ],
                    center: .bottomLeading,
                    startRadius: 0,
                    endRadius: 150
                )
            )
        } else {
            // Light mode: soft lavender/white
            LinearGradient(
                colors: [
                    Color(hex: "#FAF8FC"),
                    Color(hex: "#F3EEF8")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay(
                RadialGradient(
                    colors: [
                        Color(hex: "#A855F7").opacity(0.08),
                        Color.clear
                    ],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 150
                )
            )
            .overlay(
                RadialGradient(
                    colors: [
                        Color(hex: "#EC4899").opacity(0.06),
                        Color.clear
                    ],
                    center: .bottomTrailing,
                    startRadius: 0,
                    endRadius: 120
                )
            )
        }
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
        ]
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
        ]
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
        ]
    )
}
