//
//  HabitCompletion.swift
//  HabitTracker
//
//  Created by Sebastián Kučera on 12.01.2026.
//

import Foundation
import SwiftData

@Model
class HabitCompletion {
    @Attribute(.unique) var id: UUID
    var date: Date
    var habit: Habit?

    // HealthKit value tracking
    var value: Double?         // Numeric value (e.g., 2000ml, 7.5 hours)
    var isAutoSynced: Bool     // Track if from HealthKit

    init(date: Date = Date(), habit: Habit? = nil, value: Double? = nil, isAutoSynced: Bool = false) {
        self.id = UUID()
        self.date = date
        self.habit = habit
        self.value = value
        self.isAutoSynced = isAutoSynced
    }
}
