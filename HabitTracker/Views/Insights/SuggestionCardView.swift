//
//  SuggestionCardView.swift
//  HabitTracker
//
//  Created by Claude on 14.01.2026.
//

import SwiftUI

struct SuggestionCardView: View {
    let suggestion: HabitSuggestion
    let onAdd: () -> Void
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var showingDetails = false

    private var primaryText: Color {
        colorScheme == .dark ? .white : Color(red: 0.15, green: 0.12, blue: 0.25)
    }

    private var secondaryText: Color {
        colorScheme == .dark ? .white.opacity(0.7) : Color(red: 0.4, green: 0.35, blue: 0.5)
    }

    private var suggestionColor: Color {
        Color(hex: suggestion.color)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(suggestionColor.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: suggestion.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(suggestionColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(suggestion.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(primaryText)

                    Text(suggestion.reason)
                        .font(.system(size: 12))
                        .foregroundStyle(secondaryText)
                        .lineLimit(1)
                }

                Spacer()

                // Dismiss button
                Button {
                    HapticManager.shared.lightTap()
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(secondaryText)
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                        )
                }
            }

            // Expandable details
            if showingDetails {
                Text(suggestion.detailedReason)
                    .font(.system(size: 13))
                    .foregroundStyle(secondaryText)
                    .padding(.vertical, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Action buttons
            HStack(spacing: 10) {
                // Why this suggestion
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showingDetails.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showingDetails ? "chevron.up" : "lightbulb.fill")
                            .font(.system(size: 11))
                        Text(showingDetails ? "Hide" : "Why this?")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(secondaryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                    )
                }

                Spacer()

                // Add habit button
                Button {
                    HapticManager.shared.mediumTap()
                    onAdd()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                        Text("Add Habit")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(suggestionColor)
                    )
                }
            }
        }
        .padding(16)
        .liquidGlass(cornerRadius: 16)
    }
}

// MARK: - Compact Suggestion Card (for HomeView preview)

struct CompactSuggestionCard: View {
    let suggestion: HabitSuggestion
    let onAdd: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var primaryText: Color {
        colorScheme == .dark ? .white : Color(red: 0.15, green: 0.12, blue: 0.25)
    }

    private var secondaryText: Color {
        colorScheme == .dark ? .white.opacity(0.7) : Color(red: 0.4, green: 0.35, blue: 0.5)
    }

    private var suggestionColor: Color {
        Color(hex: suggestion.color)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(suggestionColor.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: suggestion.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(suggestionColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(suggestion.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(primaryText)

                Text(suggestion.reason)
                    .font(.system(size: 11))
                    .foregroundStyle(secondaryText)
                    .lineLimit(1)
            }

            Spacer()

            // Quick add button
            Button {
                HapticManager.shared.mediumTap()
                onAdd()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(suggestionColor)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.6))
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        SuggestionCardView(
            suggestion: HabitSuggestion(
                name: "Morning Meditation",
                icon: "brain.head.profile",
                color: "#8B5CF6",
                category: .mindfulness,
                reason: "Pairs well with Sleep tracking",
                detailedReason: "Since you're tracking your sleep, adding morning meditation can help you start the day with clarity and build on your rest.",
                relatedTo: ["Sleep"],
                priority: 25
            ),
            onAdd: {},
            onDismiss: {}
        )

        CompactSuggestionCard(
            suggestion: HabitSuggestion(
                name: "Drink Water",
                icon: "drop.fill",
                color: "#06B6D4",
                category: .health,
                reason: "Complements your fitness habits",
                detailedReason: "Staying hydrated is essential for your workout performance.",
                relatedTo: ["Exercise"],
                priority: 20
            ),
            onAdd: {}
        )
    }
    .padding()
    .background(Color(hex: "#0D0B1E"))
}
