//
//  HabitRowView.swift
//  HabitFlowWatch
//
//  Created by Claude on 14.01.2026.
//

import SwiftUI

struct HabitRowView: View {
    let habit: WatchHabitData
    let onToggle: () -> Void

    private var habitColor: Color {
        Color(hex: habit.color)
    }

    private let primaryPurple = Color(hex: "#A855F7")
    private let primaryPink = Color(hex: "#EC4899")

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 8) {
                // Habit Icon with gradient background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [habitColor.opacity(0.8), habitColor.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)

                    Image(systemName: habit.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }

                // Habit Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    // Streak with fire icon
                    if habit.currentStreak > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange, .red],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )

                            Text("\(habit.currentStreak) day streak")
                                .font(.system(size: 9))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                }

                Spacer(minLength: 4)

                // Completion Toggle
                ZStack {
                    if habit.isCompletedToday {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#10B981"), Color(hex: "#059669")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 26, height: 26)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    } else {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 26, height: 26)

                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [primaryPurple.opacity(0.6), primaryPink.opacity(0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 26, height: 26)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.12),
                                Color.white.opacity(0.06)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Color Extension for Watch

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 8) {
            HabitRowView(
                habit: WatchHabitData(
                    id: UUID(),
                    name: "Meditation",
                    icon: "brain.head.profile",
                    color: "#A855F7",
                    isCompletedToday: false,
                    currentStreak: 5
                ),
                onToggle: {}
            )
            HabitRowView(
                habit: WatchHabitData(
                    id: UUID(),
                    name: "Exercise",
                    icon: "figure.run",
                    color: "#10B981",
                    isCompletedToday: true,
                    currentStreak: 12
                ),
                onToggle: {}
            )
        }
        .padding()
    }
}
