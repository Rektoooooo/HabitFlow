//
//  HomeView.swift
//  HabitTracker
//
//  Created by Sebastián Kučera on 12.01.2026.
//

import SwiftUI
import SwiftData
import UIKit

// MARK: - Notification for Widget Updates

extension Notification.Name {
    static let habitsDidChange = Notification.Name("habitsDidChange")
    static let allHabitsCompleted = Notification.Name("allHabitsCompleted")
}

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \Habit.createdAt, order: .reverse) private var habits: [Habit]
    @Query(sort: \HabitStack.createdAt, order: .reverse) private var stacks: [HabitStack]
    @ObservedObject private var healthKitManager = HealthKitManager.shared
    @ObservedObject private var store = StoreManager.shared
    @ObservedObject private var suggestionEngine = HabitSuggestionEngine.shared
    @ObservedObject private var stackManager = HabitStackManager.shared
    @ObservedObject private var focusManager = FocusSessionManager.shared
    @State private var showingAddHabit = false
    @State private var showingStacks = false
    @State private var showingCreateStack = false
    @State private var showingPaywall = false
    @State private var showingSuggestions = false
    @State private var habitToEdit: Habit?
    @State private var habitToDelete: Habit?
    @State private var showingDeleteConfirmation = false
    @State private var suggestions: [HabitSuggestion] = []
    @State private var selectedSuggestion: HabitSuggestion?
    @State private var habitForFocus: Habit?
    @State private var showingCelebration = false
    @State private var lastActiveDate: Date = Date()
    @State private var refreshID = UUID()

    // Top section colors based on color scheme
    private var topSectionGradient: LinearGradient {
        if colorScheme == .dark {
            // Dark mode: deep purple gradient
            return LinearGradient(
                colors: [
                    Color(red: 0.18, green: 0.14, blue: 0.28),
                    Color(red: 0.15, green: 0.12, blue: 0.25)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            // Light mode: soft lavender gradient
            return LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.94, blue: 0.98),
                    Color(red: 0.94, green: 0.92, blue: 0.97)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    // MARK: - Greeting Header

    private var greetingHeader: some View {
        HStack(spacing: 12) {
            // Mascot avatar
            Image("ProfileMascot")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 50)

            // Greeting text
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(greeting)
                        .font(.subheadline)
                        .foregroundStyle(colorScheme == .dark
                            ? Color(red: 0.75, green: 0.70, blue: 0.85)
                            : Color(red: 0.5, green: 0.45, blue: 0.55))

                    Text(greetingEmoji)
                        .font(.subheadline)
                }

                Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.abbreviated)))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(colorScheme == .dark ? .white : Color(red: 0.15, green: 0.12, blue: 0.25))
            }

            Spacer()

            // Add habit button
            Button {
                HapticManager.shared.buttonPressed()
                if store.canAddMoreHabits(currentCount: habits.count) {
                    showingAddHabit = true
                } else {
                    showingPaywall = true
                }
            } label: {
                Image(systemName: "plus")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.65, green: 0.35, blue: 0.85),
                                Color(red: 0.85, green: 0.35, blue: 0.65)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
            }
        }
    }

    private var greetingEmoji: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "☀️"
        case 12..<17: return "👋"
        case 17..<21: return "🌅"
        default: return "🌙"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Layer 1: Floating clouds background (full screen)
                FloatingClouds(theme: .habitTracker(colorScheme))

                // Layer 2: Scrollable habits (below top section)
                ScrollView {
                    VStack(spacing: 12) {
                        // Spacer for top section height + wave clearance
                        Color.clear
                            .frame(height: habits.isEmpty ? 180 : 280)

                        // Habits content
                        if habits.isEmpty {
                            emptyStateSection
                        } else {
                            habitsPreviewSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120)
                }

                // Layer 3: Top section (on top, habits scroll behind it)
                VStack(spacing: 0) {
                    ZStack(alignment: .top) {
                        // Safe area fill (not clipped by wave) - use solid color matching gradient top
                        (colorScheme == .dark
                            ? Color(red: 0.18, green: 0.14, blue: 0.28)
                            : Color(red: 0.96, green: 0.94, blue: 0.98))
                            .frame(height: 80) // Just the safe area height
                            .ignoresSafeArea(edges: .top)

                        // Content with wave clip
                        VStack(spacing: 12) {
                            // Greeting header
                            greetingHeader

                            // Today's Progress Card
                            if !habits.isEmpty {
                                WhiteProgressCard(habits: Array(habits))
                                    .id(refreshID) // Force re-render when day changes
                                    .padding(.bottom, 12) // Extra padding from wave
                            } else {
                                Text("Add habits to track progress")
                                    .font(.subheadline)
                                    .foregroundStyle(colorScheme == .dark
                                        ? Color(red: 0.7, green: 0.65, blue: 0.8)
                                        : Color(red: 0.5, green: 0.45, blue: 0.55))
                                    .padding(.vertical, 12)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 35) // Space for wave curve
                        .frame(maxWidth: .infinity)
                        .background(topSectionGradient)
                        .clipShape(WaveBottomEdge(amplitude: 25))
                    }

                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView()
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .sheet(item: $habitToEdit) { habit in
                EditHabitView(habit: habit)
            }
            .sheet(isPresented: $showingSuggestions) {
                SuggestionsView()
            }
            .sheet(isPresented: $showingStacks) {
                StacksView()
            }
            .sheet(isPresented: $showingCreateStack) {
                HabitStackBuilderView()
            }
            .sheet(item: $selectedSuggestion) { suggestion in
                AddHabitFromSuggestionView(suggestion: suggestion)
            }
            .sheet(item: $habitForFocus) { habit in
                FocusSetupSheet(habit: habit)
            }
            .fullScreenCover(isPresented: $focusManager.isShowingTimer) {
                FocusSessionView()
            }
            .alert("Delete Habit", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    habitToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let habit = habitToDelete {
                        deleteHabit(habit)
                    }
                }
            } message: {
                Text("Are you sure you want to delete \"\(habitToDelete?.name ?? "")\"? This action cannot be undone.")
            }
            .onChange(of: habits) { _, newHabits in
                // Sync to widgets when habits change
                WidgetDataManager.shared.updateWidgetData(habits: newHabits)
                // Sync to Apple Watch
                WatchConnectivityManager.shared.sendHabitsToWatch(newHabits)
                // Refresh suggestions when habits change
                refreshSuggestions()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    // Check if we've crossed into a new day since last active
                    let calendar = Calendar.current
                    if !calendar.isDate(lastActiveDate, inSameDayAs: Date()) {
                        // Day changed - force UI refresh
                        refreshID = UUID()
                        lastActiveDate = Date()
                    }

                    // Sync HealthKit habits when app becomes active
                    Task {
                        await syncHealthKitHabits()
                    }
                    // Update widgets
                    WidgetDataManager.shared.updateWidgetData(habits: habits)
                    // Update Apple Watch
                    WatchConnectivityManager.shared.sendHabitsToWatch(Array(habits))
                }
            }
            .onAppear {
                // Initial sync
                WidgetDataManager.shared.updateWidgetData(habits: habits)
                // Initial Watch sync
                WatchConnectivityManager.shared.sendHabitsToWatch(Array(habits))
                // Generate suggestions
                refreshSuggestions()
            }
            .onReceive(NotificationCenter.default.publisher(for: .habitsDidChange)) { _ in
                // Update widgets when completions change
                WidgetDataManager.shared.updateWidgetData(habits: habits)
                // Update Apple Watch
                WatchConnectivityManager.shared.sendHabitsToWatch(Array(habits))
            }
            .onReceive(NotificationCenter.default.publisher(for: .watchRequestedSync)) { _ in
                // Watch requested a sync
                WatchConnectivityManager.shared.sendHabitsToWatch(Array(habits))
            }
            .onReceive(NotificationCenter.default.publisher(for: .allHabitsCompleted)) { _ in
                // Show celebration when all habits are completed
                showingCelebration = true
            }
            .overlay {
                if showingCelebration {
                    CelebrationView(isShowing: $showingCelebration)
                        .ignoresSafeArea()
                }
            }
        }
    }

    // MARK: - HealthKit Sync

    private func syncHealthKitHabits() async {
        let healthKitHabits = habits.filter { $0.dataSource == .healthKit }

        for habit in healthKitHabits {
            do {
                if let value = try await healthKitManager.syncHabitFromHealthKit(habit) {
                    await MainActor.run {
                        updateOrCreateCompletion(for: habit, value: value)
                    }
                }
            } catch {
                print("Failed to sync \(habit.name): \(error)")
            }
        }
    }

    private func updateOrCreateCompletion(for habit: Habit, value: Double) {
        let calendar = Calendar.current

        if let existing = habit.completions.first(where: { calendar.isDateInToday($0.date) }) {
            existing.value = value
            existing.isAutoSynced = true
        } else {
            let completion = HabitCompletion(date: Date(), habit: habit, value: value, isAutoSynced: true)
            modelContext.insert(completion)
        }

        // Notify widgets
        NotificationCenter.default.post(name: .habitsDidChange, object: nil)
    }

    // MARK: - Delete Habit

    private func deleteHabit(_ habit: Habit) {
        HapticManager.shared.habitDeleted()
        withAnimation {
            // Delete all completions first
            for completion in habit.completions {
                modelContext.delete(completion)
            }
            // Delete the habit
            modelContext.delete(habit)
            habitToDelete = nil

            // Notify widgets
            NotificationCenter.default.post(name: .habitsDidChange, object: nil)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greeting)
                .font(.subheadline)
                .foregroundStyle(Color(hex: "#6B7280"))

            Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                .font(.title2.weight(.bold))
                .foregroundStyle(Color(hex: "#1F2937"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Good night"
        }
    }

    // MARK: - Habits Section

    private var habitsPreviewSection: some View {
        VStack(spacing: 12) {
            // Show all habits
            ForEach(habits) { habit in
                HabitCard(
                    habit: habit,
                    stack: getStack(for: habit),
                    stackPosition: getStackPosition(for: habit),
                    onStartFocus: {
                        habitForFocus = habit
                    }
                )
                .contextMenu {
                    // Focus session option (only if enabled and not completed)
                    if habit.focusEnabled && !habit.isCompletedToday {
                        Button {
                            habitForFocus = habit
                        } label: {
                            Label("Start Focus Session", systemImage: "timer")
                        }
                    }

                    Button {
                        habitToEdit = habit
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        habitToDelete = habit
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }

            // Stacks Preview (show if user has 2+ habits)
            if habits.count >= 2 {
                stacksPreviewSection
            }

            // Suggestions Section (show if we have suggestions and user has less than 10 habits)
            if !suggestions.isEmpty && habits.count < 10 {
                suggestionsPreviewSection
            }
        }
        .id(refreshID) // Force re-render when day changes
    }

    // MARK: - Stacks Preview Section

    private var stacksPreviewSection: some View {
        StacksPreviewSection(
            stacks: Array(stacks),
            habits: Array(habits),
            onShowStacks: { showingStacks = true },
            onCreateStack: { showingCreateStack = true }
        )
    }

    // MARK: - Suggestions Preview Section

    private var suggestionsPreviewSection: some View {
        SuggestionsPreviewSection(
            suggestions: suggestions,
            onShowSuggestions: { showingSuggestions = true },
            onSelectSuggestion: { suggestion in
                selectedSuggestion = suggestion
            }
        )
    }

    // MARK: - Empty State

    private var emptyStateSection: some View {
        EmptyHabitsView()
    }

    // MARK: - Actions

    private func deleteHabits(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(habits[index])
        }
    }

    private func refreshSuggestions() {
        suggestions = suggestionEngine.generateSuggestions(for: habits)
    }

    // MARK: - Stack Helpers

    /// Get the stack that contains this habit
    private func getStack(for habit: Habit) -> HabitStack? {
        guard let stackId = habit.stackId else { return nil }
        return stacks.first { $0.id == stackId }
    }

    /// Get the position of this habit within its stack (1-based index)
    private func getStackPosition(for habit: Habit) -> (current: Int, total: Int)? {
        guard let stack = getStack(for: habit) else { return nil }
        guard let index = stack.habitOrder.firstIndex(of: habit.id) else { return nil }
        return (current: index + 1, total: stack.habitOrder.count)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Habit.self, inMemory: true)
}
