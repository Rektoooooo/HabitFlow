//
//  HabitStackBuilderView.swift
//  HabitTracker
//
//  Created by Claude on 14.01.2026.
//

import SwiftUI
import SwiftData

struct HabitStackBuilderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var store = StoreManager.shared

    @Query(sort: \Habit.createdAt, order: .reverse) private var allHabits: [Habit]

    @State private var stackName = ""
    @State private var selectedIcon = "link.circle.fill"
    @State private var selectedColor = "#A855F7"
    @State private var selectedHabits: [Habit] = []
    @State private var currentStep = 0 // 0 = select habits, 1 = customize
    @State private var showingPaywall = false

    let existingStack: HabitStack?
    let template: StackTemplate?

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

    let icons = [
        "link.circle.fill", "arrow.triangle.2.circlepath", "repeat.circle.fill",
        "sunrise.fill", "moon.stars.fill", "bolt.fill",
        "figure.run", "brain.head.profile", "heart.fill",
        "leaf.fill", "book.fill", "star.fill"
    ]

    let colors = [
        "#A855F7", "#EC4899", "#06B6D4", "#34D399",
        "#F59E0B", "#EF4444", "#8B5CF6", "#3B82F6"
    ]

    // Available habits (not in another stack)
    private var availableHabits: [Habit] {
        allHabits.filter { habit in
            habit.stackId == nil || habit.stackId == existingStack?.id
        }
    }

    init(existingStack: HabitStack? = nil, template: StackTemplate? = nil) {
        self.existingStack = existingStack
        self.template = template
    }

    var body: some View {
        NavigationStack {
            ZStack {
                FloatingClouds()

                if currentStep == 0 {
                    habitSelectionStep
                } else {
                    customizeStep
                }
            }
            .navigationTitle(existingStack == nil ? "New Chain" : "Edit Chain")
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
                }

                ToolbarItem(placement: .confirmationAction) {
                    if currentStep == 0 {
                        Button("Next") {
                            if store.isPremium {
                                withAnimation { currentStep = 1 }
                            } else {
                                showingPaywall = true
                            }
                        }
                        .disabled(selectedHabits.count < 2)
                        .foregroundStyle(selectedHabits.count >= 2 ? accentColor : tertiaryText)
                    } else {
                        Button("Save") {
                            if store.isPremium {
                                saveStack()
                            } else {
                                showingPaywall = true
                            }
                        }
                        .disabled(stackName.isEmpty)
                        .foregroundStyle(stackName.isEmpty ? tertiaryText : accentColor)
                    }
                }
            }
            .onAppear {
                if let stack = existingStack {
                    loadExistingStack(stack)
                } else if let template = template {
                    loadTemplate(template)
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Habit Selection Step

    private var habitSelectionStep: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Instructions
                VStack(spacing: 8) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: template?.icon ?? "link.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(Color(hex: template?.color ?? "#A855F7"))

                        if !store.isPremium {
                            Text("PRO")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "#A855F7"), Color(hex: "#EC4899")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(Capsule())
                                .offset(x: 20, y: -10)
                        }
                    }

                    Text(template?.name ?? "Build Your Chain")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(primaryText)

                    Text(template != nil ? template!.description : "Select habits in the order you want to complete them")
                        .font(.subheadline)
                        .foregroundStyle(secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 20)

                // Template suggestions (if using a template)
                if let template = template {
                    templateSuggestionsSection(template)
                }

                // Selected chain preview
                if !selectedHabits.isEmpty {
                    chainPreview
                }

                // Available habits
                VStack(alignment: .leading, spacing: 12) {
                    Text("Available Habits")
                        .font(.headline)
                        .foregroundStyle(primaryText)

                    if availableHabits.isEmpty {
                        Text("No habits available. Create some habits first!")
                            .font(.subheadline)
                            .foregroundStyle(secondaryText)
                            .padding()
                    } else {
                        ForEach(availableHabits) { habit in
                            HabitSelectionRow(
                                habit: habit,
                                isSelected: selectedHabits.contains(where: { $0.id == habit.id }),
                                orderNumber: selectedHabits.firstIndex(where: { $0.id == habit.id }).map { $0 + 1 },
                                primaryText: primaryText,
                                secondaryText: secondaryText,
                                tertiaryText: tertiaryText,
                                accentColor: accentColor,
                                colorScheme: colorScheme
                            ) {
                                toggleHabitSelection(habit)
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
    }

    private func templateSuggestionsSection(_ template: StackTemplate) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.subheadline)
                    .foregroundStyle(.yellow)

                Text("Suggested Habits")
                    .font(.headline)
                    .foregroundStyle(primaryText)
            }

            Text("This template works best with these habits:")
                .font(.caption)
                .foregroundStyle(secondaryText)

            // Show suggested habit names
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                ForEach(template.suggestedHabits, id: \.self) { habitName in
                    let isMatched = availableHabits.contains { habit in
                        habit.name.lowercased().contains(habitName.lowercased()) ||
                        habitName.lowercased().contains(habit.name.lowercased())
                    }

                    HStack(spacing: 4) {
                        if isMatched {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.green)
                        }
                        Text(habitName)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .foregroundStyle(isMatched ? primaryText : secondaryText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(isMatched
                                  ? Color.green.opacity(0.15)
                                  : (colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05)))
                    )
                }
            }

            if !availableHabits.isEmpty {
                Text("Habits matching these suggestions are highlighted below")
                    .font(.caption2)
                    .foregroundStyle(tertiaryText)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: template.color).opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: template.color).opacity(0.3), lineWidth: 1)
        )
    }

    private var chainPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Chain")
                    .font(.headline)
                    .foregroundStyle(primaryText)

                Spacer()

                Text("\(selectedHabits.count) habits")
                    .font(.caption)
                    .foregroundStyle(secondaryText)
            }

            // Chain visualization
            VStack(spacing: 0) {
                ForEach(Array(selectedHabits.enumerated()), id: \.element.id) { index, habit in
                    HStack(spacing: 12) {
                        // Order number
                        ZStack {
                            Circle()
                                .fill(accentColor)
                                .frame(width: 28, height: 28)

                            Text("\(index + 1)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                        }

                        // Habit info
                        HStack(spacing: 10) {
                            Image(systemName: habit.icon)
                                .font(.subheadline)
                                .foregroundStyle(Color(hex: habit.color))

                            Text(habit.name)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(primaryText)

                            Spacer()

                            // Remove button
                            Button {
                                removeFromChain(habit)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(tertiaryText)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.6))
                        )
                    }

                    // Connector line
                    if index < selectedHabits.count - 1 {
                        HStack {
                            Rectangle()
                                .fill(accentColor.opacity(0.5))
                                .frame(width: 2, height: 20)
                                .padding(.leading, 13)
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding(16)
        .liquidGlass(cornerRadius: 16)
    }

    // MARK: - Customize Step

    private var customizeStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Preview
                stackPreview

                // Name
                VStack(alignment: .leading, spacing: 12) {
                    Text("Name")
                        .font(.headline)
                        .foregroundStyle(primaryText)

                    TextField("e.g., Morning Routine", text: $stackName)
                        .font(.body)
                        .foregroundStyle(primaryText)
                        .padding(16)
                        .liquidGlass(cornerRadius: 12)
                }

                // Icon
                iconSection

                // Color
                colorSection

                // Reorder habits
                reorderSection
            }
            .padding(20)
        }
    }

    private var stackPreview: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: selectedColor).opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: selectedIcon)
                    .font(.system(size: 32))
                    .foregroundStyle(Color(hex: selectedColor))
            }

            Text(stackName.isEmpty ? "Chain Name" : stackName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(stackName.isEmpty ? tertiaryText : primaryText)

            Text("\(selectedHabits.count) habits in chain")
                .font(.caption)
                .foregroundStyle(secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .liquidGlass(cornerRadius: 24)
    }

    private var iconSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Icon")
                .font(.headline)
                .foregroundStyle(primaryText)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                ForEach(icons, id: \.self) { icon in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedIcon = icon
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedIcon == icon
                                      ? Color(hex: selectedColor)
                                      : (colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.6)))
                                .frame(width: 48, height: 48)

                            Image(systemName: icon)
                                .font(.title3)
                                .foregroundStyle(selectedIcon == icon ? .white : Color(hex: selectedColor))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .liquidGlass(cornerRadius: 16)
        }
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Color")
                .font(.headline)
                .foregroundStyle(primaryText)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                ForEach(colors, id: \.self) { color in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedColor = color
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 36, height: 36)

                            if selectedColor == color {
                                Circle()
                                    .stroke(.white, lineWidth: 2)
                                    .frame(width: 36, height: 36)

                                Image(systemName: "checkmark")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .liquidGlass(cornerRadius: 16)
        }
    }

    private var reorderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Chain Order")
                    .font(.headline)
                    .foregroundStyle(primaryText)

                Spacer()

                Text("Drag to reorder")
                    .font(.caption)
                    .foregroundStyle(secondaryText)
            }

            VStack(spacing: 8) {
                ForEach(Array(selectedHabits.enumerated()), id: \.element.id) { index, habit in
                    HStack(spacing: 12) {
                        Image(systemName: "line.3.horizontal")
                            .font(.caption)
                            .foregroundStyle(tertiaryText)

                        ZStack {
                            Circle()
                                .fill(Color(hex: habit.color).opacity(0.2))
                                .frame(width: 36, height: 36)

                            Image(systemName: habit.icon)
                                .font(.subheadline)
                                .foregroundStyle(Color(hex: habit.color))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(habit.name)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(primaryText)

                            Text("Step \(index + 1)")
                                .font(.caption2)
                                .foregroundStyle(secondaryText)
                        }

                        Spacer()

                        // Move buttons
                        HStack(spacing: 8) {
                            Button {
                                moveUp(index)
                            } label: {
                                Image(systemName: "chevron.up")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(index == 0 ? tertiaryText.opacity(0.3) : accentColor)
                            }
                            .disabled(index == 0)

                            Button {
                                moveDown(index)
                            } label: {
                                Image(systemName: "chevron.down")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(index == selectedHabits.count - 1 ? tertiaryText.opacity(0.3) : accentColor)
                            }
                            .disabled(index == selectedHabits.count - 1)
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.5))
                    )
                }
            }
            .padding(12)
            .liquidGlass(cornerRadius: 16)
        }
    }

    // MARK: - Actions

    private func toggleHabitSelection(_ habit: Habit) {
        withAnimation(.spring(response: 0.3)) {
            if let index = selectedHabits.firstIndex(where: { $0.id == habit.id }) {
                selectedHabits.remove(at: index)
            } else {
                selectedHabits.append(habit)
            }
        }
    }

    private func removeFromChain(_ habit: Habit) {
        withAnimation(.spring(response: 0.3)) {
            selectedHabits.removeAll { $0.id == habit.id }
        }
    }

    private func moveUp(_ index: Int) {
        guard index > 0 else { return }
        withAnimation(.spring(response: 0.3)) {
            selectedHabits.swapAt(index, index - 1)
        }
    }

    private func moveDown(_ index: Int) {
        guard index < selectedHabits.count - 1 else { return }
        withAnimation(.spring(response: 0.3)) {
            selectedHabits.swapAt(index, index + 1)
        }
    }

    private func loadExistingStack(_ stack: HabitStack) {
        stackName = stack.name
        selectedIcon = stack.icon
        selectedColor = stack.color

        // Load habits in order
        selectedHabits = stack.habitOrder.compactMap { habitId in
            allHabits.first { $0.id == habitId }
        }
    }

    private func loadTemplate(_ template: StackTemplate) {
        stackName = template.name
        selectedIcon = template.icon
        selectedColor = template.color

        // Try to match existing habits with template suggestions
        for suggestedName in template.suggestedHabits {
            // Find habits that match the suggested name (case-insensitive partial match)
            if let matchingHabit = availableHabits.first(where: { habit in
                habit.name.lowercased().contains(suggestedName.lowercased()) ||
                suggestedName.lowercased().contains(habit.name.lowercased())
            }) {
                if !selectedHabits.contains(where: { $0.id == matchingHabit.id }) {
                    selectedHabits.append(matchingHabit)
                }
            }
        }
    }

    private func saveStack() {
        if let existingStack = existingStack {
            // Update existing stack
            existingStack.name = stackName
            existingStack.icon = selectedIcon
            existingStack.color = selectedColor
            existingStack.habitOrder = selectedHabits.map { $0.id }

            // Update habit associations
            for (index, habit) in selectedHabits.enumerated() {
                habit.stackId = existingStack.id
                habit.stackOrder = index
            }

            // Remove association from habits no longer in stack
            for habit in allHabits where habit.stackId == existingStack.id {
                if !selectedHabits.contains(where: { $0.id == habit.id }) {
                    habit.stackId = nil
                    habit.stackOrder = nil
                }
            }
        } else {
            // Create new stack
            _ = HabitStackManager.shared.createStack(
                name: stackName,
                icon: selectedIcon,
                color: selectedColor,
                habits: selectedHabits,
                in: modelContext
            )
        }

        HapticManager.shared.success()
        dismiss()
    }
}

// MARK: - Habit Selection Row

struct HabitSelectionRow: View {
    let habit: Habit
    let isSelected: Bool
    let orderNumber: Int?
    let primaryText: Color
    let secondaryText: Color
    let tertiaryText: Color
    let accentColor: Color
    let colorScheme: ColorScheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? accentColor : tertiaryText, lineWidth: 2)
                        .frame(width: 28, height: 28)

                    if isSelected, let number = orderNumber {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 28, height: 28)

                        Text("\(number)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                    }
                }

                // Habit icon
                ZStack {
                    Circle()
                        .fill(Color(hex: habit.color).opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: habit.icon)
                        .font(.body)
                        .foregroundStyle(Color(hex: habit.color))
                }

                // Habit info
                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(primaryText)

                    if habit.stackId != nil && !isSelected {
                        Text("Already in another chain")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }

                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected
                          ? accentColor.opacity(0.1)
                          : (colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.5)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? accentColor.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HabitStackBuilderView()
        .modelContainer(for: [Habit.self, HabitStack.self], inMemory: true)
}
