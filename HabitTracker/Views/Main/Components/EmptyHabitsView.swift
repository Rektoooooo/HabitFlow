//
//  EmptyHabitsView.swift
//  HabitTracker
//
//  Created by Sebastián Kučera on 12.01.2026.
//

import SwiftUI

struct EmptyHabitsView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 60)

            ZStack {
                Circle()
                    .fill(AppTheme.Gradients.accentGradient)
                    .frame(width: 120, height: 120)
                    .blur(radius: 40)
                    .opacity(0.5)

                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundStyle(AppTheme.Gradients.accentGradient)
            }

            VStack(spacing: 12) {
                Text("Start Your Journey")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Text("Build better habits, one day at a time.\nTap the + button to create your first habit.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 8) {
                Image(systemName: "arrow.down")
                    .font(.title2)
                    .foregroundStyle(AppTheme.Colors.accentPrimary)

                Text("Tap + to add a habit")
                    .font(.caption)
                    .foregroundStyle(AppTheme.Colors.textTertiary)
            }
            .padding(.top, 20)

            Spacer()
        }
    }
}

#Preview {
    EmptyHabitsView()
}
