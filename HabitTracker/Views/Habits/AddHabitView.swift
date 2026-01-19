//
//  AddHabitView.swift
//  HabitTracker
//
//  Created by Sebastián Kučera on 12.01.2026.
//

import SwiftUI
import SwiftData

struct AddHabitView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var healthKitManager = HealthKitManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared

    // Step management
    @State private var currentStep = 0 // 0 = type selection, 1 = details

    // Habit configuration
    @State private var selectedHabitType: HabitType = .manual
    @State private var selectedDataSource: HabitDataSource = .manual
    @State private var name = ""
    @State private var selectedIcon = "checkmark.circle.fill"
    @State private var selectedColor = "#A855F7"
    @State private var hasGoal = false
    @State private var dailyGoal: Double = 0

    // Goal Progression
    @State private var goalProgression: GoalProgression = .fixed
    @State private var goalIncrement: Double = 0
    @State private var goalIncrementInterval: Int = 7
    @State private var selectedRestDays: Set<Int> = []
    @State private var showGoalProgressionOptions = false

    // Focus Session
    @State private var focusEnabled = false

    // HealthKit permission
    @State private var showingHealthKitPermission = false

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

    var body: some View {
        NavigationStack {
            ZStack {
                // Floating clouds background
                FloatingClouds()

                if currentStep == 0 {
                    habitTypeSelection
                } else {
                    habitDetailsForm
                }
            }
            .navigationTitle(currentStep == 0 ? "Choose Type" : "New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        if currentStep > 0 {
                            withAnimation { currentStep = 0 }
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: currentStep > 0 ? "chevron.left" : "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(tertiaryText)
                    }
                    .accessibilityLabel(currentStep > 0 ? "Back" : "Close")
                    .accessibilityHint(currentStep > 0 ? "Double tap to go back to habit type selection" : "Double tap to close without saving")
                }

                if currentStep == 1 {
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            saveHabit()
                        } label: {
                            Text("Save")
                                .fontWeight(.semibold)
                                .foregroundStyle(canSave ? accentColor : tertiaryText)
                        }
                        .disabled(!canSave)
                        .accessibilityLabel("Save habit")
                        .accessibilityHint(canSave ? "Double tap to save this habit" : "Enter a name to save")
                    }
                }
            }
            .sheet(isPresented: $showingHealthKitPermission) {
                HealthKitPermissionView(
                    habitType: selectedHabitType,
                    onAuthorized: {
                        showingHealthKitPermission = false
                        selectedDataSource = .healthKit
                        withAnimation { currentStep = 1 }
                    },
                    onSkip: {
                        showingHealthKitPermission = false
                        selectedDataSource = .manual
                        withAnimation { currentStep = 1 }
                    }
                )
            }
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Step 1: Habit Type Selection

    private var habitTypeSelection: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Standard Habit
                HabitTypeCard(
                    title: "Standard Habit",
                    subtitle: "Track any habit with a simple checkmark",
                    icon: "checkmark.circle.fill",
                    color: accentColor,
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                    tertiaryText: tertiaryText,
                    colorScheme: colorScheme,
                    isSelected: false
                ) {
                    selectedHabitType = .manual
                    selectedDataSource = .manual
                    withAnimation { currentStep = 1 }
                }

                // Health Section Header
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                    Text("Health Tracking")
                        .font(.headline)
                        .foregroundStyle(primaryText)
                    Spacer()
                }
                .padding(.top, 12)

                // Sleep Tracking
                HabitTypeCard(
                    title: "Sleep",
                    subtitle: "Track hours of sleep",
                    icon: "bed.double.fill",
                    color: Color(hex: "#8B5CF6"),
                    badge: "Auto-sync",
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                    tertiaryText: tertiaryText,
                    colorScheme: colorScheme,
                    isSelected: false
                ) {
                    selectHealthKitType(.healthKitSleep, name: "Sleep", icon: "bed.double.fill", color: "#8B5CF6")
                }

                // Water Tracking
                HabitTypeCard(
                    title: "Water Intake",
                    subtitle: "Track daily hydration in ml",
                    icon: "drop.fill",
                    color: Color(hex: "#06B6D4"),
                    badge: "Auto-sync",
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                    tertiaryText: tertiaryText,
                    colorScheme: colorScheme,
                    isSelected: false
                ) {
                    selectHealthKitType(.healthKitWater, name: "Water", icon: "drop.fill", color: "#06B6D4")
                }

                // Calories Tracking
                HabitTypeCard(
                    title: "Calories",
                    subtitle: "Track dietary calories",
                    icon: "flame.fill",
                    color: Color(hex: "#F59E0B"),
                    badge: "Auto-sync",
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                    tertiaryText: tertiaryText,
                    colorScheme: colorScheme,
                    isSelected: false
                ) {
                    selectHealthKitType(.healthKitCalories, name: "Calories", icon: "flame.fill", color: "#F59E0B")
                }
            }
            .padding(20)
        }
    }

    private func selectHealthKitType(_ type: HabitType, name: String, icon: String, color: String) {
        selectedHabitType = type
        self.name = name
        selectedIcon = icon
        selectedColor = color

        // Set default goal
        switch type {
        case .healthKitSleep:
            dailyGoal = 8
        case .healthKitWater:
            dailyGoal = 2000
        case .healthKitCalories:
            dailyGoal = 2000
        default:
            dailyGoal = 0
        }

        // Check if HealthKit is available
        if healthKitManager.isHealthKitAvailable {
            // Check if already authorized for this specific habit type
            if healthKitManager.isAuthorized(for: type) {
                // Already authorized, proceed directly
                selectedDataSource = .healthKit
                withAnimation { currentStep = 1 }
            } else {
                // Not authorized yet, show permission sheet
                showingHealthKitPermission = true
            }
        } else {
            selectedDataSource = .manual
            withAnimation { currentStep = 1 }
        }
    }

    // MARK: - Step 2: Habit Details Form

    private var habitDetailsForm: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Preview
                previewSection

                // Data Source (for HealthKit types)
                if selectedHabitType != .manual {
                    dataSourceSection
                }

                // Name Input
                nameSection

                // Goal Section (for HealthKit types)
                if selectedHabitType != .manual {
                    goalSection
                }

                // Goal Progression (for habits with goals)
                if hasGoal && selectedHabitType != .manual {
                    goalProgressionSection
                }

                // Rest Days Section
                restDaysSection

                // Focus Session Section (only for manual habits)
                if selectedHabitType == .manual {
                    focusSessionSection
                }

                // Icon Picker
                iconSection

                // Color Picker
                colorSection
            }
            .padding(20)
        }
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: selectedColor).opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: selectedIcon)
                    .font(.system(size: 40))
                    .foregroundStyle(Color(hex: selectedColor))
            }

            Text(name.isEmpty ? "Habit Name" : name)
                .font(.title3.weight(.semibold))
                .foregroundStyle(name.isEmpty ? tertiaryText : primaryText)

            if selectedHabitType != .manual {
                HStack(spacing: 4) {
                    Image(systemName: selectedDataSource == .healthKit ? "heart.fill" : "hand.tap.fill")
                        .font(.caption)
                    Text(selectedDataSource == .healthKit ? "Auto-sync from Health" : "Manual entry")
                        .font(.caption)
                }
                .foregroundStyle(secondaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .liquidGlass(cornerRadius: 24)
    }

    // MARK: - Data Source Section

    private var dataSourceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Data Source")
                .font(.headline)
                .foregroundStyle(primaryText)

            HStack(spacing: 12) {
                DataSourceButton(
                    title: "Auto-sync",
                    subtitle: "From Apple Health",
                    icon: "heart.fill",
                    isSelected: selectedDataSource == .healthKit,
                    isEnabled: healthKitManager.isHealthKitAvailable,
                    accentColor: accentColor,
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                    tertiaryText: tertiaryText,
                    colorScheme: colorScheme
                ) {
                    // Check if already authorized for this specific habit type
                    if healthKitManager.isAuthorized(for: selectedHabitType) {
                        selectedDataSource = .healthKit
                    } else {
                        showingHealthKitPermission = true
                    }
                }

                DataSourceButton(
                    title: "Manual",
                    subtitle: "Enter values yourself",
                    icon: "hand.tap.fill",
                    isSelected: selectedDataSource == .manual,
                    isEnabled: true,
                    accentColor: accentColor,
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                    tertiaryText: tertiaryText,
                    colorScheme: colorScheme
                ) {
                    selectedDataSource = .manual
                }
            }
        }
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
                    unit: unitForType,
                    color: Color(hex: selectedColor)
                )

                // Quick presets
                GoalPresetButtons(
                    value: $dailyGoal,
                    presets: presetsForType,
                    unit: unitForType,
                    color: Color(hex: selectedColor)
                )
            }
        }
        .padding(16)
        .liquidGlass(cornerRadius: 20)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: hasGoal)
    }

    private var goalRangeForType: ClosedRange<Double> {
        switch selectedHabitType {
        case .healthKitSleep: return 4...12
        case .healthKitWater: return 500...4000
        case .healthKitCalories: return 100...5000
        default: return 1...100
        }
    }

    private var goalStepForType: Double {
        switch selectedHabitType {
        case .healthKitSleep: return 0.5
        case .healthKitWater: return 100
        case .healthKitCalories: return 100
        default: return 1
        }
    }

    private var presetsForType: [Double] {
        switch selectedHabitType {
        case .healthKitSleep: return [6, 7, 8, 9]
        case .healthKitWater: return [1500, 2000, 2500, 3000]
        case .healthKitCalories: return [1500, 2000, 2500, 3000]
        default: return []
        }
    }

    private var unitForType: String {
        switch selectedHabitType {
        case .healthKitSleep: return "hours"
        case .healthKitWater: return "ml"
        case .healthKitCalories: return "kcal"
        default: return ""
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
                            if progression == .rampUp {
                                goalIncrement = defaultIncrement
                            }
                        }
                    }
                }
            }

            // Expanded options
            if showGoalProgressionOptions {
                VStack(alignment: .leading, spacing: 12) {
                    // Description
                    Text(goalProgression.description)
                        .font(.caption)
                        .foregroundStyle(secondaryText)
                        .padding(.vertical, 4)

                    // Ramp-up specific options
                    if goalProgression == .rampUp {
                        rampUpOptions
                    }

                    // Adaptive explanation
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
        switch selectedHabitType {
        case .healthKitSleep: return 0.5
        case .healthKitWater: return 250
        case .healthKitCalories: return 100
        default: return 1
        }
    }

    private var rampUpOptions: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Increment amount
            VStack(alignment: .leading, spacing: 8) {
                Text("Increase by")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(primaryText)

                HStack {
                    Slider(value: $goalIncrement, in: incrementRange, step: incrementStep)
                        .tint(accentColor)

                    Text("\(formatIncrement(goalIncrement)) \(unitForType)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(accentColor)
                        .frame(width: 80, alignment: .trailing)
                }
            }

            // Interval
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
        switch selectedHabitType {
        case .healthKitSleep: return 0.25...2
        case .healthKitWater: return 100...500
        case .healthKitCalories: return 50...500
        default: return 1...10
        }
    }

    private var incrementStep: Double {
        switch selectedHabitType {
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

            // Day selection
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

    private func saveHabit() {
        HapticManager.shared.habitCreated()
        let habit = Habit(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            icon: selectedIcon,
            color: selectedColor,
            habitType: selectedHabitType,
            dataSource: selectedDataSource,
            dailyGoal: hasGoal ? dailyGoal : nil,
            unit: selectedHabitType != .manual ? unitForType : nil
        )

        // Set goal progression properties
        habit.goalProgression = goalProgression
        habit.initialGoal = hasGoal ? dailyGoal : nil

        if goalProgression == .rampUp {
            habit.goalIncrement = goalIncrement
            habit.goalIncrementIntervalDays = goalIncrementInterval
        }

        // Set rest days
        if !selectedRestDays.isEmpty {
            habit.restDays = Array(selectedRestDays).sorted()
            habit.restDaysPerWeek = selectedRestDays.count
        }

        // Set focus session enabled
        habit.focusEnabled = focusEnabled

        modelContext.insert(habit)
        dismiss()
    }
}

#Preview {
    AddHabitView()
        .modelContainer(for: Habit.self, inMemory: true)
}
