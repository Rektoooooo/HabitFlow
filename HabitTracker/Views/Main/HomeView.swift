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
    }

    // MARK: - Stacks Preview Section

    private var stacksPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "link.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "#8B5CF6"), Color(hex: "#06B6D4")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Habit Chains")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(colorScheme == .dark ? .white : Color(red: 0.15, green: 0.12, blue: 0.25))
                }

                Spacer()

                Button {
                    showingStacks = true
                } label: {
                    Text("See all")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color(hex: "#8B5CF6"))
                }
            }

            // Show active stacks (max 2)
            ForEach(stacks.filter { $0.isActive }.prefix(2)) { stack in
                CompactStackCard(
                    stack: stack,
                    habits: habits,
                    onTap: { showingStacks = true }
                )
            }

            // Create stack button if no stacks
            if stacks.isEmpty {
                Button {
                    showingCreateStack = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.subheadline)
                        Text("Create a habit chain")
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundStyle(Color(hex: "#8B5CF6"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(hex: "#8B5CF6").opacity(0.1))
                    )
                }
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Suggestions Preview Section

    private var suggestionsPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.subheadline)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "#A855F7"), Color(hex: "#EC4899")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Suggested for you")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(colorScheme == .dark ? .white : Color(red: 0.15, green: 0.12, blue: 0.25))
                }

                Spacer()

                Button {
                    showingSuggestions = true
                } label: {
                    Text("See all")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color(hex: "#A855F7"))
                }
            }
            .padding(.top, 8)

            // Show first 2 suggestions as compact cards
            ForEach(suggestions.prefix(2)) { suggestion in
                CompactSuggestionCard(
                    suggestion: suggestion,
                    onAdd: {
                        selectedSuggestion = suggestion
                    }
                )
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Empty State

    private var emptyStateSection: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 60)

            ZStack {
                Circle()
                    .fill(AppTheme.Gradients.accentGradient)
                    .frame(width: 120, height: 120)
                    .blur(radius: 40)
                    .opacity(0.5)

                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundStyle(AppTheme.Gradients.accentGradient)
            }

            VStack(spacing: 12) {
                Text("Start Your Journey")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Text("Build better habits, one day at a time.\nTap the + button to create your first habit.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Arrow pointing to center tab button
            VStack(spacing: 8) {
                Image(systemName: "arrow.down")
                    .font(.title2)
                    .foregroundStyle(AppTheme.Colors.accentPrimary)

                Text("Tap + to add a habit")
                    .font(.caption)
                    .foregroundStyle(AppTheme.Colors.textTertiary)
            }
            .padding(.top, 20)

            Spacer()
        }
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

// MARK: - Habit Card

struct HabitCard: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var habit: Habit  // Use @Bindable to observe SwiftData model changes
    var stack: HabitStack?  // Optional stack this habit belongs to
    var stackPosition: (current: Int, total: Int)?  // Position in the stack (1-based)
    var onStartFocus: (() -> Void)?  // Callback to start focus session
    @State private var showingValueEntry = false
    @State private var showingDetail = false

    // Adaptive text colors
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
                    // Progress ring for HealthKit habits with goals (not tappable - auto synced)
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
                            // Use appropriate haptic based on action
                            if wasCompleted {
                                HapticManager.shared.habitUncompleted()
                            } else {
                                HapticManager.shared.habitCompleted()
                                // Check if all habits are now completed - celebrate!
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
            // Background ring
            Circle()
                .stroke(colorScheme == .dark ? Color.white.opacity(0.15) : Color.gray.opacity(0.2), lineWidth: 4)
                .frame(width: 48, height: 48)

            // Progress ring with animation
            Circle()
                .trim(from: 0, to: min(habit.todayProgress, 1.0))
                .stroke(
                    Color(hex: habit.color),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 48, height: 48)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: habit.todayProgress)

            // Center content with transition
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
            // Remove today's completion
            if let todayCompletion = habit.completions.first(where: { calendar.isDateInToday($0.date) }) {
                habit.completions.removeAll { $0.id == todayCompletion.id }
                modelContext.delete(todayCompletion)
            }
        } else {
            // Create and add new completion
            let completion = HabitCompletion(date: Date(), habit: habit)
            habit.completions.append(completion)  // Explicitly add to array
            modelContext.insert(completion)
        }

        // Save context to ensure persistence
        try? modelContext.save()

        // Update widgets after a short delay to ensure data is saved
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NotificationCenter.default.post(name: .habitsDidChange, object: nil)
        }
    }

    private func checkAllHabitsCompleted() {
        // Small delay to ensure the completion is saved
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            do {
                let descriptor = FetchDescriptor<Habit>()
                let allHabits = try modelContext.fetch(descriptor)

                // Check if all habits are completed today
                let allCompleted = allHabits.allSatisfy { $0.isCompletedToday }

                if allCompleted && !allHabits.isEmpty {
                    HapticManager.shared.allHabitsCompleted()
                    // Post notification to show celebration
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

// MARK: - Checkmark Tap View (using Button for reliable tap handling)

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
                // Background circle with animated fill
                Circle()
                    .fill(isCompleted
                          ? Color(hex: color)
                          : colorScheme == .dark ? Color.white.opacity(0.1) : Color.gray.opacity(0.15))
                    .frame(width: 44, height: 44)

                // Checkmark or empty circle
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

#Preview {
    HomeView()
        .modelContainer(for: Habit.self, inMemory: true)
}
