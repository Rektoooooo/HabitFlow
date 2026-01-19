//
//  HabitFlowWatchWidget.swift
//  HabitFlowWatchWidget
//
//  Created by Sebastián Kučera on 14.01.2026.
//

import WidgetKit
import SwiftUI

// MARK: - Watch Habit Data

struct WatchHabitData: Codable, Identifiable {
    let id: UUID
    let name: String
    let icon: String
    let color: String
    var isCompletedToday: Bool
    let currentStreak: Int
}

// MARK: - Widget Entry

struct HabitWidgetEntry: TimelineEntry {
    let date: Date
    let habits: [WatchHabitData]

    var completedCount: Int {
        habits.filter { $0.isCompletedToday }.count
    }

    var totalCount: Int {
        habits.count
    }

    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    var nextHabit: WatchHabitData? {
        habits.first { !$0.isCompletedToday }
    }
}

// MARK: - Timeline Provider

struct HabitWidgetProvider: TimelineProvider {
    private let suiteName = "group.ic-servis.com.HabitTracker"
    private let habitsKey = "watchHabits"

    func placeholder(in context: Context) -> HabitWidgetEntry {
        HabitWidgetEntry(
            date: Date(),
            habits: [
                WatchHabitData(id: UUID(), name: "Meditation", icon: "brain.head.profile", color: "#A855F7", isCompletedToday: true, currentStreak: 5),
                WatchHabitData(id: UUID(), name: "Exercise", icon: "figure.run", color: "#10B981", isCompletedToday: false, currentStreak: 3)
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (HabitWidgetEntry) -> Void) {
        let entry = HabitWidgetEntry(date: Date(), habits: loadHabits())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitWidgetEntry>) -> Void) {
        let habits = loadHabits()
        let entry = HabitWidgetEntry(date: Date(), habits: habits)

        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

        completion(timeline)
    }

    private func loadHabits() -> [WatchHabitData] {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: habitsKey),
              let habits = try? JSONDecoder().decode([WatchHabitData].self, from: data) else {
            return []
        }
        return habits
    }
}

// MARK: - Widget Configuration

struct HabitFlowWatchWidget: Widget {
    let kind = "HabitFlowWatchWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitWidgetProvider()) { entry in
            HabitWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Dotti")
        .description("Track your daily habits")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCorner
        ])
    }
}

// MARK: - Entry View

struct HabitWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: HabitWidgetEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            AccessoryCircularView(entry: entry)
        case .accessoryRectangular:
            AccessoryRectangularView(entry: entry)
        case .accessoryInline:
            AccessoryInlineView(entry: entry)
        case .accessoryCorner:
            AccessoryCornerView(entry: entry)
        default:
            AccessoryCircularView(entry: entry)
        }
    }
}

// MARK: - Accessory Circular

struct AccessoryCircularView: View {
    let entry: HabitWidgetEntry

    var body: some View {
        Gauge(value: entry.progress) {
            Image(systemName: "checkmark.circle.fill")
        } currentValueLabel: {
            Text("\(entry.completedCount)")
                .font(.system(size: 16, weight: .bold))
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .tint(entry.completedCount == entry.totalCount ? .green : .purple)
    }
}

// MARK: - Accessory Rectangular

struct AccessoryRectangularView: View {
    let entry: HabitWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Header
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.caption2)

                Text("Dotti")
                    .font(.caption2.weight(.semibold))

                Spacer()

                Text("\(entry.completedCount)/\(entry.totalCount)")
                    .font(.caption2.weight(.bold))
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(entry.completedCount == entry.totalCount ? Color.green : Color.purple)
                        .frame(width: geometry.size.width * entry.progress, height: 4)
                }
            }
            .frame(height: 4)

            // Next habit or done message
            if let nextHabit = entry.nextHabit {
                HStack(spacing: 4) {
                    Image(systemName: nextHabit.icon)
                        .font(.caption2)
                    Text(nextHabit.name)
                        .font(.caption2)
                        .lineLimit(1)
                }
                .foregroundStyle(.secondary)
            } else if entry.totalCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                    Text("All done!")
                        .font(.caption2.weight(.medium))
                }
                .foregroundStyle(.green)
            } else {
                Text("No habits yet")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Accessory Inline

struct AccessoryInlineView: View {
    let entry: HabitWidgetEntry

    var body: some View {
        if entry.totalCount == 0 {
            Label("No habits", systemImage: "circle.dashed")
        } else if entry.completedCount == entry.totalCount {
            Label("All \(entry.totalCount) done!", systemImage: "checkmark.circle.fill")
        } else {
            Label("\(entry.completedCount)/\(entry.totalCount) habits", systemImage: "flame.fill")
        }
    }
}

// MARK: - Accessory Corner

struct AccessoryCornerView: View {
    let entry: HabitWidgetEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            Gauge(value: entry.progress) {
                Image(systemName: "checkmark.circle")
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(entry.completedCount == entry.totalCount ? .green : .purple)
        }
        .widgetLabel {
            Text("\(entry.completedCount)/\(entry.totalCount)")
        }
    }
}

#Preview(as: .accessoryCircular) {
    HabitFlowWatchWidget()
} timeline: {
    HabitWidgetEntry(date: Date(), habits: [
        WatchHabitData(id: UUID(), name: "Meditation", icon: "brain.head.profile", color: "#A855F7", isCompletedToday: true, currentStreak: 5),
        WatchHabitData(id: UUID(), name: "Exercise", icon: "figure.run", color: "#10B981", isCompletedToday: false, currentStreak: 3)
    ])
}
