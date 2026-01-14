//
//  CelebrationView.swift
//  HabitTracker
//
//  Created by Claude on 14.01.2026.
//

import SwiftUI

// MARK: - Confetti Piece

struct ConfettiPiece: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let color: Color
    let rotation: Double
    let scale: CGFloat
    let shape: ConfettiShape

    enum ConfettiShape: CaseIterable {
        case circle, rectangle, triangle
    }
}

// MARK: - Celebration Overlay View

struct CelebrationView: View {
    @Binding var isShowing: Bool
    @State private var confetti: [ConfettiPiece] = []
    @State private var screenSize: CGSize = .zero

    private let confettiColors: [Color] = [
        Color(hex: "#A855F7"), // Purple
        Color(hex: "#EC4899"), // Pink
        Color(hex: "#F59E0B"), // Amber
        Color(hex: "#10B981"), // Emerald
        Color(hex: "#3B82F6"), // Blue
        Color(hex: "#EF4444"), // Red
        Color(hex: "#8B5CF6"), // Violet
        Color(hex: "#06B6D4"), // Cyan
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Confetti particles
                ForEach(confetti) { piece in
                    ConfettiPieceView(piece: piece)
                }
            }
            .onAppear {
                screenSize = geometry.size
                startCelebration()
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Animation Methods

    private func startCelebration() {
        // Generate confetti
        generateConfetti()

        // Animate confetti falling
        animateConfetti()

        // Auto-dismiss after confetti falls
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            isShowing = false
        }
    }

    private func generateConfetti() {
        let screenWidth = screenSize.width > 0 ? screenSize.width : 400

        for _ in 0..<60 {
            let piece = ConfettiPiece(
                x: CGFloat.random(in: 0...screenWidth),
                y: CGFloat.random(in: -150...(-20)),
                color: confettiColors.randomElement() ?? .purple,
                rotation: Double.random(in: 0...360),
                scale: CGFloat.random(in: 0.6...1.2),
                shape: ConfettiPiece.ConfettiShape.allCases.randomElement() ?? .circle
            )
            confetti.append(piece)
        }
    }

    private func animateConfetti() {
        let screenHeight = screenSize.height > 0 ? screenSize.height : 800

        for i in confetti.indices {
            let delay = Double.random(in: 0...0.8)
            let duration = Double.random(in: 2.5...3.5)

            withAnimation(.easeIn(duration: duration).delay(delay)) {
                confetti[i].y = screenHeight + 100
                confetti[i].x += CGFloat.random(in: -80...80)
            }
        }
    }
}

// MARK: - Confetti Piece View

struct ConfettiPieceView: View {
    let piece: ConfettiPiece

    var body: some View {
        Group {
            switch piece.shape {
            case .circle:
                Circle()
                    .fill(piece.color)
                    .frame(width: 10 * piece.scale, height: 10 * piece.scale)
            case .rectangle:
                Rectangle()
                    .fill(piece.color)
                    .frame(width: 8 * piece.scale, height: 14 * piece.scale)
            case .triangle:
                Triangle()
                    .fill(piece.color)
                    .frame(width: 12 * piece.scale, height: 12 * piece.scale)
            }
        }
        .rotationEffect(.degrees(piece.rotation))
        .position(x: piece.x, y: piece.y)
    }
}

// MARK: - Triangle Shape

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    CelebrationView(isShowing: .constant(true))
}
