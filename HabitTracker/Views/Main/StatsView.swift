//
//  StatsView.swift
//  HabitTracker
//
//  Created by Sebastián Kučera on 12.01.2026.
//

import SwiftUI
import SwiftData

struct StatsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \Habit.createdAt, order: .reverse) private var habits: [Habit]
    @Query(sort: \FocusSession.startedAt, order: .reverse) private var focusSessions: [FocusSession]
    @ObservedObject private var insightsEngine = InsightsEngine.shared
    @ObservedObject private var focusManager = FocusSessionManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared

    @State private var insights: [Insight] = []
    @State private var showingInsights = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Floating clouds background
                FloatingClouds()

                if habits.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Overview Cards
                            overviewSection

                            // Focus Stats (if any sessions)
                            if !focusSessions.isEmpty {
                                focusStatsSection
                            }

                            // Insights Preview
                            if !insights.isEmpty {
                                insightsPreviewSection
                            }

                            // Weekly Chart
                            weeklySection

                            // Best Streaks
                            streaksSection
                        }
                        .padding(20)
                        .padding(.bottom, 60)
                    }
                    .onAppear {
                        refreshInsights()
                    }
                    .sheet(isPresented: $showingInsights) {
                        InsightsView()
                    }
                }
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(AppTheme.Gradients.accentGradient)
                    .frame(width: 100, height: 100)
                    .blur(radius: 30)
                    .opacity(0.5)

                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 50))
                    .foregroundStyle(AppTheme.Colors.textTertiary)
            }

            Text("No Stats Yet")
                .font(.title2.weight(.bold))
                .foregroundStyle(AppTheme.Colors.textPrimary)

            Text("Create habits and track them\nto see your statistics")
                .font(.subheadline)
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Overview Section

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overview")
                .font(.headline)
                .foregroundStyle(colorScheme == .dark ? .white : Color(red: 0.2, green: 0.15, blue: 0.3))

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    title: "Total Habits",
                    value: "\(habits.count)",
                    icon: "list.bullet",
                    color: AppTheme.Colors.accentPrimary
                )

                StatCard(
                    title: "Completed Today",
                    value: "\(habits.filter { $0.isCompletedToday }.count)",
                    icon: "checkmark.circle.fill",
                    color: AppTheme.Colors.success
                )

                StatCard(
                    title: "Best Streak",
                    value: "\(habits.map { $0.longestStreak }.max() ?? 0)",
                    icon: "flame.fill",
                    color: .orange
                )

                StatCard(
                    title: "Total Completions",
                    value: "\(habits.reduce(0) { $0 + $1.safeCompletions.count })",
                    icon: "star.fill",
                    color: .yellow
                )
            }
        }
    }

    // MARK: - Focus Stats Section

    private var focusStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "timer")
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: "#A855F7"))

                Text("Focus Time")
                    .font(.headline)
                    .foregroundStyle(colorScheme == .dark ? .white : Color(red: 0.2, green: 0.15, blue: 0.3))
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                FocusStatCard(
                    title: "Today",
                    value: focusManager.formatDuration(focusManager.getTodayFocusTime(sessions: focusSessions)),
                    icon: "sun.max.fill",
                    color: .orange
                )

                FocusStatCard(
                    title: "This Week",
                    value: focusManager.formatDuration(focusManager.getWeekFocusTime(sessions: focusSessions)),
                    icon: "calendar",
                    color: .blue
                )

                FocusStatCard(
                    title: "Total Time",
                    value: focusManager.formatDuration(focusManager.getTotalFocusTime(sessions: focusSessions)),
                    icon: "hourglass",
                    color: Color(hex: "#A855F7")
                )

                FocusStatCard(
                    title: "Sessions",
                    value: "\(focusManager.getSessionCount(sessions: focusSessions))",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }
        }
    }

    // MARK: - Weekly Section

    private var weeklySection: some View {
        let data = weeklyData
        let maxCompletions = max(data.map { $0.completions }.max() ?? 1, 1)
        let maxBarHeight: CGFloat = 100

        return VStack(alignment: .leading, spacing: 16) {
            Text("This Week")
                .font(.headline)
                .foregroundStyle(colorScheme == .dark ? .white : Color(red: 0.2, green: 0.15, blue: 0.3))

            VStack(spacing: 16) {
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(Array(data.enumerated()), id: \.element.day) { index, dayData in
                        VStack(spacing: 8) {
                            // Bar - scale based on max completions in the week
                            let barHeight = dayData.completions > 0
                                ? max(20, CGFloat(dayData.completions) / CGFloat(maxCompletions) * maxBarHeight)
                                : 8

                            RoundedRectangle(cornerRadius: 6)
                                .fill(dayData.isToday
                                      ? themeManager.primaryGradient
                                      : LinearGradient(colors: [colorScheme == .dark ? Color.white.opacity(0.2) : Color(red: 0.8, green: 0.75, blue: 0.9)], startPoint: .top, endPoint: .bottom))
                                .frame(height: barHeight)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.05),
                                    value: dayData.completions
                                )

                            // Day label
                            Text(dayData.day)
                                .font(.caption2)
                                .foregroundStyle(dayData.isToday
                                                 ? (colorScheme == .dark ? .white : Color(red: 0.2, green: 0.15, blue: 0.3))
                                                 : (colorScheme == .dark ? .white.opacity(0.5) : Color(red: 0.5, green: 0.45, blue: 0.6)))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 120, alignment: .bottom)

                // Legend
                HStack {
                    Circle()
                        .fill(themeManager.primaryGradient)
                        .frame(width: 8, height: 8)
                    Text("Today")
                        .font(.caption)
                        .foregroundStyle(colorScheme == .dark ? .white.opacity(0.7) : Color(red: 0.4, green: 0.35, blue: 0.5))

                    Spacer()

                    Text("Habits completed per day")
                        .font(.caption)
                        .foregroundStyle(colorScheme == .dark ? .white.opacity(0.5) : Color(red: 0.5, green: 0.45, blue: 0.6))
                }
            }
            .padding(20)
            .liquidGlass(cornerRadius: 24)
        }
    }

    // MARK: - Streaks Section

    private var streaksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Best Streaks")
                .font(.headline)
                .foregroundStyle(colorScheme == .dark ? .white : Color(red: 0.2, green: 0.15, blue: 0.3))

            VStack(spacing: 12) {
                ForEach(habits.sorted { $0.longestStreak > $1.longestStreak }.prefix(5)) { habit in
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: habit.color).opacity(colorScheme == .dark ? 0.3 : 0.2))
                                .frame(width: 44, height: 44)

                            Image(systemName: habit.icon)
                                .font(.body)
                                .foregroundStyle(Color(hex: habit.color))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(habit.name)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(colorScheme == .dark ? .white : Color(red: 0.2, green: 0.15, blue: 0.3))

                            Text("Current: \(habit.currentStreak) days")
                                .font(.caption)
                                .foregroundStyle(colorScheme == .dark ? .white.opacity(0.7) : Color(red: 0.4, green: 0.35, blue: 0.5))
                        }

                        Spacer()

                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)

                            Text("\(habit.longestStreak)")
                                .font(.headline)
                                .foregroundStyle(colorScheme == .dark ? .white : Color(red: 0.2, green: 0.15, blue: 0.3))
                        }
                    }
                    .padding(16)
                    .liquidGlass(cornerRadius: 16)
                }
            }
        }
    }

    // MARK: - Insights Preview Section

    private var insightsPreviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .font(.subheadline)
                        .foregroundStyle(.yellow)

                    Text("Insights")
                        .font(.headline)
                        .foregroundStyle(colorScheme == .dark ? .white : Color(red: 0.2, green: 0.15, blue: 0.3))
                }

                Spacer()

                Button {
                    showingInsights = true
                } label: {
                    Text("See all")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(themeManager.primaryColor)
                }
            }

            // Show top 3 insights
            VStack(spacing: 10) {
                ForEach(insights.prefix(3)) { insight in
                    CompactInsightCard(insight: insight)
                }
            }
        }
    }

    // MARK: - Refresh Insights

    private func refreshInsights() {
        insights = insightsEngine.generateInsights(for: habits)
    }

    // MARK: - Weekly Data

    private var weeklyData: [(day: String, completions: Int, isToday: Bool)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return (0..<7).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let dayName = date.formatted(.dateTime.weekday(.abbreviated))
            let completions = habits.reduce(0) { count, habit in
                count + habit.safeCompletions.filter { calendar.isDate($0.date, inSameDayAs: date) }.count
            }
            return (day: String(dayName.prefix(3)), completions: completions, isToday: daysAgo == 0)
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title.weight(.bold))
                    .foregroundStyle(colorScheme == .dark ? .white : Color(red: 0.2, green: 0.15, blue: 0.3))

                Text(title)
                    .font(.caption)
                    .foregroundStyle(colorScheme == .dark ? .white.opacity(0.7) : Color(red: 0.4, green: 0.35, blue: 0.5))
            }
        }
        .padding(16)
        .liquidGlass(cornerRadius: 20)
    }
}

// MARK: - Focus Stat Card

struct FocusStatCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(colorScheme == .dark ? .white : Color(red: 0.2, green: 0.15, blue: 0.3))

                Text(title)
                    .font(.caption)
                    .foregroundStyle(colorScheme == .dark ? .white.opacity(0.7) : Color(red: 0.4, green: 0.35, blue: 0.5))
            }
        }
        .padding(16)
        .liquidGlass(cornerRadius: 20)
    }
}

#Preview {
    StatsView()
        .modelContainer(for: [Habit.self, FocusSession.self], inMemory: true)
}
