//
//  HabitTypeCard.swift
//  HabitTracker
//
//  Created by Sebastián Kučera on 12.01.2026.
//

import SwiftUI

struct HabitTypeCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    var badge: String? = nil
    let primaryText: Color
    let secondaryText: Color
    let tertiaryText: Color
    let colorScheme: ColorScheme
    let isSelected: Bool
    var isLocked: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(colorScheme == .dark ? 0.3 : 0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(primaryText)

                        if let badge = badge {
                            Text(badge)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    badge == "PRO"
                                        ? LinearGradient(
                                            colors: [Color(hex: "#A855F7"), Color(hex: "#EC4899")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                        : LinearGradient(colors: [color, color], startPoint: .leading, endPoint: .trailing)
                                )
                                .clipShape(Capsule())
                        }
                    }

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(secondaryText)
                }

                Spacer()

                Image(systemName: isLocked ? "lock.fill" : "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(tertiaryText)
            }
            .padding(16)
            .liquidGlass(cornerRadius: 20)
            .shadow(color: color.opacity(0.15), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(subtitle)\(isLocked ? ", Premium feature" : "")")
        .accessibilityHint(isLocked ? "Double tap to unlock with Premium" : "Double tap to select this habit type")
    }
}

// MARK: - Data Source Button

struct DataSourceButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let isEnabled: Bool
    let accentColor: Color
    let primaryText: Color
    let secondaryText: Color
    let tertiaryText: Color
    let colorScheme: ColorScheme
    let action: () -> Void

    var body: some View {
        let cardBackground = colorScheme == .dark ? Color.white.opacity(0.1) : Color(red: 0.9, green: 0.88, blue: 0.95)

        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? accentColor : tertiaryText)

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isSelected ? primaryText : secondaryText)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(tertiaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? accentColor.opacity(0.1) : cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? accentColor : tertiaryText.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(subtitle)")
        .accessibilityHint(isEnabled ? "Double tap to select" : "Not available")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Goal Progression Pill

struct GoalProgressionPill: View {
    let progression: GoalProgression
    let isSelected: Bool
    let accentColor: Color
    let primaryText: Color
    let secondaryText: Color
    let colorScheme: ColorScheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: progression.icon)
                    .font(.caption)
                Text(progression.displayName)
                    .font(.caption.weight(.medium))
            }
            .foregroundStyle(isSelected ? .white : secondaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? accentColor : accentColor.opacity(0.15))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(progression.displayName)
        .accessibilityHint("Double tap to select this goal progression type")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
