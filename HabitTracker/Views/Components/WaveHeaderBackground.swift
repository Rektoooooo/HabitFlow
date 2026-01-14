//
//  WaveHeaderBackground.swift
//  HabitTracker
//
//  Created by Sebastián Kučera on 13.01.2026.
//

import SwiftUI

struct WaveHeaderBackground: View {
    @State private var phase1: CGFloat = 0
    @State private var phase2: CGFloat = 0
    @State private var phase3: CGFloat = 0

    var body: some View {
        ZStack {
            // Deep gradient base
            AppTheme.Gradients.deepPurpleGradient

            // Bottom wave layer - slowest, most opaque
            InvertedWaveShape(amplitude: 25, frequency: 1.2, phase: phase1)
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.Colors.accentPrimary.opacity(0.15),
                            AppTheme.Colors.accentSecondary.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .offset(y: 30)

            // Middle wave layer
            InvertedWaveShape(amplitude: 20, frequency: 1.5, phase: phase2)
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.Colors.accentSecondary.opacity(0.12),
                            AppTheme.Colors.accentPrimary.opacity(0.06)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .offset(y: 15)

            // Top wave layer - fastest, most transparent
            InvertedWaveShape(amplitude: 15, frequency: 2, phase: phase3)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.02)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                phase1 = .pi * 2
            }
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                phase2 = .pi * 2
            }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                phase3 = .pi * 2
            }
        }
    }
}

// MARK: - Compact Wave Header (for smaller sections)

struct CompactWaveHeader: View {
    let height: CGFloat

    init(height: CGFloat = 120) {
        self.height = height
    }

    var body: some View {
        ZStack {
            // Single wave with gradient
            InvertedWaveShape(amplitude: 12, frequency: 1.8, phase: 0)
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.Colors.accentPrimary.opacity(0.2),
                            AppTheme.Colors.accentSecondary.opacity(0.1),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .frame(height: height)
    }
}

#Preview {
    ZStack {
        AppTheme.Colors.background
            .ignoresSafeArea()

        VStack {
            WaveHeaderBackground()
                .frame(height: 200)

            Spacer()
        }
    }
}
