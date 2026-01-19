//
//  SuggestionsPreviewSection.swift
//  HabitTracker
//
//  Created by Sebastián Kučera on 12.01.2026.
//

import SwiftUI

struct SuggestionsPreviewSection: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var themeManager = ThemeManager.shared
    let suggestions: [HabitSuggestion]
    let onShowSuggestions: () -> Void
    let onSelectSuggestion: (HabitSuggestion) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.subheadline)
                        .foregroundStyle(themeManager.primaryGradient)

                    Text("Suggested for you")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(colorScheme == .dark ? .white : Color(red: 0.15, green: 0.12, blue: 0.25))
                }

                Spacer()

                Button {
                    onShowSuggestions()
                } label: {
                    Text("See all")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(themeManager.primaryColor)
                }
            }
            .padding(.top, 8)

            // Show first 2 suggestions as compact cards
            ForEach(suggestions.prefix(2)) { suggestion in
                CompactSuggestionCard(
                    suggestion: suggestion,
                    onAdd: {
                        onSelectSuggestion(suggestion)
                    }
                )
            }
        }
        .padding(.top, 8)
    }
}
