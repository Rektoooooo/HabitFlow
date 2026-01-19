//
//  HabitDetailView.swift
//  HabitTracker
//
//  Created by Sebastián Kučera on 12.01.2026.
//

import SwiftUI
import SwiftData

struct HabitDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var goalManager = DynamicGoalManager.shared

    let habit: Habit

    // Adaptive colors
    private var primaryText: Color {
        colorScheme == .dark ? .white : Color(red: 0.2, green: 0.15, blue: 0.3)
    }

    private var secondaryText: Color {
        colorScheme == .dark ? .white.opacity(0.7) : Color(red: 0.4, green: 0.35, blue: 0.5)
    }

    private var tertiaryText: Color {
        colorScheme == .dark ? .white.opacity(0.5) : Color(red: 0.5, green: 0.45, blue: 0.6)
    }

    var body: some View {
        ZStack {
            // Floating clouds background
            FloatingClouds()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Goal Progression (if not fixed)
                    if habit.goalProgression != .fixed || habit.restDays != nil {
                        goalProgressionSection
                    }

                    // Stats Cards
                    statsSection

                    // Contribution Grid
                    gridSection

                    // Weekly Insights
                    weeklyInsightsSection
                }
                .padding(20)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 20) {
            ZStack {
                // Glow
                Circle()
                    .fill(Color(hex: habit.color))
                    .frame(width: 120, height: 120)
                    .blur(radius: 40)
                    .opacity(0.4)

                // Icon
                ZStack {
                    Circle()
                        .fill(Color(hex: habit.color).opacity(colorScheme == .dark ? 0.3 : 0.2))
                        .frame(width: 100, height: 100)

                    Image(systemName: habit.icon)
                        .font(.system(size: 44))
                        .foregroundStyle(Color(hex: habit.color))
                }
            }

            VStack(spacing: 8) {
                Text(habit.name)
                    .font(.title.weight(.bold))
                    .foregroundStyle(primaryText)

                Text("Started \(habit.createdAt.formatted(.dateTime.month().day().year()))")
                    .font(.subheadline)
                    .foregroundStyle(secondaryText)
            }
        }
        .padding(.vertical, 20)
    }

    // MARK: - Goal Progression

    private var goalProgressionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: habit.goalProgression.icon)
                    .font(.headline)
                    .foregroundStyle(Color(hex: habit.color))

                Text("Goal Settings")
                    .font(.headline)
                    .foregroundStyle(primaryText)

                Spacer()
            }

            VStack(spacing: 12) {
                // Progression type
                if habit.goalProgression != .fixed {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Progression")
                                .font(.caption)
                                .foregroundStyle(tertiaryText)
                            Text(habit.goalProgression.displayName)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(primaryText)
                        }

                        Spacer()

                        // Show progression info
                        if let info = goalManager.getProgressionInfo(for: habit) {
                            VStack(alignment: .trailing, spacing: 4) {
                                if habit.goalProgression == .rampUp {
                                    Text("Next increase")
                                        .font(.caption)
                                        .foregroundStyle(tertiaryText)
                                    if let days = info.daysUntilChange {
                                        Text("\(days) day\(days == 1 ? "" : "s")")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(Color(hex: habit.color))
                                    }
                                } else {
                                    Text(info.message)
                                        .font(.caption)
                                        .foregroundStyle(secondaryText)
                                        .multilineTextAlignment(.trailing)
                                }
                            }
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
                    )
                }

                // Ramp-up details
                if habit.goalProgression == .rampUp,
                   let increment = habit.goalIncrement,
                   let interval = habit.goalIncrementIntervalDays {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Increase Amount")
                                .font(.caption)
                                .foregroundStyle(tertiaryText)
                            Text("+\(formatGoalValue(increment)) \(habit.unit ?? "") every \(interval) days")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(primaryText)
                        }

                        Spacer()

                        Image(systemName: "arrow.up.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.green)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
                    )
                }

                // Rest days
                if let restDays = habit.restDays, !restDays.isEmpty {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Rest Days")
                                .font(.caption)
                                .foregroundStyle(tertiaryText)

                            HStack(spacing: 6) {
                                ForEach(RestDayOption.allDays) { day in
                                    Text(day.shortName.prefix(1))
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(restDays.contains(day.id) ? .white : tertiaryText)
                                        .frame(width: 24, height: 24)
                                        .background(
                                            Circle()
                                                .fill(restDays.contains(day.id)
                                                      ? Color(hex: habit.color)
                                                      : Color(hex: habit.color).opacity(0.15))
                                        )
                                }
                            }
                        }

                        Spacer()

                        if habit.isRestDayToday {
                            Text("Rest day today")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color(hex: habit.color))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color(hex: habit.color).opacity(0.2))
                                )
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
                    )
                }
            }
        }
        .padding(20)
        .liquidGlass(cornerRadius: 20)
    }

    private func formatGoalValue(_ value: Double) -> String {
        if value == floor(value) {
            return "\(Int(value))"
        }
        return String(format: "%.1f", value)
    }

    // MARK: - Stats

    private var statsSection: some View {
        let streakGradient = LinearGradient(
            colors: [Color(red: 1.0, green: 0.6, blue: 0.2), Color(red: 1.0, green: 0.4, blue: 0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        let cyanGradient = LinearGradient(
            colors: [Color(red: 0.0, green: 0.8, blue: 0.9), Color(red: 0.0, green: 0.6, blue: 0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        let successGradient = LinearGradient(
            colors: [Color(red: 0.2, green: 0.8, blue: 0.5), Color(red: 0.1, green: 0.7, blue: 0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        return HStack(spacing: 12) {
            StatCardNew(
                title: "Current",
                value: "\(habit.currentStreak)",
                subtitle: "days",
                gradient: streakGradient,
                primaryText: primaryText,
                secondaryText: secondaryText,
                tertiaryText: tertiaryText
            )

            StatCardNew(
                title: "Longest",
                value: "\(habit.longestStreak)",
                subtitle: "days",
                gradient: cyanGradient,
                primaryText: primaryText,
                secondaryText: secondaryText,
                tertiaryText: tertiaryText
            )

            StatCardNew(
                title: "Rate",
                value: "\(Int(habit.completionRate * 100))%",
                subtitle: "complete",
                gradient: successGradient,
                primaryText: primaryText,
                secondaryText: secondaryText,
                tertiaryText: tertiaryText
            )
        }
    }

    // MARK: - Grid

    private var gridSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity")
                .font(.headline)
                .foregroundStyle(primaryText)

            ContributionGridView(habit: habit)
        }
        .padding(20)
        .liquidGlass(cornerRadius: 20)
    }

    // MARK: - Weekly Insights

    private var weeklyInsightsSection: some View {
        WeeklyInsightsView(
            habit: habit,
            primaryText: primaryText,
            secondaryText: secondaryText,
            tertiaryText: tertiaryText
        )
    }
}

// MARK: - Stat Card New

struct StatCardNew: View {
    let title: String
    let value: String
    let subtitle: String
    let gradient: LinearGradient
    let primaryText: Color
    let secondaryText: Color
    let tertiaryText: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title.weight(.bold))
                .foregroundStyle(gradient)

            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(secondaryText)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(tertiaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .liquidGlass(cornerRadius: 16)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, configurations: config)

    let habit = Habit(name: "Exercise", icon: "figure.run", color: "#A855F7")
    container.mainContext.insert(habit)

    return NavigationStack {
        HabitDetailView(habit: habit)
    }
    .modelContainer(container)
}
