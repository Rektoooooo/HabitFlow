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
    @Environment(\.isUsingLocalStorage) private var isUsingLocalStorage
    @Query(sort: \Habit.createdAt, order: .reverse) private var habits: [Habit]
    @Query(sort: \HabitStack.createdAt, order: .reverse) private var stacks: [HabitStack]
    @ObservedObject private var healthKitManager = HealthKitManager.shared
    @ObservedObject private var store = StoreManager.shared
    @ObservedObject private var suggestionEngine = HabitSuggestionEngine.shared
    @ObservedObject private var stackManager = HabitStackManager.shared
    @ObservedObject private var focusManager = FocusSessionManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared
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
    @AppStorage("lastActiveDate") private var lastActiveDateTimestamp: Double = 0
    @State private var refreshID = UUID()
    @State private var syncError: String?
    @State private var showingSyncError = false
    @State private var showingLocalStorageBanner = false
    @AppStorage("dismissedWidgetPromo") private var dismissedWidgetPromo = false
    @State private var showingWidgetPromo = false

    // Helper to get Date from persisted timestamp
    private var lastActiveDate: Date {
        Date(timeIntervalSince1970: lastActiveDateTimestamp)
    }

    private func updateLastActiveDate() {
        lastActiveDateTimestamp = Date().timeIntervalSince1970
    }

    // Top section colors based on color scheme and accent color
    private var topSectionGradient: LinearGradient {
        let (r, g, b) = themeManager.accentColor.rgbComponents

        if colorScheme == .dark {
            // Dark mode: deep gradient tinted with accent color
            return LinearGradient(
                colors: [
                    Color(red: r * 0.18, green: g * 0.14, blue: b * 0.28),
                    Color(red: r * 0.12, green: g * 0.10, blue: b * 0.22)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            // Light mode: soft gradient tinted with accent
            return LinearGradient(
                colors: [
                    Color(red: 0.94 + r * 0.04, green: 0.92 + g * 0.04, blue: 0.96 + b * 0.03),
                    Color(red: 0.92 + r * 0.04, green: 0.90 + g * 0.04, blue: 0.95 + b * 0.03)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    // Top color of the section (for safe area fill)
    private var topSectionTopColor: Color {
        if themeManager.dynamicHeaderEnabled {
            // Use a color that blends with the top of the current time-based image
            switch TimeOfDay.current {
            case .morning:
                return Color(red: 0.53, green: 0.72, blue: 0.96) // Soft blue from morning image
            case .afternoon:
                return Color(red: 0.42, green: 0.73, blue: 0.98) // Bright blue from afternoon
            case .evening:
                return Color(red: 0.24, green: 0.18, blue: 0.42) // Deep purple from evening
            case .night:
                return Color(red: 0.15, green: 0.12, blue: 0.28) // Dark indigo from night
            }
        }

        let (r, g, b) = themeManager.accentColor.rgbComponents

        if colorScheme == .dark {
            return Color(red: r * 0.18, green: g * 0.14, blue: b * 0.28)
        } else {
            return Color(red: 0.94 + r * 0.04, green: 0.92 + g * 0.04, blue: 0.96 + b * 0.03)
        }
    }

    // Dynamic header background view
    @ViewBuilder
    private var headerBackground: some View {
        if themeManager.dynamicHeaderEnabled {
            Image(themeManager.currentHeaderImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            topSectionGradient
        }
    }

    // Text colors for greeting (adapts to dynamic header)
    private var greetingSubtitleColor: Color {
        if themeManager.dynamicHeaderEnabled {
            // With dark overlay, use light text for all time states
            return Color.white.opacity(0.85)
        }
        return colorScheme == .dark
            ? Color(red: 0.75, green: 0.70, blue: 0.85)
            : Color(red: 0.5, green: 0.45, blue: 0.55)
    }

    private var greetingTitleColor: Color {
        if themeManager.dynamicHeaderEnabled {
            // With dark overlay, use white text for all time states
            return .white
        }
        return colorScheme == .dark ? .white : Color(red: 0.15, green: 0.12, blue: 0.25)
    }

    // MARK: - Greeting Header

    private var greetingHeader: some View {
        HStack(spacing: 12) {
            // Mascot avatar
            Image("ProfileMascot")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 65, height: 65)

            // Greeting text
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(greeting)
                        .font(.subheadline)
                        .foregroundStyle(greetingSubtitleColor)
                        .shadow(color: themeManager.dynamicHeaderEnabled ? .black.opacity(0.5) : .clear, radius: 3, x: 0, y: 1)

                    Text(greetingEmoji)
                        .font(.subheadline)
                }

                Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.abbreviated)))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(greetingTitleColor)
                    .shadow(color: themeManager.dynamicHeaderEnabled ? .black.opacity(0.5) : .clear, radius: 3, x: 0, y: 1)
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
                    .background(themeManager.primaryGradient)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Add new habit")
            .accessibilityHint("Double tap to create a new habit")
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
                FloatingClouds()

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
                        // Background layer - extends into safe area
                        if themeManager.dynamicHeaderEnabled {
                            // Dynamic header image with overlay for text visibility
                            GeometryReader { geo in
                                Image(themeManager.currentHeaderImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geo.size.width, height: habits.isEmpty ? 220 : 320)
                                    .clipped()
                            }
                            .frame(height: habits.isEmpty ? 220 : 320)
                            .clipShape(WaveBottomEdge(amplitude: 25))
                            .ignoresSafeArea(edges: .top)
                        } else {
                            // Original gradient background
                            topSectionTopColor
                                .frame(height: 80)
                                .ignoresSafeArea(edges: .top)

                            VStack {}
                                .frame(maxWidth: .infinity)
                                .frame(height: habits.isEmpty ? 180 : 280)
                                .background(topSectionGradient)
                                .clipShape(WaveBottomEdge(amplitude: 25))
                        }

                        // Content layer (text, progress card)
                        VStack(spacing: 6) {
                            // Greeting header
                            greetingHeader

                            // Today's Progress Card
                            if !habits.isEmpty {
                                WhiteProgressCard(habits: Array(habits), showDynamicBackground: themeManager.dynamicHeaderEnabled)
                                    .id(refreshID) // Force re-render when day changes
                                    .padding(.bottom, 8) // Extra padding from wave
                            } else {
                                Text("Add habits to track progress")
                                    .font(.subheadline)
                                    .foregroundStyle(greetingSubtitleColor)
                                    .shadow(color: themeManager.dynamicHeaderEnabled ? .black.opacity(0.3) : .clear, radius: 2, x: 0, y: 1)
                                    .padding(.vertical, 12)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 30) // Space for wave curve
                        .frame(maxWidth: .infinity)
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

                // Show widget promo when user adds their first habit
                if !dismissedWidgetPromo && newHabits.count == 1 && !showingWidgetPromo {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3)) {
                        showingWidgetPromo = true
                    }
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    let calendar = Calendar.current
                    let now = Date()

                    // Check if we've crossed into a new day since last active
                    if !calendar.isDate(lastActiveDate, inSameDayAs: now) {
                        // Day changed - force UI refresh
                        refreshID = UUID()
                    }

                    // Always update last active timestamp
                    updateLastActiveDate()

                    // Sync HealthKit habits when app becomes active
                    Task {
                        await syncHealthKitHabits()
                    }
                    // Update widgets with fresh data
                    WidgetDataManager.shared.updateWidgetData(habits: habits)
                    // Update Apple Watch
                    WatchConnectivityManager.shared.sendHabitsToWatch(Array(habits))
                }
            }
            .onAppear {
                let calendar = Calendar.current
                let now = Date()

                // CRITICAL: Check if we're on a new day (handles fresh launch after termination)
                if lastActiveDateTimestamp == 0 || !calendar.isDate(lastActiveDate, inSameDayAs: now) {
                    // Force UI to re-compute all habit completion states
                    refreshID = UUID()
                    updateLastActiveDate()
                }

                // Initial sync with fresh computed values
                WidgetDataManager.shared.updateWidgetData(habits: habits)
                // Initial Watch sync
                WatchConnectivityManager.shared.sendHabitsToWatch(Array(habits))
                // Generate suggestions
                refreshSuggestions()

                // Show widget promo if not dismissed and user has habits
                if !dismissedWidgetPromo && !habits.isEmpty {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.5)) {
                        showingWidgetPromo = true
                    }
                }
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
            .overlay(alignment: .top) {
                VStack(spacing: 8) {
                    if showingLocalStorageBanner {
                        LocalStorageBanner {
                            withAnimation {
                                showingLocalStorageBanner = false
                            }
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    if showingSyncError, let error = syncError {
                        SyncErrorBanner(message: error) {
                            withAnimation {
                                showingSyncError = false
                            }
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding(.top, 60)
            }
            .onAppear {
                // Show local storage banner if CloudKit failed
                if isUsingLocalStorage && !UserDefaults.standard.bool(forKey: "dismissedLocalStorageBanner") {
                    showingLocalStorageBanner = true
                }
            }
        }
    }

    // MARK: - Local Storage Banner

    private struct LocalStorageBanner: View {
        let onDismiss: () -> Void

        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: "icloud.slash")
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Offline Mode")
                        .font(.subheadline.weight(.medium))
                    Text("Data is saved locally only")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    UserDefaults.standard.set(true, forKey: "dismissedLocalStorageBanner")
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
    }

    // MARK: - Sync Error Banner

    private struct SyncErrorBanner: View {
        let message: String
        let onDismiss: () -> Void

        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.icloud")
                    .foregroundStyle(.orange)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
            .padding(.horizontal, 16)
        }
    }

    // MARK: - HealthKit Sync

    private func syncHealthKitHabits() async {
        let healthKitHabits = habits.filter { $0.dataSource == .healthKit }
        var syncFailed = false

        for habit in healthKitHabits {
            do {
                if let value = try await healthKitManager.syncHabitFromHealthKit(habit) {
                    await MainActor.run {
                        updateOrCreateCompletion(for: habit, value: value)
                    }
                }
            } catch let error as NSError {
                // Error code 11 = "No data available" - this is expected when no health data exists
                // Don't treat it as a sync failure
                if error.domain == "com.apple.healthkit" && error.code == 11 {
                    #if DEBUG
                    print("\(habit.name): No health data available for today (this is normal)")
                    #endif
                } else {
                    syncFailed = true
                    #if DEBUG
                    print("Failed to sync \(habit.name): \(error)")
                    #endif
                }
            }
        }

        // Show error banner if any sync failed
        if syncFailed {
            await MainActor.run {
                syncError = "Some health data couldn't sync"
                withAnimation {
                    showingSyncError = true
                }
                // Auto-dismiss after 5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    withAnimation {
                        showingSyncError = false
                    }
                }
            }
        }
    }

    private func updateOrCreateCompletion(for habit: Habit, value: Double) {
        let calendar = Calendar.current

        if let existing = habit.safeCompletions.first(where: { calendar.isDateInToday($0.date) }) {
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
            for completion in habit.safeCompletions {
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

            // Widget Promo Banner (show if not dismissed and user has habits)
            if showingWidgetPromo {
                WidgetPromoBanner {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showingWidgetPromo = false
                    }
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .scale(scale: 0.9).combined(with: .opacity)
                ))
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
