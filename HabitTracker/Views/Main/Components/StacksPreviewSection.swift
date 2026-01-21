//
//  StacksPreviewSection.swift
//  HabitTracker
//
//  Created by Sebastián Kučera on 12.01.2026.
//

import SwiftUI

struct StacksPreviewSection: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var themeManager = ThemeManager.shared
    let stacks: [HabitStack]
    let habits: [Habit]
    let onShowStacks: () -> Void
    let onCreateStack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "link.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "#8B5CF6"), Color(hex: "#06B6D4")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Habit Chains")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(colorScheme == .dark ? .white : Color(red: 0.15, green: 0.12, blue: 0.25))
                }

                Spacer()

                Button {
                    onShowStacks()
                } label: {
                    Text("See all")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(themeManager.primaryColor)
                }
            }

            // Show active stacks (max 2)
            ForEach(stacks.filter { $0.isActive }.prefix(2)) { stack in
                CompactStackCard(
                    stack: stack,
                    habits: habits,
                    onTap: { onShowStacks() }
                )
            }

            // Create stack button if no stacks
            if stacks.isEmpty {
                Button {
                    onShowStacks()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(Color(hex: "#8B5CF6"))
                        Text("Create a habit chain")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(hex: "#8B5CF6").opacity(0.1))
                    )
                }
            }
        }
        .padding(.top, 8)
    }
}
