//
//  FloatingClouds.swift
//  HabitTracker
//
//  Adapted from ShadowLift by Sebastián Kučera
//

import SwiftUI
import Combine

// MARK: - Clouds Theme

struct CloudsTheme {
    var background: Color
    var topLeading: Color
    var topTrailing: Color
    var bottomLeading: Color
    var bottomTrailing: Color

    // MARK: - Dynamic HabitTracker Theme (uses ThemeManager accent color)

    static func habitTracker(_ scheme: ColorScheme) -> CloudsTheme {
        let accentColor = ThemeManager.shared.accentColor
        return dynamicTheme(for: accentColor, scheme: scheme)
    }

    // MARK: - Dynamic Theme Based on Accent Color

    static func dynamicTheme(for accent: AccentColor, scheme: ColorScheme) -> CloudsTheme {
        // Get the RGB components of the accent color
        let (r, g, b) = accent.rgbComponents

        if scheme == .dark {
            // Dark mode: Deep background with accent-tinted clouds
            // Background uses a very dark version of the accent
            let bgR = r * 0.12
            let bgG = g * 0.08
            let bgB = b * 0.15

            return CloudsTheme(
                // Deep dark background tinted with accent
                background: Color(red: max(0.05, bgR), green: max(0.03, bgG), blue: max(0.10, bgB)),
                // Top left - vibrant accent color
                topLeading: Color(red: r * 0.85, green: g * 0.65, blue: b * 0.95).opacity(0.75),
                // Top right - shifted accent
                topTrailing: Color(red: r * 0.6, green: g * 0.75, blue: b * 0.85).opacity(0.60),
                // Bottom left - deeper accent
                bottomLeading: Color(red: r * 0.7, green: g * 0.5, blue: b * 0.85).opacity(0.55),
                // Bottom right - rich accent
                bottomTrailing: Color(red: r * 0.9, green: g * 0.5, blue: b * 0.7).opacity(0.65)
            )
        } else {
            // Light mode: Soft background with MORE VISIBLE accent-tinted clouds
            // Background is a light tint of the accent
            let bgR = 0.94 + r * 0.04
            let bgG = 0.92 + g * 0.04
            let bgB = 0.96 + b * 0.03

            return CloudsTheme(
                // Light pastel background with accent tint
                background: Color(red: min(0.98, bgR), green: min(0.97, bgG), blue: min(0.99, bgB)),
                // Top left - MORE SATURATED accent cloud
                topLeading: Color(red: r * 0.85, green: g * 0.7, blue: b * 0.9).opacity(0.55),
                // Top right - complementary accent
                topTrailing: Color(red: r * 0.7, green: g * 0.8, blue: b * 0.85).opacity(0.45),
                // Bottom left - accent tinted
                bottomLeading: Color(red: r * 0.75, green: g * 0.65, blue: b * 0.85).opacity(0.40),
                // Bottom right - soft accent
                bottomTrailing: Color(red: r * 0.9, green: g * 0.7, blue: b * 0.8).opacity(0.50)
            )
        }
    }
}

// MARK: - Cloud Provider

class CloudProvider: ObservableObject {
    let offset: CGSize
    let frameHeightRatio: CGFloat

    init() {
        frameHeightRatio = CGFloat.random(in: 0.7..<1.4)
        offset = CGSize(
            width: CGFloat.random(in: -150..<150),
            height: CGFloat.random(in: -150..<150)
        )
    }
}

// MARK: - Cloud View

struct Cloud: View {
    @StateObject var provider = CloudProvider()
    let proxy: GeometryProxy
    let color: Color
    let rotationStart: Double
    let duration: Double
    let alignment: Alignment

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let progress = (t.truncatingRemainder(dividingBy: duration)) / duration
            let angle = rotationStart + progress * 360

            Circle()
                .fill(color)
                .frame(height: proxy.size.height / provider.frameHeightRatio)
                .offset(provider.offset)
                .rotationEffect(.degrees(angle))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
                .opacity(0.8)
        }
    }
}

// MARK: - Floating Clouds

struct FloatingClouds: View {
    @Environment(\.colorScheme) var scheme
    @ObservedObject private var themeManager = ThemeManager.shared

    var customTheme: CloudsTheme?
    let blur: CGFloat

    init(theme: CloudsTheme? = nil, blur: CGFloat = 60) {
        self.customTheme = theme
        self.blur = blur
    }

    private var currentTheme: CloudsTheme {
        // If a custom theme is provided, use it
        // Otherwise, generate dynamic theme based on accent color
        customTheme ?? CloudsTheme.dynamicTheme(for: themeManager.accentColor, scheme: scheme)
    }

    var body: some View {
        let t = currentTheme

        GeometryReader { proxy in
            ZStack {
                t.background

                Cloud(
                    proxy: proxy,
                    color: t.bottomTrailing,
                    rotationStart: 0,
                    duration: 60,
                    alignment: .bottomTrailing
                )

                Cloud(
                    proxy: proxy,
                    color: t.topTrailing,
                    rotationStart: 240,
                    duration: 50,
                    alignment: .topTrailing
                )

                Cloud(
                    proxy: proxy,
                    color: t.bottomLeading,
                    rotationStart: 120,
                    duration: 80,
                    alignment: .bottomLeading
                )

                Cloud(
                    proxy: proxy,
                    color: t.topLeading,
                    rotationStart: 180,
                    duration: 70,
                    alignment: .topLeading
                )
            }
            .blur(radius: blur)
            .ignoresSafeArea()
        }
    }
}

#Preview {
    FloatingClouds()
}
