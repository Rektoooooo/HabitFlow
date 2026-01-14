//
//  HapticManager.swift
//  HabitTracker
//
//  Created by Sebastián Kučera on 13.01.2026.
//

import UIKit

/// Centralized haptic feedback manager for consistent tactile feedback throughout the app
final class HapticManager {
    static let shared = HapticManager()

    private init() {}

    // MARK: - Impact Feedback

    /// Light tap - for subtle interactions like toggles, switches
    func lightTap() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Medium tap - for button presses, confirmations
    func mediumTap() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    /// Heavy tap - for significant actions, deletions
    func heavyTap() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    /// Soft tap - for gentle, subtle feedback
    func softTap() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }

    /// Rigid tap - for firm, definitive feedback
    func rigidTap() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred()
    }

    // MARK: - Selection Feedback

    /// Selection changed - for picker changes, segment controls, tab switches
    func selectionChanged() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    // MARK: - Notification Feedback

    /// Success - habit completed, goal reached, streak achieved
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// Warning - approaching limit, reminder
    func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    /// Error - action failed, invalid input
    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    // MARK: - Habit-Specific Feedback

    /// Habit completed - satisfying success feedback
    func habitCompleted() {
        success()
    }

    /// Habit uncompleted - light tap to acknowledge
    func habitUncompleted() {
        lightTap()
    }

    /// All habits completed for the day - celebratory feedback
    func allHabitsCompleted() {
        // Double success tap for extra celebration
        success()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.mediumTap()
        }
    }

    /// Streak milestone reached (7 days, 30 days, etc.)
    func streakMilestone() {
        // Triple tap celebration
        success()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.rigidTap()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.success()
        }
    }

    /// New habit created
    func habitCreated() {
        success()
    }

    /// Habit deleted
    func habitDeleted() {
        heavyTap()
    }

    // MARK: - Navigation Feedback

    /// Tab changed
    func tabChanged() {
        selectionChanged()
    }

    /// Sheet presented
    func sheetPresented() {
        lightTap()
    }

    /// Button pressed
    func buttonPressed() {
        lightTap()
    }
}
