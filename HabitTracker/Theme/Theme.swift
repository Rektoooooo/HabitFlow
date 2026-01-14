//
//  Theme.swift
//  HabitTracker
//
//  Created by Sebastián Kučera on 12.01.2026.
//

import SwiftUI

// MARK: - App Theme

struct AppTheme {
    // MARK: - Colors

    struct Colors {
        // Backgrounds
        static let background = Color(hex: "#0D0B1E")
        static let cardBackground = Color(hex: "#1A1730")
        static let cardBackgroundLight = Color(hex: "#252142")
        static let surfaceBackground = Color(hex: "#13112A")

        // Primary Accent (Purple-Pink)
        static let accentPrimary = Color(hex: "#A855F7")
        static let accentSecondary = Color(hex: "#EC4899")
        static let accentTertiary = Color(hex: "#06B6D4")

        // Text
        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.7)
        static let textTertiary = Color.white.opacity(0.4)

        // Status
        static let success = Color(hex: "#34D399")
        static let warning = Color(hex: "#FBBF24")
        static let error = Color(hex: "#F87171")

        // Glow Colors
        static let glowPurple = Color(hex: "#A855F7").opacity(0.5)
        static let glowPink = Color(hex: "#EC4899").opacity(0.5)
        static let glowCyan = Color(hex: "#06B6D4").opacity(0.5)
    }

    // MARK: - Gradients

    struct Gradients {
        static let backgroundGradient = LinearGradient(
            colors: [
                Color(hex: "#0D0B1E"),
                Color(hex: "#1A1730"),
                Color(hex: "#0D0B1E")
            ],
            startPoint: .top,
            endPoint: .bottom
        )

        static let cardGradient = LinearGradient(
            colors: [
                Color(hex: "#1A1730"),
                Color(hex: "#252142")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let accentGradient = LinearGradient(
            colors: [
                Color(hex: "#A855F7"),
                Color(hex: "#EC4899")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let buttonGradient = LinearGradient(
            colors: [
                Color(hex: "#A855F7"),
                Color(hex: "#EC4899"),
                Color(hex: "#F472B6")
            ],
            startPoint: .leading,
            endPoint: .trailing
        )

        static let cyanGradient = LinearGradient(
            colors: [
                Color(hex: "#06B6D4"),
                Color(hex: "#A855F7")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let successGradient = LinearGradient(
            colors: [
                Color(hex: "#34D399"),
                Color(hex: "#06B6D4")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let streakGradient = LinearGradient(
            colors: [
                Color(hex: "#F59E0B"),
                Color(hex: "#EF4444")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        // Wave gradients for decorative backgrounds
        static let waveGradient = LinearGradient(
            colors: [
                Color(hex: "#A855F7").opacity(0.4),
                Color(hex: "#EC4899").opacity(0.2),
                Color.clear
            ],
            startPoint: .top,
            endPoint: .bottom
        )

        static let deepPurpleGradient = LinearGradient(
            colors: [
                Color(hex: "#2D1B4E"),
                Color(hex: "#1A1730"),
                Color(hex: "#0D0B1E")
            ],
            startPoint: .top,
            endPoint: .bottom
        )

        static let frostedOverlay = LinearGradient(
            colors: [
                Color.white.opacity(0.15),
                Color.white.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        // Blue-pink gradient for habits section (inspiration style)
        static let bluePinkGradient = LinearGradient(
            colors: [
                Color(hex: "#E8F4FD"),  // Light blue
                Color(hex: "#F5E6F3"),  // Light pink
                Color(hex: "#D4E5F7"),  // Medium blue
            ],
            startPoint: .top,
            endPoint: .bottom
        )

        // Wave colors
        static let waveBlue = Color(hex: "#7EB6E6")
        static let wavePink = Color(hex: "#E8A4D0")
    }
}

// MARK: - Custom View Modifiers

struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AppTheme.Colors.cardBackground.opacity(0.6))
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                            .opacity(0.3)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

struct GlowingCard: ViewModifier {
    var color: Color = AppTheme.Colors.accentPrimary
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AppTheme.Colors.cardBackground)
                    .shadow(color: color.opacity(0.3), radius: 20, x: 0, y: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
    }
}

struct FrostedCard: ViewModifier {
    var cornerRadius: CGFloat = 20
    var opacity: Double = 0.12
    var blur: Bool = true

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    if blur {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                            .opacity(0.5)
                    }

                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.white.opacity(opacity))
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.25),
                                Color.white.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

// MARK: - Liquid Glass Effect (iOS 26 style)

struct LiquidGlassModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    var cornerRadius: CGFloat = 24

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    if colorScheme == .dark {
                        // Dark mode: More translucent frosted glass
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)

                        // Subtle purple-tinted glass overlay (more transparent)
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.35, green: 0.28, blue: 0.50).opacity(0.25),
                                        Color(red: 0.28, green: 0.22, blue: 0.42).opacity(0.20)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        // Top shine highlight
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.20),
                                        Color.white.opacity(0.08),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )

                        // Subtle inner border glow
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.35),
                                        Color.white.opacity(0.10),
                                        Color(red: 0.6, green: 0.5, blue: 0.8).opacity(0.20)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    } else {
                        // Light mode: Soft white frosted glass
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)

                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.white.opacity(0.35))

                        // Top highlight (liquid shine effect)
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.6),
                                        Color.white.opacity(0.15),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )

                        // Inner glow at edges
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.8),
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.4)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(
                color: colorScheme == .dark
                    ? Color.black.opacity(0.25)
                    : Color(red: 0.4, green: 0.35, blue: 0.5).opacity(0.15),
                radius: colorScheme == .dark ? 8 : 12,
                x: 0,
                y: colorScheme == .dark ? 4 : 6
            )
            .shadow(
                color: colorScheme == .dark
                    ? Color(red: 0.6, green: 0.5, blue: 0.8).opacity(0.08)
                    : Color.white.opacity(0.5),
                radius: 1,
                x: 0,
                y: -1
            )
    }
}

struct PrimaryButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(AppTheme.Gradients.buttonGradient)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: AppTheme.Colors.accentPrimary.opacity(0.4), radius: 16, x: 0, y: 8)
    }
}

// MARK: - View Extensions

extension View {
    func glassCard(cornerRadius: CGFloat = 20) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }

    func glowingCard(color: Color = AppTheme.Colors.accentPrimary, cornerRadius: CGFloat = 20) -> some View {
        modifier(GlowingCard(color: color, cornerRadius: cornerRadius))
    }

    func frostedCard(cornerRadius: CGFloat = 20, opacity: Double = 0.12, blur: Bool = true) -> some View {
        modifier(FrostedCard(cornerRadius: cornerRadius, opacity: opacity, blur: blur))
    }

    func liquidGlass(cornerRadius: CGFloat = 24) -> some View {
        modifier(LiquidGlassModifier(cornerRadius: cornerRadius))
    }

    func primaryButtonStyle() -> some View {
        modifier(PrimaryButton())
    }

    func appBackground() -> some View {
        self.background(AppTheme.Colors.background.ignoresSafeArea())
    }
}

// MARK: - Animated Gradient Background

struct AnimatedMeshBackground: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            AppTheme.Colors.background

            // Animated gradient blobs
            Circle()
                .fill(AppTheme.Colors.accentPrimary.opacity(0.15))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: animate ? 50 : -50, y: animate ? -30 : 30)

            Circle()
                .fill(AppTheme.Colors.accentSecondary.opacity(0.1))
                .frame(width: 250, height: 250)
                .blur(radius: 50)
                .offset(x: animate ? -70 : 70, y: animate ? 50 : -50)

            Circle()
                .fill(AppTheme.Colors.accentTertiary.opacity(0.08))
                .frame(width: 200, height: 200)
                .blur(radius: 40)
                .offset(x: animate ? 30 : -30, y: animate ? 100 : -100)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

// MARK: - Glow Effect

struct GlowEffect: View {
    let color: Color
    let radius: CGFloat

    var body: some View {
        Circle()
            .fill(color)
            .blur(radius: radius)
    }
}
