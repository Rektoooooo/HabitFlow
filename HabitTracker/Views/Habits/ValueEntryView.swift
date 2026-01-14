//
//  ValueEntryView.swift
//  HabitTracker
//
//  Created by Sebastián Kučera on 13.01.2026.
//

import SwiftUI
import SwiftData

struct ValueEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let habit: Habit

    @State private var inputValue: String = ""
    @FocusState private var isInputFocused: Bool

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

    private var accentColor: Color {
        Color(red: 0.65, green: 0.35, blue: 0.85)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Floating clouds background
                FloatingClouds(theme: .habitTracker(colorScheme))

                VStack(spacing: 32) {
                    Spacer()

                    // Habit Icon
                    ZStack {
                        Circle()
                            .fill(Color(hex: habit.color).opacity(colorScheme == .dark ? 0.3 : 0.2))
                            .frame(width: 100, height: 100)

                        Image(systemName: habit.icon)
                            .font(.system(size: 40))
                            .foregroundStyle(Color(hex: habit.color))
                    }

                    // Habit Name
                    Text(habit.name)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(primaryText)

                    // Progress Ring
                    if let goal = habit.dailyGoal {
                        progressSection(goal: goal)
                    }

                    // Input Section
                    VStack(spacing: 12) {
                        HStack(alignment: .lastTextBaseline, spacing: 8) {
                            TextField("0", text: $inputValue)
                                .keyboardType(habit.unit == "hours" ? .decimalPad : .numberPad)
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(primaryText)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 150)
                                .focused($isInputFocused)

                            Text(unitLabel)
                                .font(.title3)
                                .foregroundStyle(secondaryText)
                        }

                        // Quick Add Buttons
                        if let quickValues = quickAddValues {
                            HStack(spacing: 12) {
                                ForEach(quickValues, id: \.self) { value in
                                    QuickAddButton(
                                        value: value,
                                        unit: habit.unit,
                                        accentColor: accentColor
                                    ) {
                                        addToValue(value)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 20)

                    Spacer()

                    // Save Button
                    Button {
                        saveValue()
                    } label: {
                        Text("Save")
                    }
                    .primaryButtonStyle()
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Log \(habit.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(tertiaryText)
                    }
                }
            }
            .onAppear {
                // Pre-fill with today's value if exists
                if let currentValue = habit.todayValue {
                    inputValue = formatInputValue(currentValue)
                }
                isInputFocused = true
            }
        }
    }

    // MARK: - Progress Section

    private func progressSection(goal: Double) -> some View {
        let currentValue = Double(inputValue) ?? habit.todayValue ?? 0
        let progress = min(currentValue / goal, 1.0)
        let ringBackground = colorScheme == .dark ? Color.white.opacity(0.1) : Color(red: 0.9, green: 0.88, blue: 0.95)

        return VStack(spacing: 8) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(ringBackground, lineWidth: 8)
                    .frame(width: 120, height: 120)

                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Color(hex: habit.color),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: progress)

                // Percentage
                VStack(spacing: 2) {
                    Text("\(Int(progress * 100))%")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(primaryText)

                    if currentValue >= goal {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }

            Text("Goal: \(formatGoalValue(goal))")
                .font(.caption)
                .foregroundStyle(secondaryText)
        }
    }

    // MARK: - Quick Add Values

    private var quickAddValues: [Double]? {
        switch habit.unit {
        case "ml":
            return [250, 500, 750]
        case "kcal":
            return [100, 250, 500]
        case "hours":
            return [0.5, 1.0, 2.0]
        default:
            return nil
        }
    }

    private var unitLabel: String {
        switch habit.unit {
        case "ml": return "ml"
        case "kcal": return "kcal"
        case "hours": return "hours"
        default: return ""
        }
    }

    // MARK: - Helpers

    private func addToValue(_ amount: Double) {
        let current = Double(inputValue) ?? 0
        inputValue = formatInputValue(current + amount)
    }

    private func formatInputValue(_ value: Double) -> String {
        if habit.unit == "hours" {
            return String(format: "%.1f", value)
        }
        return String(Int(value))
    }

    private func formatGoalValue(_ goal: Double) -> String {
        switch habit.unit {
        case "ml":
            if goal >= 1000 {
                return String(format: "%.1fL", goal / 1000)
            }
            return "\(Int(goal))ml"
        case "kcal":
            return "\(Int(goal)) kcal"
        case "hours":
            return String(format: "%.1f hours", goal)
        default:
            return String(format: "%.1f", goal)
        }
    }

    private func saveValue() {
        guard let value = Double(inputValue), value > 0 else {
            dismiss()
            return
        }

        let calendar = Calendar.current

        // Update existing completion or create new one
        if let existing = habit.completions.first(where: { calendar.isDateInToday($0.date) }) {
            existing.value = value
            existing.isAutoSynced = false
        } else {
            let completion = HabitCompletion(
                date: Date(),
                habit: habit,
                value: value,
                isAutoSynced: false
            )
            modelContext.insert(completion)
        }

        // Notify widgets
        NotificationCenter.default.post(name: .habitsDidChange, object: nil)

        dismiss()
    }
}

// MARK: - Quick Add Button

struct QuickAddButton: View {
    let value: Double
    let unit: String?
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("+\(formattedValue)")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(accentColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(accentColor.opacity(0.15))
                )
        }
    }

    private var formattedValue: String {
        switch unit {
        case "ml":
            return "\(Int(value))ml"
        case "kcal":
            return "\(Int(value))"
        case "hours":
            if value < 1 {
                return "\(Int(value * 60))m"
            }
            return String(format: "%.1fh", value)
        default:
            return String(format: "%.0f", value)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, configurations: config)

    let habit = Habit(
        name: "Water",
        icon: "drop.fill",
        color: "#007AFF",
        habitType: .healthKitWater,
        dataSource: .manual,
        dailyGoal: 2000,
        unit: "ml"
    )

    return ValueEntryView(habit: habit)
        .modelContainer(container)
}
