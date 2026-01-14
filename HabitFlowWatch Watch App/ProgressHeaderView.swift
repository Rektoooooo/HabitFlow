//
//  ProgressHeaderView.swift
//  HabitFlowWatch
//
//  Created by Claude on 14.01.2026.
//

import SwiftUI

struct ProgressHeaderView: View {
    let completed: Int
    let total: Int

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    private var allDone: Bool {
        total > 0 && completed == total
    }

    // Theme colors
    private let primaryPurple = Color(hex: "#A855F7")
    private let primaryPink = Color(hex: "#EC4899")
    private let successGreen = Color(hex: "#10B981")

    var body: some View {
        VStack(spacing: 6) {
            // Progress Ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 8)
                    .frame(width: 70, height: 70)

                // Progress ring with gradient
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            colors: allDone
                                ? [successGreen, successGreen.opacity(0.8)]
                                : [primaryPurple, primaryPink, primaryPurple],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: allDone ? successGreen.opacity(0.5) : primaryPurple.opacity(0.5), radius: 4)

                // Center content
                if allDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [successGreen, Color(hex: "#059669")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                } else {
                    VStack(spacing: 0) {
                        Text("\(completed)")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)

                        Text("/\(total)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }

            // Status Text
            Text(allDone ? "All Done!" : "Today's Progress")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(allDone ? successGreen : .white.opacity(0.6))
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 20) {
            ProgressHeaderView(completed: 2, total: 4)
            ProgressHeaderView(completed: 4, total: 4)
            ProgressHeaderView(completed: 0, total: 3)
        }
    }
}
