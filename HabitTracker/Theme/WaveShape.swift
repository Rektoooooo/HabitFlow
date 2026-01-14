//
//  WaveShape.swift
//  HabitTracker
//
//  Created by Sebastián Kučera on 13.01.2026.
//

import SwiftUI

// MARK: - Wave Shape

struct WaveShape: Shape {
    var amplitude: CGFloat
    var frequency: CGFloat
    var phase: CGFloat

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    init(amplitude: CGFloat = 20, frequency: CGFloat = 1.5, phase: CGFloat = 0) {
        self.amplitude = amplitude
        self.frequency = frequency
        self.phase = phase
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height
        let midHeight = height * 0.5

        path.move(to: CGPoint(x: 0, y: height))

        // Draw wave from left to right
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let sine = sin((relativeX * frequency * .pi * 2) + phase)
            let y = midHeight + (amplitude * sine)
            path.addLine(to: CGPoint(x: x, y: y))
        }

        // Close the path
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()

        return path
    }
}

// MARK: - Inverted Wave (fills from top)

struct InvertedWaveShape: Shape {
    var amplitude: CGFloat
    var frequency: CGFloat
    var phase: CGFloat

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    init(amplitude: CGFloat = 20, frequency: CGFloat = 1.5, phase: CGFloat = 0) {
        self.amplitude = amplitude
        self.frequency = frequency
        self.phase = phase
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height
        let midHeight = height * 0.5

        path.move(to: CGPoint(x: 0, y: 0))

        // Draw wave from left to right
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let sine = sin((relativeX * frequency * .pi * 2) + phase)
            let y = midHeight + (amplitude * sine)
            path.addLine(to: CGPoint(x: x, y: y))
        }

        // Close the path from top
        path.addLine(to: CGPoint(x: width, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.closeSubpath()

        return path
    }
}

// MARK: - Blob Shape (organic form)

struct BlobShape: Shape {
    var points: Int
    var smoothness: CGFloat

    init(points: Int = 6, smoothness: CGFloat = 0.5) {
        self.points = points
        self.smoothness = smoothness
    }

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        var path = Path()

        let angleIncrement = (2 * .pi) / CGFloat(points)

        // Generate control points
        var controlPoints: [CGPoint] = []
        for i in 0..<points {
            let angle = angleIncrement * CGFloat(i) - .pi / 2
            let variation = 1 + (smoothness * sin(CGFloat(i) * 2.5))
            let r = radius * variation * 0.8
            let point = CGPoint(
                x: center.x + r * cos(angle),
                y: center.y + r * sin(angle)
            )
            controlPoints.append(point)
        }

        guard controlPoints.count >= 3 else { return path }

        path.move(to: controlPoints[0])

        for i in 0..<controlPoints.count {
            let current = controlPoints[i]
            let next = controlPoints[(i + 1) % controlPoints.count]
            let nextNext = controlPoints[(i + 2) % controlPoints.count]

            let cp1 = CGPoint(
                x: current.x + (next.x - controlPoints[(i - 1 + controlPoints.count) % controlPoints.count].x) * 0.25,
                y: current.y + (next.y - controlPoints[(i - 1 + controlPoints.count) % controlPoints.count].y) * 0.25
            )
            let cp2 = CGPoint(
                x: next.x - (nextNext.x - current.x) * 0.25,
                y: next.y - (nextNext.y - current.y) * 0.25
            )

            path.addCurve(to: next, control1: cp1, control2: cp2)
        }

        path.closeSubpath()
        return path
    }
}

#Preview {
    ZStack {
        AppTheme.Colors.background
            .ignoresSafeArea()

        VStack(spacing: 40) {
            // Wave example
            WaveShape(amplitude: 15, frequency: 2, phase: 0)
                .fill(AppTheme.Gradients.accentGradient)
                .frame(height: 100)
                .opacity(0.5)

            // Inverted wave
            InvertedWaveShape(amplitude: 20, frequency: 1.5, phase: .pi / 4)
                .fill(AppTheme.Colors.accentPrimary.opacity(0.3))
                .frame(height: 120)

            // Blob
            BlobShape(points: 6, smoothness: 0.3)
                .fill(AppTheme.Gradients.cyanGradient)
                .frame(width: 150, height: 150)
                .opacity(0.5)
        }
    }
}
