//
//  EditHabitView.swift
//  HabitTracker
//
//  Created by Sebastián Kučera on 13.01.2026.
//

import SwiftUI
import SwiftData

struct EditHabitView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var themeManager = ThemeManager.shared

    let habit: Habit

    @State private var name: String
    @State private var selectedIcon: String
    @State private var selectedColor: String
    @State private var hasGoal: Bool
    @State private var dailyGoal: Double

    // Goal Progression
    @State private var goalProgression: GoalProgression
    @State private var goalIncrement: Double
    @State private var goalIncrementInterval: Int
    @State private var selectedRestDays: Set<Int>
    @State private var showGoalProgressionOptions = false

    // Focus Session
    @State private var focusEnabled: Bool

    let icons = [
        "checkmark.circle.fill", "star.fill", "heart.fill", "bolt.fill",
        "flame.fill", "drop.fill", "leaf.fill", "moon.fill",
        "sun.max.fill", "figure.run", "figure.walk", "dumbbell.fill",
        "book.fill", "pencil", "brain.head.profile", "bed.double.fill",
        "cup.and.saucer.fill", "fork.knife", "pills.fill", "cross.fill"
    ]

    let colors = [
        "#A855F7", "#EC4899", "#06B6D4", "#34D399",
        "#F59E0B", "#EF4444", "#8B5CF6", "#3B82F6",
        "#10B981", "#F472B6"
    ]

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
        themeManager.primaryColor
    }

    init(habit: Habit) {
        self.habit = habit
        _name = State(initialValue: habit.name)
        _selectedIcon = State(initialValue: habit.icon)
        _selectedColor = State(initialValue: habit.color)
        _hasGoal = State(initialValue: habit.dailyGoal != nil)
        _dailyGoal = State(initialValue: habit.dailyGoal ?? 0)

        // Goal progression
        _goalProgression = State(initialValue: habit.goalProgression)
        _goalIncrement = State(initialValue: habit.goalIncrement ?? 0)
        _goalIncrementInterval = State(initialValue: habit.goalIncrementIntervalDays ?? 7)
        _selectedRestDays = State(initialValue: Set(habit.restDays ?? []))

        // Focus session
        _focusEnabled = State(initialValue: habit.focusEnabled)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Floating clouds background
                FloatingClouds()

                ScrollView {
                    VStack(spacing: 24) {
                        // Preview
                        previewSection

                        // Name Input
                        nameSection

                        // Goal Section (for non-manual types)
                        if habit.habitType != .manual {
                            goalSection
                        }

                        // Goal Progression (for habits with goals)
                        if hasGoal && habit.habitType != .manual {
                            goalProgressionSection
                        }

                        // Rest Days Section
                        restDaysSection

                        // Focus Session Section (only for manual habits)
                        if habit.habitType == .manual {
                            focusSessionSection
                        }

                        // Icon Picker
                        iconSection

                        // Color Picker
                        colorSection
                    }
                    .padding(20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Edit Habit")
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

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveChanges()
                    } label: {
                        Text("Save")
                            .fontWeight(.semibold)
                            .foregroundStyle(canSave ? accentColor : tertiaryText)
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: selectedColor).opacity(colorScheme == .dark ? 0.3 : 0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: selectedIcon)
                    .font(.system(size: 40))
                    .foregroundStyle(Color(hex: selectedColor))
            }

            Text(name.isEmpty ? "Habit Name" : name)
                .font(.title3.weight(.semibold))
                .foregroundStyle(name.isEmpty ? tertiaryText : primaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .liquidGlass(cornerRadius: 24)
    }

    // MARK: - Name Section

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Name")
                .font(.headline)
                .foregroundStyle(primaryText)

            TextField("e.g., Exercise, Read, Meditate", text: $name)
                .font(.body)
                .foregroundStyle(primaryText)
                .padding(16)
                .liquidGlass(cornerRadius: 12)
        }
    }

    // MARK: - Goal Section

    private var goalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Daily Goal")
                    .font(.headline)
                    .foregroundStyle(primaryText)

                Spacer()

                Toggle("", isOn: $hasGoal)
                    .tint(accentColor)
                    .labelsHidden()
            }

            if hasGoal {
                GoalSliderView(
                    value: $dailyGoal,
                    range: goalRangeForType,
                    step: goalStepForType,
                    unit: habit.unit ?? "",
                    color: Color(hex: selectedColor)
                )
            }
        }
        .padding(16)
        .liquidGlass(cornerRadius: 20)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: hasGoal)
    }

    private var goalRangeForType: ClosedRange<Double> {
        switch habit.habitType {
        case .healthKitSleep: return 4...12
        case .healthKitWater: return 500...4000
        case .healthKitCalories: return 100...3000
        default: return 1...100
        }
    }

    private var goalStepForType: Double {
        switch habit.habitType {
        case .healthKitSleep: return 0.5
        case .healthKitWater: return 100
        case .healthKitCalories: return 100
        default: return 1
        }
    }

    // MARK: - Goal Progression Section

    private var goalProgressionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Goal Progression")
                    .font(.headline)
                    .foregroundStyle(primaryText)

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.3)) {
                        showGoalProgressionOptions.toggle()
                    }
                } label: {
                    Image(systemName: showGoalProgressionOptions ? "chevron.up" : "chevron.down")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(accentColor)
                }
            }

            // Progression type pills
            HStack(spacing: 10) {
                ForEach(GoalProgression.allCases, id: \.rawValue) { progression in
                    GoalProgressionPill(
                        progression: progression,
                        isSelected: goalProgression == progression,
                        accentColor: accentColor,
                        primaryText: primaryText,
                        secondaryText: secondaryText,
                        colorScheme: colorScheme
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            goalProgression = progression
                            if progression == .rampUp && goalIncrement == 0 {
                                goalIncrement = defaultIncrement
                            }
                        }
                    }
                }
            }

            // Expanded options
            if showGoalProgressionOptions {
                VStack(alignment: .leading, spacing: 12) {
                    Text(goalProgression.description)
                        .font(.caption)
                        .foregroundStyle(secondaryText)
                        .padding(.vertical, 4)

                    if goalProgression == .rampUp {
                        rampUpOptions
                    }

                    if goalProgression == .adaptive {
                        adaptiveExplanation
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .liquidGlass(cornerRadius: 20)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: goalProgression)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showGoalProgressionOptions)
    }

    private var defaultIncrement: Double {
        switch habit.habitType {
        case .healthKitSleep: return 0.5
        case .healthKitWater: return 250
        case .healthKitCalories: return 100
        default: return 1
        }
    }

    private var rampUpOptions: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Increase by")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(primaryText)

                HStack {
                    Slider(value: $goalIncrement, in: incrementRange, step: incrementStep)
                        .tint(accentColor)

                    Text("\(formatIncrement(goalIncrement)) \(habit.unit ?? "")")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(accentColor)
                        .frame(width: 80, alignment: .trailing)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Every")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(primaryText)

                HStack(spacing: 8) {
                    ForEach([7, 14, 21, 30], id: \.self) { days in
                        Button {
                            goalIncrementInterval = days
                        } label: {
                            Text("\(days)d")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(goalIncrementInterval == days ? .white : secondaryText)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(goalIncrementInterval == days ? accentColor : accentColor.opacity(0.15))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var incrementRange: ClosedRange<Double> {
        switch habit.habitType {
        case .healthKitSleep: return 0.25...2
        case .healthKitWater: return 100...500
        case .healthKitCalories: return 50...500
        default: return 1...10
        }
    }

    private var incrementStep: Double {
        switch habit.habitType {
        case .healthKitSleep: return 0.25
        case .healthKitWater: return 50
        case .healthKitCalories: return 50
        default: return 1
        }
    }

    private func formatIncrement(_ value: Double) -> String {
        if value == floor(value) {
            return "\(Int(value))"
        }
        return String(format: "%.2g", value)
    }

    private var adaptiveExplanation: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundStyle(.green)
                Text("Goal increases when you consistently exceed it")
                    .font(.caption)
                    .foregroundStyle(secondaryText)
            }

            HStack(spacing: 8) {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundStyle(.orange)
                Text("Goal decreases if you're struggling")
                    .font(.caption)
                    .foregroundStyle(secondaryText)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
        )
    }

    // MARK: - Focus Session Section

    private var focusSessionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "timer")
                            .foregroundStyle(accentColor)
                        Text("Focus Sessions")
                            .font(.headline)
                            .foregroundStyle(primaryText)
                    }

                    Text("Use a timer to stay focused on this habit")
                        .font(.caption)
                        .foregroundStyle(secondaryText)
                }

                Spacer()

                Toggle("", isOn: $focusEnabled)
                    .tint(accentColor)
                    .labelsHidden()
            }

            if focusEnabled {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                    Text("A timer button will appear on the habit card")
                        .font(.caption)
                }
                .foregroundStyle(accentColor)
            }
        }
        .padding(16)
        .liquidGlass(cornerRadius: 20)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: focusEnabled)
    }

    // MARK: - Rest Days Section

    private var restDaysSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rest Days")
                        .font(.headline)
                        .foregroundStyle(primaryText)

                    Text("Streak won't break on rest days")
                        .font(.caption)
                        .foregroundStyle(secondaryText)
                }

                Spacer()
            }

            HStack(spacing: 6) {
                ForEach(RestDayOption.allDays) { day in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            if selectedRestDays.contains(day.id) {
                                selectedRestDays.remove(day.id)
                            } else {
                                selectedRestDays.insert(day.id)
                            }
                        }
                    } label: {
                        Text(day.shortName)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(selectedRestDays.contains(day.id) ? .white : secondaryText)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(selectedRestDays.contains(day.id) ? accentColor : accentColor.opacity(0.15))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            if !selectedRestDays.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                    Text("\(selectedRestDays.count) rest day\(selectedRestDays.count == 1 ? "" : "s") per week")
                        .font(.caption)
                }
                .foregroundStyle(accentColor)
            }
        }
        .padding(16)
        .liquidGlass(cornerRadius: 20)
    }

    // MARK: - Icon Section

    private var iconSection: some View {
        let cardBackground = colorScheme == .dark ? Color.white.opacity(0.1) : Color(red: 0.9, green: 0.88, blue: 0.95)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Icon")
                .font(.headline)
                .foregroundStyle(primaryText)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                ForEach(icons, id: \.self) { icon in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedIcon = icon
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedIcon == icon
                                      ? Color(hex: selectedColor)
                                      : cardBackground)
                                .frame(width: 56, height: 56)

                            Image(systemName: icon)
                                .font(.title3)
                                .foregroundStyle(selectedIcon == icon
                                                 ? .white
                                                 : Color(hex: selectedColor))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .liquidGlass(cornerRadius: 20)
        }
    }

    // MARK: - Color Section

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Color")
                .font(.headline)
                .foregroundStyle(primaryText)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                ForEach(colors, id: \.self) { color in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedColor = color
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 50, height: 50)

                            if selectedColor == color {
                                Circle()
                                    .stroke(.white, lineWidth: 3)
                                    .frame(width: 50, height: 50)

                                Image(systemName: "checkmark")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .liquidGlass(cornerRadius: 20)
        }
    }

    // MARK: - Actions

    private func saveChanges() {
        habit.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        habit.icon = selectedIcon
        habit.color = selectedColor
        habit.dailyGoal = hasGoal ? dailyGoal : nil

        // Goal progression
        habit.goalProgression = goalProgression
        if habit.initialGoal == nil && hasGoal {
            habit.initialGoal = dailyGoal
        }

        if goalProgression == .rampUp {
            habit.goalIncrement = goalIncrement
            habit.goalIncrementIntervalDays = goalIncrementInterval
        } else {
            habit.goalIncrement = nil
            habit.goalIncrementIntervalDays = nil
        }

        // Rest days
        if !selectedRestDays.isEmpty {
            habit.restDays = Array(selectedRestDays).sorted()
            habit.restDaysPerWeek = selectedRestDays.count
        } else {
            habit.restDays = nil
            habit.restDaysPerWeek = nil
        }

        // Focus session
        habit.focusEnabled = focusEnabled

        // Notify widgets
        NotificationCenter.default.post(name: .habitsDidChange, object: nil)

        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, configurations: config)

    let habit = Habit(name: "Exercise", icon: "figure.run", color: "#A855F7")
    container.mainContext.insert(habit)

    return EditHabitView(habit: habit)
        .modelContainer(container)
}
