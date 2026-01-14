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

    // MARK: - HabitTracker Theme

    static func habitTracker(_ scheme: ColorScheme) -> CloudsTheme {
        if scheme == .dark {
            // Dark mode: Deep purple with magenta/cyan accents (matching light mode aesthetic)
            return CloudsTheme(
                // Deep midnight purple base
                background: Color(red: 0.08, green: 0.06, blue: 0.16),
                // Top left - rich purple/violet
                topLeading: Color(red: 0.50, green: 0.28, blue: 0.72, opacity: 0.70),
                // Top right - soft cyan/blue (mirrors light mode blue)
                topTrailing: Color(red: 0.35, green: 0.55, blue: 0.80, opacity: 0.55),
                // Bottom left - deep lavender/purple
                bottomLeading: Color(red: 0.45, green: 0.35, blue: 0.70, opacity: 0.50),
                // Bottom right - magenta/pink (mirrors light mode pink)
                bottomTrailing: Color(red: 0.65, green: 0.30, blue: 0.65, opacity: 0.60)
            )
        } else {
            // Light mode: Soft lavender/pink/blue
            return CloudsTheme(
                // Light lavender base
                background: Color(red: 0.94, green: 0.92, blue: 0.98),
                // Top left - soft pink
                topLeading: Color(red: 0.85, green: 0.70, blue: 0.90, opacity: 0.70),
                // Top right - light blue
                topTrailing: Color(red: 0.70, green: 0.82, blue: 0.95, opacity: 0.60),
                // Bottom left - soft lavender
                bottomLeading: Color(red: 0.78, green: 0.72, blue: 0.92, opacity: 0.50),
                // Bottom right - light purple/pink
                bottomTrailing: Color(red: 0.88, green: 0.75, blue: 0.92, opacity: 0.55)
            )
        }
    }

    // MARK: - Alternative Themes

    static func purple(_ scheme: ColorScheme) -> CloudsTheme {
        CloudsTheme(
            background: scheme == .dark
                ? Color(red: 0.25, green: 0.00, blue: 0.35)
                : Color(red: 0.96, green: 0.94, blue: 0.99),
            topLeading: scheme == .dark
                ? Color(red: 0.40, green: 0.15, blue: 0.55, opacity: 0.8)
                : Color(red: 0.75, green: 0.55, blue: 0.95, opacity: 0.70),
            topTrailing: scheme == .dark
                ? Color(red: 0.55, green: 0.25, blue: 0.70, opacity: 0.6)
                : Color(red: 0.85, green: 0.65, blue: 1.00, opacity: 0.55),
            bottomLeading: scheme == .dark
                ? Color(red: 0.50, green: 0.20, blue: 0.65, opacity: 0.45)
                : Color(red: 0.70, green: 0.50, blue: 0.90, opacity: 0.50),
            bottomTrailing: scheme == .dark
                ? Color(red: 0.75, green: 0.50, blue: 0.90, opacity: 0.7)
                : Color(red: 0.80, green: 0.60, blue: 0.95, opacity: 0.60)
        )
    }

    static func blue(_ scheme: ColorScheme) -> CloudsTheme {
        CloudsTheme(
            background: scheme == .dark
                ? Color(red: 0.00, green: 0.15, blue: 0.40)
                : Color(red: 0.94, green: 0.97, blue: 1.00),
            topLeading: scheme == .dark
                ? Color(red: 0.00, green: 0.30, blue: 0.60, opacity: 0.8)
                : Color(red: 0.55, green: 0.75, blue: 1.00, opacity: 0.65),
            topTrailing: scheme == .dark
                ? Color(red: 0.10, green: 0.40, blue: 0.75, opacity: 0.6)
                : Color(red: 0.65, green: 0.82, blue: 1.00, opacity: 0.55),
            bottomLeading: scheme == .dark
                ? Color(red: 0.05, green: 0.35, blue: 0.70, opacity: 0.45)
                : Color(red: 0.50, green: 0.70, blue: 0.95, opacity: 0.50),
            bottomTrailing: scheme == .dark
                ? Color(red: 0.40, green: 0.65, blue: 1.00, opacity: 0.7)
                : Color(red: 0.60, green: 0.78, blue: 1.00, opacity: 0.58)
        )
    }

    static func pink(_ scheme: ColorScheme) -> CloudsTheme {
        CloudsTheme(
            background: scheme == .dark
                ? Color(red: 0.40, green: 0.00, blue: 0.30)
                : Color(red: 1.00, green: 0.95, blue: 0.97),
            topLeading: scheme == .dark
                ? Color(red: 0.60, green: 0.05, blue: 0.45, opacity: 0.8)
                : Color(red: 1.00, green: 0.65, blue: 0.80, opacity: 0.65),
            topTrailing: scheme == .dark
                ? Color(red: 0.75, green: 0.10, blue: 0.55, opacity: 0.6)
                : Color(red: 1.00, green: 0.75, blue: 0.88, opacity: 0.55),
            bottomLeading: scheme == .dark
                ? Color(red: 0.70, green: 0.08, blue: 0.50, opacity: 0.45)
                : Color(red: 0.95, green: 0.60, blue: 0.75, opacity: 0.50),
            bottomTrailing: scheme == .dark
                ? Color(red: 1.00, green: 0.40, blue: 0.80, opacity: 0.7)
                : Color(red: 1.00, green: 0.70, blue: 0.85, opacity: 0.58)
        )
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

    var theme: CloudsTheme?
    let blur: CGFloat

    init(theme: CloudsTheme? = nil, blur: CGFloat = 60) {
        self.theme = theme
        self.blur = blur
    }

    var body: some View {
        let t = theme ?? CloudsTheme.habitTracker(scheme)

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
