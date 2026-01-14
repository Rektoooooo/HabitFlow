//
//  Insight.swift
//  HabitTracker
//
//  Created by Claude on 14.01.2026.
//

import Foundation
import SwiftUI

// MARK: - Insight Type

enum InsightType: String, CaseIterable {
    case streak
    case pattern
    case milestone
    case improvement
    case correlation
    case motivation

    var icon: String {
        switch self {
        case .streak: return "flame.fill"
        case .pattern: return "chart.line.uptrend.xyaxis"
        case .milestone: return "trophy.fill"
        case .improvement: return "arrow.up.circle.fill"
        case .correlation: return "link"
        case .motivation: return "star.fill"
        }
    }

    var color: Color {
        switch self {
        case .streak: return Color(hex: "#F97316")
        case .pattern: return Color(hex: "#3B82F6")
        case .milestone: return Color(hex: "#F59E0B")
        case .improvement: return Color(hex: "#10B981")
        case .correlation: return Color(hex: "#8B5CF6")
        case .motivation: return Color(hex: "#EC4899")
        }
    }
}

// MARK: - Insight Priority

enum InsightPriority: Int, Comparable {
    case low = 1
    case medium = 2
    case high = 3
    case urgent = 4

    static func < (lhs: InsightPriority, rhs: InsightPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Insight

struct Insight: Identifiable, Equatable {
    let id = UUID()
    let type: InsightType
    let title: String
    let message: String
    let detail: String?
    let priority: InsightPriority
    let relatedHabitId: UUID?
    let relatedHabitName: String?
    let value: Double?
    let isPositive: Bool
    let actionable: Bool
    let createdAt: Date

    init(
        type: InsightType,
        title: String,
        message: String,
        detail: String? = nil,
        priority: InsightPriority = .medium,
        relatedHabitId: UUID? = nil,
        relatedHabitName: String? = nil,
        value: Double? = nil,
        isPositive: Bool = true,
        actionable: Bool = false
    ) {
        self.type = type
        self.title = title
        self.message = message
        self.detail = detail
        self.priority = priority
        self.relatedHabitId = relatedHabitId
        self.relatedHabitName = relatedHabitName
        self.value = value
        self.isPositive = isPositive
        self.actionable = actionable
        self.createdAt = Date()
    }

    static func == (lhs: Insight, rhs: Insight) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Day of Week Stats

struct DayOfWeekStats {
    let dayName: String
    let dayIndex: Int // 1 = Sunday, 2 = Monday, etc.
    let completionCount: Int
    let completionRate: Double
}

// MARK: - Weekly Comparison

struct WeeklyComparison {
    let currentWeekCompletions: Int
    let previousWeekCompletions: Int
    let changePercent: Double
    let isImprovement: Bool
}
