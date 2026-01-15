//
//  HabitCard.swift
//  HabitTracker
//
//  Created by Sebastián Kučera on 12.01.2026.
//

import SwiftUI
import SwiftData

// MARK: - Habit Card

struct HabitCard: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var habit: Habit
    var stack: HabitStack?
    var stackPosition: (current: Int, total: Int)?
    var onStartFocus: (() -> Void)?
    @State private var showingValueEntry = false
    @State private var showingDetail = false

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : Color(hex: "#1F2937")
    }

    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.7) : Color(hex: "#6B7280")
    }

    var body: some View {
        HStack(spacing: 16) {
            // Left side: Navigation button (icon + info)
            Button {
                showingDetail = true
            } label: {
                HStack(spacing: 16) {
                    // Icon with chain indicator
                    ZStack(alignment: .bottomTrailing) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: habit.color).opacity(colorScheme == .dark ? 0.3 : 0.2))
                                .frame(width: 50, height: 50)

                            Image(systemName: habit.icon)
                                .font(.title3)
                                .foregroundStyle(Color(hex: habit.color))
                        }

                        // Chain indicator badge on icon
                        if let stack = stack, let position = stackPosition {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: stack.color))
                                    .frame(width: 18, height: 18)

                                Text("\(position.current)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            .offset(x: 4, y: 4)
                        }
                    }

                    // Info
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(habit.name)
                                .font(.headline)
                                .foregroundStyle(primaryTextColor)

                            // HealthKit badge
                            if habit.dataSource == .healthKit {
                                Image(systemName: "heart.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.red)
                            }
                        }

                        // Show value/goal for HealthKit habits, streak for manual
                        if habit.habitType != .manual, let goal = habit.dailyGoal {
                            HStack(spacing: 4) {
                                let value = habit.todayValue ?? 0
                                Text(formatValue(value, unit: habit.unit))
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(primaryTextColor.opacity(0.85))

                                Text("/ \(formatValue(goal, unit: habit.unit))")
                                    .font(.caption)
                                    .foregroundStyle(secondaryTextColor)
                            }
                        } else {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .font(.caption)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.orange, .red],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )

                                Text("\(habit.currentStreak) day streak")
                                    .font(.caption)
                                    .foregroundStyle(secondaryTextColor)
                            }
                        }

                        // Chain membership indicator
                        if let stack = stack, let position = stackPosition {
                            HStack(spacing: 4) {
                                Image(systemName: "link")
                                    .font(.caption2)
                                    .foregroundStyle(Color(hex: stack.color))

                                Text("\(stack.name) • Step \(position.current)/\(position.total)")
                                    .font(.caption2)
                                    .foregroundStyle(Color(hex: stack.color))
                            }
                        }
                    }

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Right side: Focus button + Progress/Checkmark Button
            HStack(spacing: 8) {
                // Focus button (only if enabled and not completed yet)
                if habit.focusEnabled && !habit.isCompletedToday {
                    Button {
                        onStartFocus?()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color(hex: habit.color).opacity(colorScheme == .dark ? 0.2 : 0.1))
                                .frame(width: 36, height: 36)

                            Image(systemName: "timer")
                                .font(.subheadline)
                                .foregroundStyle(Color(hex: habit.color))
                        }
                    }
                    .buttonStyle(.plain)
                }

                if habit.habitType != .manual, habit.dailyGoal != nil {
                    // Progress ring for HealthKit habits with goals
                    progressRing
                        .frame(width: 54, height: 54)
                } else {
                    // Standard checkmark for manual habits
                    CheckmarkTapView(
                        isCompleted: habit.isCompletedToday,
                        color: habit.color,
                        colorScheme: colorScheme,
                        onTap: {
                            let wasCompleted = habit.isCompletedToday
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                toggleCompletion()
                            }
                            if wasCompleted {
                                HapticManager.shared.habitUncompleted()
                            } else {
                                HapticManager.shared.habitCompleted()
                                checkAllHabitsCompleted()
                            }
                        }
                    )
                }
            }
        }
        .padding(16)
        .liquidGlass(cornerRadius: 24)
        .sheet(isPresented: $showingValueEntry) {
            ValueEntryView(habit: habit)
        }
        .navigationDestination(isPresented: $showingDetail) {
            HabitDetailView(habit: habit)
        }
    }

    // MARK: - Progress Ring

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(colorScheme == .dark ? Color.white.opacity(0.15) : Color.gray.opacity(0.2), lineWidth: 4)
                .frame(width: 48, height: 48)

            Circle()
                .trim(from: 0, to: min(habit.todayProgress, 1.0))
                .stroke(
                    Color(hex: habit.color),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 48, height: 48)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: habit.todayProgress)

            if habit.isCompletedToday {
                Image(systemName: "checkmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color(hex: habit.color))
                    .transition(.scale.combined(with: .opacity))
            } else {
                Text("\(Int(habit.todayProgress * 100))%")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(secondaryTextColor)
                    .contentTransition(.numericText())
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: habit.isCompletedToday)
    }

    // MARK: - Helpers

    private func formatValue(_ value: Double, unit: String?) -> String {
        switch unit {
        case "hours":
            let hours = Int(value)
            let minutes = Int((value - Double(hours)) * 60)
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            }
            return "\(hours)h"
        case "ml":
            if value >= 1000 {
                return String(format: "%.1fL", value / 1000)
            }
            return "\(Int(value))ml"
        case "kcal":
            return "\(Int(value)) kcal"
        default:
            return String(format: "%.1f", value)
        }
    }

    private func toggleCompletion() {
        let calendar = Calendar.current
        if habit.isCompletedToday {
            if let todayCompletion = habit.completions.first(where: { calendar.isDateInToday($0.date) }) {
                habit.completions.removeAll { $0.id == todayCompletion.id }
                modelContext.delete(todayCompletion)
            }
        } else {
            let completion = HabitCompletion(date: Date(), habit: habit)
            habit.completions.append(completion)
            modelContext.insert(completion)
        }

        try? modelContext.save()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NotificationCenter.default.post(name: .habitsDidChange, object: nil)
        }
    }

    private func checkAllHabitsCompleted() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            do {
                let descriptor = FetchDescriptor<Habit>()
                let allHabits = try modelContext.fetch(descriptor)

                let allCompleted = allHabits.allSatisfy { $0.isCompletedToday }

                if allCompleted && !allHabits.isEmpty {
                    HapticManager.shared.allHabitsCompleted()
                    NotificationCenter.default.post(name: .allHabitsCompleted, object: nil)
                }
            } catch {
                print("Failed to check all habits: \(error)")
            }
        }
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Checkmark Tap View

struct CheckmarkTapView: View {
    let isCompleted: Bool
    let color: String
    let colorScheme: ColorScheme
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            onTap()
        }) {
            ZStack {
                Circle()
                    .fill(isCompleted
                          ? Color(hex: color)
                          : colorScheme == .dark ? Color.white.opacity(0.1) : Color.gray.opacity(0.15))
                    .frame(width: 44, height: 44)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Circle()
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.25) : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 44, height: 44)
                }
            }
            .frame(width: 54, height: 54)
            .contentShape(Circle())
        }
        .buttonStyle(CheckmarkButtonStyle(isCompleted: isCompleted))
    }
}

// MARK: - Checkmark Button Style

struct CheckmarkButtonStyle: ButtonStyle {
    let isCompleted: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isCompleted)
    }
}
