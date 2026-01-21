//
//  LargeProgressRing.swift
//  HabitTracker
//
//  Created by Sebastián Kučera on 13.01.2026.
//

import SwiftUI

struct LargeProgressRing: View {
    let progress: Double
    let completed: Int
    let total: Int

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(
                    Color.white.opacity(0.1),
                    lineWidth: 12
                )

            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AppTheme.Gradients.accentGradient,
                    style: StrokeStyle(
                        lineWidth: 12,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)

            // Inner glow effect
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AppTheme.Colors.accentPrimary.opacity(0.3),
                    style: StrokeStyle(
                        lineWidth: 20,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .blur(radius: 8)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)

            // Center content
            VStack(spacing: 4) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .contentTransition(.numericText())

                Text("\(completed)/\(total)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .contentTransition(.numericText())
            }
        }
        .frame(width: 120, height: 120)
    }
}

// MARK: - Category Progress Row

struct CategoryProgressRow: View {
    let category: String
    let icon: String
    let color: Color
    let completed: Int
    let total: Int

    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(color)
            }

            // Label and progress
            VStack(alignment: .leading, spacing: 4) {
                Text(category)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 4)

                        Capsule()
                            .fill(color)
                            .frame(width: geo.size.width * progress, height: 4)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progress)
                    }
                }
                .frame(height: 4)
            }

            // Count
            Text("\(completed)/\(total)")
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .frame(width: 35, alignment: .trailing)
        }
    }
}

// MARK: - Split Progress Header

struct SplitProgressHeader: View {
    let habits: [Habit]

    private var completedToday: Int {
        habits.filter { $0.isCompletedToday }.count
    }

    private var totalHabits: Int {
        habits.count
    }

    private var progress: Double {
        guard totalHabits > 0 else { return 0 }
        return Double(completedToday) / Double(totalHabits)
    }

    // Group habits by type for category display
    private var categories: [(name: String, icon: String, color: Color, completed: Int, total: Int)] {
        var result: [(name: String, icon: String, color: Color, completed: Int, total: Int)] = []

        // Manual habits
        let manualHabits = habits.filter { $0.habitType == .manual }
        if !manualHabits.isEmpty {
            let completed = manualHabits.filter { $0.isCompletedToday }.count
            result.append(("Habits", "checkmark.circle", AppTheme.Colors.accentPrimary, completed, manualHabits.count))
        }

        // Sleep habits
        let sleepHabits = habits.filter { $0.habitType == .healthKitSleep }
        if !sleepHabits.isEmpty {
            let completed = sleepHabits.filter { $0.isCompletedToday }.count
            result.append(("Sleep", "moon.fill", .indigo, completed, sleepHabits.count))
        }

        // Water habits
        let waterHabits = habits.filter { $0.habitType == .healthKitWater }
        if !waterHabits.isEmpty {
            let completed = waterHabits.filter { $0.isCompletedToday }.count
            result.append(("Water", "drop.fill", .cyan, completed, waterHabits.count))
        }

        // Calories habits
        let calorieHabits = habits.filter { $0.habitType == .healthKitCalories }
        if !calorieHabits.isEmpty {
            let completed = calorieHabits.filter { $0.isCompletedToday }.count
            result.append(("Calories", "flame.fill", .orange, completed, calorieHabits.count))
        }

        return result
    }

    var body: some View {
        HStack(spacing: 20) {
            // Left: Categories
            VStack(alignment: .leading, spacing: 12) {
                Text("Today's Progress")
                    .font(.headline)
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                if categories.isEmpty {
                    Text("Add habits to track")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                } else {
                    ForEach(categories, id: \.name) { category in
                        CategoryProgressRow(
                            category: category.name,
                            icon: category.icon,
                            color: category.color,
                            completed: category.completed,
                            total: category.total
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Right: Large ring
            LargeProgressRing(
                progress: progress,
                completed: completedToday,
                total: totalHabits
            )
        }
        .padding(20)
        .frostedCard(cornerRadius: 24)
    }
}

// MARK: - Progress Card (adapts to light/dark mode)

struct WhiteProgressCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let habits: [Habit]
    var showDynamicBackground: Bool = false

    private var completedToday: Int {
        habits.filter { $0.isCompletedToday }.count
    }

    private var totalHabits: Int {
        habits.count
    }

    private var progress: Double {
        guard totalHabits > 0 else { return 0 }
        return Double(completedToday) / Double(totalHabits)
    }

    // Group habits by type for category display (purple/cyan theme colors)
    // Limited to max 3 categories
    private var categories: [(name: String, icon: String, color: Color, completed: Int, total: Int)] {
        var result: [(name: String, icon: String, color: Color, completed: Int, total: Int)] = []

        // Manual habits - soft purple
        let manualHabits = habits.filter { $0.habitType == .manual }
        if !manualHabits.isEmpty {
            let completed = manualHabits.filter { $0.isCompletedToday }.count
            result.append(("Habits", "checkmark.circle.fill", Color(red: 0.65, green: 0.45, blue: 0.85), completed, manualHabits.count))
        }

        // Sleep habits - indigo/violet
        let sleepHabits = habits.filter { $0.habitType == .healthKitSleep }
        if !sleepHabits.isEmpty {
            let completed = sleepHabits.filter { $0.isCompletedToday }.count
            result.append(("Sleep", "moon.fill", Color(red: 0.45, green: 0.35, blue: 0.75), completed, sleepHabits.count))
        }

        // Water habits - cyan/teal
        let waterHabits = habits.filter { $0.habitType == .healthKitWater }
        if !waterHabits.isEmpty {
            let completed = waterHabits.filter { $0.isCompletedToday }.count
            result.append(("Water", "drop.fill", Color(red: 0.40, green: 0.75, blue: 0.80), completed, waterHabits.count))
        }

        // Calories habits - orange
        let calorieHabits = habits.filter { $0.habitType == .healthKitCalories }
        if !calorieHabits.isEmpty {
            let completed = calorieHabits.filter { $0.isCompletedToday }.count
            result.append(("Calories", "flame.fill", Color(red: 0.95, green: 0.55, blue: 0.25), completed, calorieHabits.count))
        }

        // Limit to max 3 categories
        return Array(result.prefix(3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                // Left: Categories
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(categories, id: \.name) { category in
                        WhiteCategoryRow(
                            category: category.name,
                            icon: category.icon,
                            color: category.color,
                            completed: category.completed,
                            total: category.total,
                            showDynamicBackground: showDynamicBackground
                        )
                    }

                    if categories.isEmpty {
                        Text("Add habits to track")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Right: Compact colorful ring
                WhiteProgressRing(
                    progress: progress,
                    completed: completedToday,
                    total: totalHabits,
                    showDynamicBackground: showDynamicBackground
                )
            }
        }
        .padding(20)
    }
}

// MARK: - Category Row (adapts to light/dark mode)

struct WhiteCategoryRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let category: String
    let icon: String
    let color: Color
    let completed: Int
    let total: Int
    var showDynamicBackground: Bool = false

    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    var body: some View {
        HStack(spacing: 8) {
            // Icon with circular background
            ZStack {
                Circle()
                    .fill(color.opacity(colorScheme == .dark ? 0.25 : 0.15))
                    .frame(width: 28, height: 28)

                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(color)
            }

            // Label - fixed width for consistent progress bar length
            Text(category)
                .font(.caption.weight(.medium))
                .foregroundStyle(showDynamicBackground ? .white : (colorScheme == .dark
                    ? Color.white
                    : Color(red: 0.25, green: 0.20, blue: 0.35)))
                .lineLimit(1)
                .frame(width: 50, alignment: .leading)

            // Progress bar - takes remaining space
            Capsule()
                .fill(colorScheme == .dark
                    ? Color.white.opacity(0.15)
                    : Color(red: 0.85, green: 0.82, blue: 0.90).opacity(0.5))
                .frame(height: 5)
                .overlay(alignment: .leading) {
                    GeometryReader { geo in
                        Capsule()
                            .fill(color)
                            .frame(width: geo.size.width * progress, height: 5)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progress)
                    }
                }

            // Count display - fixed width for alignment
            Text("\(completed)/\(total)")
                .font(.caption2.weight(.medium))
                .foregroundStyle(showDynamicBackground ? .white.opacity(0.8) : (colorScheme == .dark
                    ? Color.white.opacity(0.7)
                    : Color(red: 0.45, green: 0.40, blue: 0.55)))
                .frame(width: 28, alignment: .trailing)
        }
        .padding(.horizontal, showDynamicBackground ? 10 : 0)
        .padding(.vertical, showDynamicBackground ? 6 : 0)
        .background {
            if showDynamicBackground {
                Capsule()
                    .fill(Color.black.opacity(0.3))
            }
        }
    }
}

// MARK: - Progress Ring (adapts to light/dark mode)

struct WhiteProgressRing: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var themeManager = ThemeManager.shared
    let progress: Double
    let completed: Int
    let total: Int
    var showDynamicBackground: Bool = false

    // Dynamic gradient colors based on theme
    private var progressGradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: [
                themeManager.primaryColor,
                themeManager.secondaryColor,
                themeManager.primaryColor
            ]),
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(270)
        )
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(colorScheme == .dark
                    ? Color.white.opacity(0.15)
                    : Color(red: 0.85, green: 0.82, blue: 0.90).opacity(0.5),
                    lineWidth: 10)

            // Glow effect (blurred progress arc)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [
                            themeManager.primaryColor.opacity(0.6),
                            themeManager.secondaryColor.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .blur(radius: 8)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)

            // Progress arc with gradient
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progressGradient,
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)

            // Center content
            VStack(spacing: 2) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(showDynamicBackground ? .white : (colorScheme == .dark
                        ? Color.white
                        : Color(red: 0.25, green: 0.20, blue: 0.35)))
                    .contentTransition(.numericText())

                Text("\(completed)/\(total)")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(showDynamicBackground ? .white.opacity(0.8) : (colorScheme == .dark
                        ? Color.white.opacity(0.6)
                        : Color(red: 0.50, green: 0.45, blue: 0.60)))
            }
        }
        .frame(width: 100, height: 100)
        .background {
            if showDynamicBackground {
                Circle()
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 110, height: 110)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.white
            .ignoresSafeArea()

        VStack(spacing: 20) {
            WhiteProgressRing(progress: 0.78, completed: 3, total: 4, showDynamicBackground: false)
        }
    }
}
