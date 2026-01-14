//
//  WaveSeparator.swift
//  HabitTracker
//
//  Created by Sebastián Kučera on 13.01.2026.
//

import SwiftUI

// MARK: - Wave Bottom Edge Shape (for clipping white card)

struct WaveBottomEdge: Shape {
    var amplitude: CGFloat = 20

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height
        let waveHeight: CGFloat = amplitude

        // Start from top-left
        path.move(to: CGPoint(x: 0, y: 0))

        // Left edge down to wave start
        path.addLine(to: CGPoint(x: 0, y: height - waveHeight))

        // Create smooth wave at bottom using cubic curves for smoother appearance
        path.addCurve(
            to: CGPoint(x: width * 0.25, y: height - waveHeight + amplitude * 0.6),
            control1: CGPoint(x: width * 0.1, y: height - waveHeight),
            control2: CGPoint(x: width * 0.15, y: height - waveHeight + amplitude * 0.6)
        )

        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height - waveHeight),
            control1: CGPoint(x: width * 0.35, y: height - waveHeight + amplitude * 0.6),
            control2: CGPoint(x: width * 0.4, y: height - waveHeight)
        )

        path.addCurve(
            to: CGPoint(x: width * 0.75, y: height - waveHeight - amplitude * 0.4),
            control1: CGPoint(x: width * 0.6, y: height - waveHeight),
            control2: CGPoint(x: width * 0.65, y: height - waveHeight - amplitude * 0.4)
        )

        path.addCurve(
            to: CGPoint(x: width, y: height - waveHeight),
            control1: CGPoint(x: width * 0.85, y: height - waveHeight - amplitude * 0.4),
            control2: CGPoint(x: width * 0.9, y: height - waveHeight)
        )

        // Right edge up
        path.addLine(to: CGPoint(x: width, y: 0))

        path.closeSubpath()

        return path
    }
}

// MARK: - Pull Handle (the small grabber in the inspiration)

struct PullHandle: View {
    var body: some View {
        Capsule()
            .fill(Color.gray.opacity(0.4))
            .frame(width: 40, height: 5)
    }
}

// MARK: - Light Frosted Card Modifier

struct LightFrostedCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(0.6))
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.8), lineWidth: 1)
            )
    }
}

extension View {
    func lightFrostedCard(cornerRadius: CGFloat = 20) -> some View {
        modifier(LightFrostedCardModifier(cornerRadius: cornerRadius))
    }
}

#Preview {
    ZStack {
        // Simulated floating clouds background
        LinearGradient(
            colors: [
                Color(red: 0.55, green: 0.75, blue: 1.00),
                Color(red: 0.85, green: 0.65, blue: 1.00),
                Color(red: 0.60, green: 0.78, blue: 1.00),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: 0) {
            // White card with wave bottom edge
            VStack {
                Text("Progress Section")
                    .padding()
                Spacer()
            }
            .frame(height: 250)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .clipShape(WaveBottomEdge(amplitude: 25))

            // Pull handle
            PullHandle()
                .padding(.top, -15)

            Spacer()
        }
    }
}
