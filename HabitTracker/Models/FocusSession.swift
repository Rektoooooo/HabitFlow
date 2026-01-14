//
//  FocusSession.swift
//  HabitTracker
//
//  Created by Claude on 14.01.2026.
//

import Foundation
import SwiftData

// MARK: - Focus Session Model

@Model
class FocusSession {
    var id: UUID = UUID()
    var habitId: UUID = UUID()
    var habitName: String = ""
    var habitIcon: String = "timer"
    var habitColor: String = "#A855F7"
    var duration: Int = 1500 // Duration in seconds (default 25 min)
    var startedAt: Date = Date()
    var completedAt: Date?
    var wasCompleted: Bool = false

    init(
        habit: Habit,
        duration: Int
    ) {
        self.id = UUID()
        self.habitId = habit.id
        self.habitName = habit.name
        self.habitIcon = habit.icon
        self.habitColor = habit.color
        self.duration = duration
        self.startedAt = Date()
        self.wasCompleted = false
    }

    // MARK: - Computed Properties

    var durationMinutes: Int {
        duration / 60
    }

    var actualDuration: Int? {
        guard let completed = completedAt else { return nil }
        return Int(completed.timeIntervalSince(startedAt))
    }
}

// MARK: - Focus Duration Presets

enum FocusDuration: Int, CaseIterable, Identifiable {
    case quick = 900      // 15 min
    case standard = 1500  // 25 min (Pomodoro)
    case extended = 2700  // 45 min
    case long = 3600      // 60 min

    var id: Int { rawValue }

    var seconds: Int { rawValue }

    var minutes: Int { rawValue / 60 }

    var label: String {
        switch self {
        case .quick: return "15 min"
        case .standard: return "25 min"
        case .extended: return "45 min"
        case .long: return "60 min"
        }
    }

    var description: String {
        switch self {
        case .quick: return "Quick focus"
        case .standard: return "Pomodoro"
        case .extended: return "Deep work"
        case .long: return "Marathon"
        }
    }

    var icon: String {
        switch self {
        case .quick: return "hare.fill"
        case .standard: return "timer"
        case .extended: return "brain.head.profile"
        case .long: return "mountain.2.fill"
        }
    }
}

// MARK: - Focus Session State

enum FocusSessionState: Equatable {
    case idle
    case running
    case paused
    case completed
}
