//
//  SuggestionsView.swift
//  HabitTracker
//
//  Created by Claude on 14.01.2026.
//

import SwiftUI
import SwiftData

struct SuggestionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: \Habit.createdAt, order: .reverse) private var habits: [Habit]
    @ObservedObject private var suggestionEngine = HabitSuggestionEngine.shared
    @ObservedObject private var store = StoreManager.shared

    @State private var suggestions: [HabitSuggestion] = []
    @State private var selectedSuggestion: HabitSuggestion?
    @State private var showingAddHabit = false

    private var primaryText: Color {
        colorScheme == .dark ? .white : Color(red: 0.15, green: 0.12, blue: 0.25)
    }

    private var secondaryText: Color {
        colorScheme == .dark ? .white.opacity(0.7) : Color(red: 0.4, green: 0.35, blue: 0.5)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                FloatingClouds()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header explanation
                        headerSection

                        if suggestions.isEmpty {
                            emptyState
                        } else {
                            // Suggestions grouped by category
                            suggestionsSection
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Suggestions")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Color(hex: "#A855F7"))
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                if let suggestion = selectedSuggestion {
                    AddHabitFromSuggestionView(suggestion: suggestion)
                }
            }
            .onAppear {
                refreshSuggestions()
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#A855F7"), Color(hex: "#EC4899")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)

                Image(systemName: "sparkles")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text("Personalized for You")
                .font(.title3.weight(.bold))
                .foregroundStyle(primaryText)

            Text("Based on your habits and patterns, we think these would be great additions to your routine.")
                .font(.subheadline)
                .foregroundStyle(secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 20)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(Color(hex: "#34D399"))

            Text("All Caught Up!")
                .font(.headline)
                .foregroundStyle(primaryText)

            Text("You've reviewed all our suggestions. Add more habits to get new personalized recommendations.")
                .font(.subheadline)
                .foregroundStyle(secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                suggestionEngine.resetDismissedSuggestions()
                refreshSuggestions()
            } label: {
                Text("Reset Suggestions")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color(hex: "#A855F7"))
            }
            .padding(.top, 8)
        }
        .padding(.vertical, 40)
    }

    // MARK: - Suggestions Section

    private var suggestionsSection: some View {
        VStack(spacing: 16) {
            ForEach(suggestions) { suggestion in
                SuggestionCardView(
                    suggestion: suggestion,
                    onAdd: {
                        selectedSuggestion = suggestion
                        showingAddHabit = true
                    },
                    onDismiss: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            suggestionEngine.dismissSuggestion(suggestion)
                            refreshSuggestions()
                        }
                    }
                )
            }
        }
    }

    // MARK: - Helpers

    private func refreshSuggestions() {
        suggestions = suggestionEngine.generateSuggestions(for: habits)
    }
}

// MARK: - Add Habit From Suggestion View

struct AddHabitFromSuggestionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    let suggestion: HabitSuggestion

    @ObservedObject private var store = StoreManager.shared
    @Query private var habits: [Habit]

    @State private var habitName: String
    @State private var showingPaywall = false

    private var primaryText: Color {
        colorScheme == .dark ? .white : Color(red: 0.15, green: 0.12, blue: 0.25)
    }

    private var secondaryText: Color {
        colorScheme == .dark ? .white.opacity(0.7) : Color(red: 0.4, green: 0.35, blue: 0.5)
    }

    private var canAddHabit: Bool {
        store.isPremium || habits.count < 3
    }

    init(suggestion: HabitSuggestion) {
        self.suggestion = suggestion
        self._habitName = State(initialValue: suggestion.name)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                FloatingClouds()

                VStack(spacing: 24) {
                    // Preview card
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: suggestion.color).opacity(0.2))
                                .frame(width: 80, height: 80)

                            Image(systemName: suggestion.icon)
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundStyle(Color(hex: suggestion.color))
                        }

                        TextField("Habit name", text: $habitName)
                            .font(.title2.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(primaryText)

                        Text(suggestion.category.displayName)
                            .font(.caption)
                            .foregroundStyle(secondaryText)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color(hex: suggestion.color).opacity(0.2))
                            )
                    }
                    .padding(24)
                    .liquidGlass(cornerRadius: 24)

                    // Why this suggestion
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.yellow)
                            Text("Why this habit?")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(primaryText)
                        }

                        Text(suggestion.detailedReason)
                            .font(.subheadline)
                            .foregroundStyle(secondaryText)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .liquidGlass(cornerRadius: 16)

                    Spacer()

                    // Add button
                    Button {
                        if canAddHabit {
                            addHabit()
                        } else {
                            showingPaywall = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: canAddHabit ? "plus.circle.fill" : "crown.fill")
                            Text(canAddHabit ? "Add to My Habits" : "Upgrade to Add More")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "#A855F7"), Color(hex: "#EC4899")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(20)
            }
            .navigationTitle("Add Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(secondaryText)
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }

    private func addHabit() {
        let habit = Habit(
            name: habitName.isEmpty ? suggestion.name : habitName,
            icon: suggestion.icon,
            color: suggestion.color
        )

        modelContext.insert(habit)

        HapticManager.shared.habitCompleted()

        // Dismiss suggestion
        HabitSuggestionEngine.shared.dismissSuggestion(suggestion)

        // Update widgets
        WidgetDataManager.shared.updateWidgetData(habits: habits + [habit])

        dismiss()
    }
}

#Preview {
    SuggestionsView()
        .modelContainer(for: Habit.self, inMemory: true)
}
