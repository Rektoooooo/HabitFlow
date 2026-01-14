//
//  ActivityIconGrid.swift
//  HabitTracker
//
//  Created by Sebastián Kučera on 13.01.2026.
//

import SwiftUI

// MARK: - Activity Definition

struct ActivityType: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    let habitType: HabitType
    let suggestedGoal: Double?
    let unit: String?
}

// MARK: - Predefined Activities

extension ActivityType {
    static let activities: [ActivityType] = [
        // Health & Fitness
        ActivityType(name: "Running", icon: "figure.run", color: .orange, habitType: .manual, suggestedGoal: nil, unit: nil),
        ActivityType(name: "Walking", icon: "figure.walk", color: .green, habitType: .manual, suggestedGoal: nil, unit: nil),
        ActivityType(name: "Cycling", icon: "bicycle", color: .blue, habitType: .manual, suggestedGoal: nil, unit: nil),
        ActivityType(name: "Swimming", icon: "figure.pool.swim", color: .cyan, habitType: .manual, suggestedGoal: nil, unit: nil),
        ActivityType(name: "Gym", icon: "dumbbell.fill", color: .purple, habitType: .manual, suggestedGoal: nil, unit: nil),
        ActivityType(name: "Yoga", icon: "figure.yoga", color: .pink, habitType: .manual, suggestedGoal: nil, unit: nil),

        // Wellness
        ActivityType(name: "Sleep", icon: "moon.fill", color: .indigo, habitType: .healthKitSleep, suggestedGoal: 8, unit: "hours"),
        ActivityType(name: "Water", icon: "drop.fill", color: .cyan, habitType: .healthKitWater, suggestedGoal: 2000, unit: "ml"),
        ActivityType(name: "Calories", icon: "flame.fill", color: .orange, habitType: .healthKitCalories, suggestedGoal: 500, unit: "kcal"),

        // Mindfulness
        ActivityType(name: "Meditate", icon: "brain.head.profile", color: .teal, habitType: .manual, suggestedGoal: nil, unit: nil),
        ActivityType(name: "Read", icon: "book.fill", color: .brown, habitType: .manual, suggestedGoal: nil, unit: nil),
        ActivityType(name: "Journal", icon: "pencil.line", color: .mint, habitType: .manual, suggestedGoal: nil, unit: nil),

        // Lifestyle
        ActivityType(name: "No Phone", icon: "iphone.slash", color: .gray, habitType: .manual, suggestedGoal: nil, unit: nil),
        ActivityType(name: "No Sugar", icon: "cup.and.saucer.fill", color: .red, habitType: .manual, suggestedGoal: nil, unit: nil),
        ActivityType(name: "Vitamins", icon: "pills.fill", color: .yellow, habitType: .manual, suggestedGoal: nil, unit: nil),
        ActivityType(name: "Custom", icon: "plus.circle.fill", color: AppTheme.Colors.accentPrimary, habitType: .manual, suggestedGoal: nil, unit: nil),
    ]
}

// MARK: - Activity Icon Button

struct ActivityIconButton: View {
    let activity: ActivityType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    // Background
                    Circle()
                        .fill(isSelected ? activity.color : activity.color.opacity(0.15))
                        .frame(width: 56, height: 56)

                    // Selection ring
                    if isSelected {
                        Circle()
                            .stroke(activity.color, lineWidth: 3)
                            .frame(width: 64, height: 64)
                    }

                    // Icon
                    Image(systemName: activity.icon)
                        .font(.system(size: 22))
                        .foregroundStyle(isSelected ? .white : activity.color)
                }

                Text(activity.name)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? AppTheme.Colors.textPrimary : AppTheme.Colors.textSecondary)
                    .lineLimit(1)
            }
            .frame(width: 70)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Activity Icon Grid

struct ActivityIconGrid: View {
    @Binding var selectedActivity: ActivityType?
    let onActivitySelected: (ActivityType) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 70), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose Activity")
                .font(.headline)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(ActivityType.activities) { activity in
                    ActivityIconButton(
                        activity: activity,
                        isSelected: selectedActivity?.id == activity.id
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedActivity = activity
                        }
                        onActivitySelected(activity)
                    }
                }
            }
        }
        .padding(20)
        .frostedCard(cornerRadius: 24)
    }
}

#Preview {
    ZStack {
        AppTheme.Colors.background
            .ignoresSafeArea()

        ScrollView {
            ActivityIconGrid(selectedActivity: .constant(nil)) { _ in }
                .padding()
        }
    }
}
