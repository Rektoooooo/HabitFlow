//
//  WidgetTheme.swift
//  HabitFlowWidget
//
//  Created by Sebastián Kučera on 12.01.2026.
//

import SwiftUI

// MARK: - Theme Colors

struct WidgetTheme {
    let colorScheme: ColorScheme

    var primaryPurple: Color { Color(hex: "#A855F7") }
    var primaryPink: Color { Color(hex: "#EC4899") }
    var successGreen: Color { Color(hex: "#10B981") }

    var primaryText: Color {
        colorScheme == .dark ? .white : Color(hex: "#1F1535")
    }

    var secondaryText: Color {
        colorScheme == .dark ? .white.opacity(0.6) : Color(hex: "#6B5B7A")
    }

    var cardBackground: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.08)
            : Color.white.opacity(0.7)
    }

    var cardBorder: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.1)
            : Color(hex: "#A855F7").opacity(0.15)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Widget Background

struct WidgetBackground: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        if colorScheme == .dark {
            LinearGradient(
                colors: [
                    Color(hex: "#1a1625"),
                    Color(hex: "#140f1f")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay(
                RadialGradient(
                    colors: [
                        Color(hex: "#A855F7").opacity(0.15),
                        Color.clear
                    ],
                    center: .topTrailing,
                    startRadius: 0,
                    endRadius: 200
                )
            )
            .overlay(
                RadialGradient(
                    colors: [
                        Color(hex: "#EC4899").opacity(0.1),
                        Color.clear
                    ],
                    center: .bottomLeading,
                    startRadius: 0,
                    endRadius: 150
                )
            )
        } else {
            LinearGradient(
                colors: [
                    Color(hex: "#FAF8FC"),
                    Color(hex: "#F3EEF8")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay(
                RadialGradient(
                    colors: [
                        Color(hex: "#A855F7").opacity(0.08),
                        Color.clear
                    ],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 150
                )
            )
            .overlay(
                RadialGradient(
                    colors: [
                        Color(hex: "#EC4899").opacity(0.06),
                        Color.clear
                    ],
                    center: .bottomTrailing,
                    startRadius: 0,
                    endRadius: 120
                )
            )
        }
    }
}
