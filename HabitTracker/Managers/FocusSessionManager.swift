//
//  FocusSessionManager.swift
//  HabitTracker
//
//  Created by Claude on 14.01.2026.
//

import Foundation
import SwiftUI
import SwiftData
import Combine
import UserNotifications

@MainActor
class FocusSessionManager: ObservableObject {
    static let shared = FocusSessionManager()

    // MARK: - Published Properties

    @Published var currentSession: FocusSession?
    @Published var currentHabit: Habit?
    @Published var state: FocusSessionState = .idle
    @Published var remainingSeconds: Int = 0
    @Published var totalSeconds: Int = 0
    @Published var isShowingTimer: Bool = false

    // MARK: - Private Properties

    private var timer: Timer?
    private var backgroundDate: Date?
    private let notificationIdentifier = "focusSessionComplete"

    private init() {
        setupNotifications()
    }

    // MARK: - Computed Properties

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - remainingSeconds) / Double(totalSeconds)
    }

    var elapsedSeconds: Int {
        totalSeconds - remainingSeconds
    }

    var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var formattedElapsed: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Session Control

    func startSession(habit: Habit, duration: Int, in context: ModelContext) {
        // Create new session
        let session = FocusSession(habit: habit, duration: duration)
        context.insert(session)

        currentSession = session
        currentHabit = habit
        totalSeconds = duration
        remainingSeconds = duration
        state = .running
        isShowingTimer = true

        startTimer()
        scheduleCompletionNotification(habitName: habit.name, seconds: duration)
        HapticManager.shared.buttonPressed()
    }

    func pause() {
        guard state == .running else { return }
        state = .paused
        timer?.invalidate()
        timer = nil
        cancelCompletionNotification()
        HapticManager.shared.buttonPressed()
    }

    func resume() {
        guard state == .paused else { return }
        state = .running
        startTimer()
        if let habitName = currentHabit?.name {
            scheduleCompletionNotification(habitName: habitName, seconds: remainingSeconds)
        }
        HapticManager.shared.buttonPressed()
    }

    func cancel() {
        timer?.invalidate()
        timer = nil
        state = .idle
        currentSession = nil
        currentHabit = nil
        remainingSeconds = 0
        totalSeconds = 0
        isShowingTimer = false
        cancelCompletionNotification()
    }

    func complete(in context: ModelContext) {
        timer?.invalidate()
        timer = nil
        cancelCompletionNotification()

        // Mark session as completed
        currentSession?.completedAt = Date()
        currentSession?.wasCompleted = true

        // Auto-complete the habit
        if let habit = currentHabit {
            completeHabit(habit, in: context)
        }

        state = .completed
        HapticManager.shared.habitCompleted()

        // Reset after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.reset()
        }
    }

    func reset() {
        state = .idle
        currentSession = nil
        currentHabit = nil
        remainingSeconds = 0
        totalSeconds = 0
        isShowingTimer = false
    }

    // MARK: - Private Methods

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
    }

    private func tick() {
        guard state == .running else { return }

        if remainingSeconds > 0 {
            remainingSeconds -= 1
        }

        // Check if completed
        if remainingSeconds == 0 {
            // Don't auto-complete here - let the view handle it
            // so we can show the completion animation
            state = .completed
            HapticManager.shared.allHabitsCompleted()
        }
    }

    private func completeHabit(_ habit: Habit, in context: ModelContext) {
        // Check if already completed today
        if habit.isCompletedToday { return }

        // Create completion
        let completion = HabitCompletion(date: Date(), habit: habit)
        habit.completions.append(completion)
        context.insert(completion)

        try? context.save()

        // Notify widgets
        NotificationCenter.default.post(name: .habitsDidChange, object: nil)
    }

    // MARK: - Background Handling

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleEnterBackground()
            }
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleEnterForeground()
            }
        }
    }

    private func handleEnterBackground() {
        guard state == .running else { return }
        backgroundDate = Date()
        timer?.invalidate()
        timer = nil
    }

    private func handleEnterForeground() {
        guard state == .running, let background = backgroundDate else { return }

        let elapsed = Int(Date().timeIntervalSince(background))
        remainingSeconds = max(0, remainingSeconds - elapsed)
        backgroundDate = nil

        if remainingSeconds > 0 {
            startTimer()
        } else {
            state = .completed
            HapticManager.shared.allHabitsCompleted()
        }
    }

    // MARK: - Statistics

    func getTotalFocusTime(sessions: [FocusSession]) -> Int {
        sessions
            .filter { $0.wasCompleted }
            .reduce(0) { $0 + $1.duration }
    }

    func getTodayFocusTime(sessions: [FocusSession]) -> Int {
        let calendar = Calendar.current
        return sessions
            .filter { $0.wasCompleted && calendar.isDateInToday($0.startedAt) }
            .reduce(0) { $0 + $1.duration }
    }

    func getWeekFocusTime(sessions: [FocusSession]) -> Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return sessions
            .filter { $0.wasCompleted && $0.startedAt >= weekAgo }
            .reduce(0) { $0 + $1.duration }
    }

    func getSessionCount(sessions: [FocusSession]) -> Int {
        sessions.filter { $0.wasCompleted }.count
    }

    func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    // MARK: - Local Notifications

    private func scheduleCompletionNotification(habitName: String, seconds: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Focus Session Complete!"
        content.body = "Great job! You've completed your \(habitName) focus session."
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(seconds),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: notificationIdentifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule focus notification: \(error)")
            }
        }
    }

    private func cancelCompletionNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [notificationIdentifier]
        )
    }
}
