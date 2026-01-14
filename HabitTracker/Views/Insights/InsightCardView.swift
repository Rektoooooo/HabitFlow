//
//  InsightCardView.swift
//  HabitTracker
//
//  Created by Claude on 14.01.2026.
//

import SwiftUI

struct InsightCardView: View {
    let insight: Insight
    var onTap: (() -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme

    private var primaryText: Color {
        colorScheme == .dark ? .white : Color(red: 0.15, green: 0.12, blue: 0.25)
    }

    private var secondaryText: Color {
        colorScheme == .dark ? .white.opacity(0.7) : Color(red: 0.4, green: 0.35, blue: 0.5)
    }

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(insight.type.color.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: insight.type.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(insight.type.color)
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(insight.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(primaryText)

                        if insight.priority == .urgent {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }

                    Text(insight.message)
                        .font(.caption)
                        .foregroundStyle(secondaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                // Indicator
                if insight.isPositive {
                    Image(systemName: "arrow.up.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.green)
                } else {
                    Image(systemName: "arrow.down.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.orange)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.7))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(insight.type.color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Featured Insight Card (Larger, for top of insights view)

struct FeaturedInsightCard: View {
    let insight: Insight

    @Environment(\.colorScheme) private var colorScheme

    private var primaryText: Color {
        colorScheme == .dark ? .white : Color(red: 0.15, green: 0.12, blue: 0.25)
    }

    private var secondaryText: Color {
        colorScheme == .dark ? .white.opacity(0.7) : Color(red: 0.4, green: 0.35, blue: 0.5)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                ZStack {
                    Circle()
                        .fill(insight.type.color.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: insight.type.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(insight.type.color)
                }

                Spacer()

                if let value = insight.value {
                    Text(formatValue(value))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(insight.type.color)
                }
            }

            // Title and message
            VStack(alignment: .leading, spacing: 6) {
                Text(insight.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(primaryText)

                Text(insight.message)
                    .font(.subheadline)
                    .foregroundStyle(secondaryText)

                if let detail = insight.detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(secondaryText.opacity(0.8))
                        .padding(.top, 2)
                }
            }

            // Related habit badge
            if let habitName = insight.relatedHabitName {
                HStack(spacing: 6) {
                    Image(systemName: "link")
                        .font(.caption2)
                    Text(habitName)
                        .font(.caption.weight(.medium))
                }
                .foregroundStyle(secondaryText)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                )
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            insight.type.color.opacity(0.15),
                            insight.type.color.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(insight.type.color.opacity(0.3), lineWidth: 1)
        )
    }

    private func formatValue(_ value: Double) -> String {
        if value >= 100 {
            return "\(Int(value))"
        } else if value >= 1 {
            return "\(Int(value))"
        } else {
            return "\(Int(value * 100))%"
        }
    }
}

// MARK: - Compact Insight Card (for StatsView preview)

struct CompactInsightCard: View {
    let insight: Insight

    @Environment(\.colorScheme) private var colorScheme

    private var primaryText: Color {
        colorScheme == .dark ? .white : Color(red: 0.15, green: 0.12, blue: 0.25)
    }

    private var secondaryText: Color {
        colorScheme == .dark ? .white.opacity(0.7) : Color(red: 0.4, green: 0.35, blue: 0.5)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(insight.type.color.opacity(0.2))
                    .frame(width: 36, height: 36)

                Image(systemName: insight.type.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(insight.type.color)
            }

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(insight.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(primaryText)
                    .lineLimit(1)

                Text(insight.message)
                    .font(.caption2)
                    .foregroundStyle(secondaryText)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.5))
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        FeaturedInsightCard(
            insight: Insight(
                type: .streak,
                title: "On Fire!",
                message: "Exercise has a 15-day streak!",
                detail: "Keep it going! You're building a strong habit.",
                priority: .high,
                relatedHabitName: "Exercise",
                value: 15,
                isPositive: true
            )
        )

        InsightCardView(
            insight: Insight(
                type: .pattern,
                title: "Your Power Day",
                message: "Saturday is your strongest day with 85% completion rate!",
                priority: .medium,
                value: 0.85,
                isPositive: true
            )
        )

        CompactInsightCard(
            insight: Insight(
                type: .improvement,
                title: "You're Improving!",
                message: "25% more completions than last week!",
                priority: .medium,
                isPositive: true
            )
        )
    }
    .padding()
    .background(Color(hex: "#0D0B1E"))
}
