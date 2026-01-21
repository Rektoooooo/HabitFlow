//
//  ThemeManager.swift
//  HabitTracker
//
//  Created by Sebastián Kučera on 19.01.2026.
//

import SwiftUI
import Combine

// MARK: - Accent Color

enum AccentColor: String, CaseIterable, Identifiable {
    case purple = "purple"
    case pink = "pink"
    case blue = "blue"
    case green = "green"
    case orange = "orange"
    case red = "red"
    case cyan = "cyan"
    case indigo = "indigo"

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var color: Color {
        switch self {
        case .purple: return Color(hex: "#A855F7")
        case .pink: return Color(hex: "#EC4899")
        case .blue: return Color(hex: "#3B82F6")
        case .green: return Color(hex: "#10B981")
        case .orange: return Color(hex: "#F59E0B")
        case .red: return Color(hex: "#EF4444")
        case .cyan: return Color(hex: "#06B6D4")
        case .indigo: return Color(hex: "#6366F1")
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .purple:
            return LinearGradient(
                colors: [Color(hex: "#A855F7"), Color(hex: "#EC4899")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .pink:
            return LinearGradient(
                colors: [Color(hex: "#EC4899"), Color(hex: "#F472B6")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .blue:
            return LinearGradient(
                colors: [Color(hex: "#3B82F6"), Color(hex: "#60A5FA")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .green:
            return LinearGradient(
                colors: [Color(hex: "#10B981"), Color(hex: "#34D399")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .orange:
            return LinearGradient(
                colors: [Color(hex: "#F59E0B"), Color(hex: "#FBBF24")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .red:
            return LinearGradient(
                colors: [Color(hex: "#EF4444"), Color(hex: "#F87171")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .cyan:
            return LinearGradient(
                colors: [Color(hex: "#06B6D4"), Color(hex: "#22D3EE")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .indigo:
            return LinearGradient(
                colors: [Color(hex: "#6366F1"), Color(hex: "#818CF8")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    /// Secondary color for gradients
    var secondaryColor: Color {
        switch self {
        case .purple: return Color(hex: "#EC4899")
        case .pink: return Color(hex: "#F472B6")
        case .blue: return Color(hex: "#60A5FA")
        case .green: return Color(hex: "#34D399")
        case .orange: return Color(hex: "#FBBF24")
        case .red: return Color(hex: "#F87171")
        case .cyan: return Color(hex: "#22D3EE")
        case .indigo: return Color(hex: "#818CF8")
        }
    }

    /// RGB components (0-1 range) for dynamic color generation
    var rgbComponents: (r: Double, g: Double, b: Double) {
        switch self {
        case .purple: return (0.66, 0.33, 0.97)  // #A855F7
        case .pink: return (0.93, 0.29, 0.60)    // #EC4899
        case .blue: return (0.23, 0.51, 0.96)    // #3B82F6
        case .green: return (0.06, 0.73, 0.51)   // #10B981
        case .orange: return (0.96, 0.62, 0.04)  // #F59E0B
        case .red: return (0.94, 0.27, 0.27)     // #EF4444
        case .cyan: return (0.02, 0.71, 0.83)    // #06B6D4
        case .indigo: return (0.39, 0.40, 0.95)  // #6366F1
        }
    }
}

// MARK: - Time of Day (for dynamic header)

enum TimeOfDay: String, CaseIterable {
    case morning    // 5am - 12pm
    case afternoon  // 12pm - 5pm
    case evening    // 5pm - 9pm
    case night      // 9pm - 5am

    static var current: TimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return .morning
        case 12..<17: return .afternoon
        case 17..<21: return .evening
        default: return .night
        }
    }

    var headerImageName: String {
        switch self {
        case .morning: return "HeaderMorning"
        case .afternoon: return "HeaderAfternoon"
        case .evening: return "HeaderEvening"
        case .night: return "HeaderNight"
        }
    }

    var displayName: String {
        switch self {
        case .morning: return "Morning"
        case .afternoon: return "Afternoon"
        case .evening: return "Evening"
        case .night: return "Night"
        }
    }
}

// MARK: - Appearance Mode

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Theme Manager

@MainActor
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @AppStorage("selectedAccentColor") private var accentColorRaw: String = AccentColor.purple.rawValue
    @AppStorage("selectedAppearanceMode") private var appearanceModeRaw: String = AppearanceMode.system.rawValue
    @AppStorage("dynamicHeaderEnabled") var dynamicHeaderEnabled: Bool = false

    @Published var accentColor: AccentColor = .purple
    @Published var appearanceMode: AppearanceMode = .system

    private init() {
        // Load saved values
        if let accent = AccentColor(rawValue: accentColorRaw) {
            accentColor = accent
        }
        if let mode = AppearanceMode(rawValue: appearanceModeRaw) {
            appearanceMode = mode
        }
    }

    // MARK: - Public Methods

    func setAccentColor(_ color: AccentColor) {
        accentColor = color
        accentColorRaw = color.rawValue
        HapticManager.shared.buttonPressed()
    }

    func setAppearanceMode(_ mode: AppearanceMode) {
        appearanceMode = mode
        appearanceModeRaw = mode.rawValue
        HapticManager.shared.buttonPressed()
    }

    func setDynamicHeader(_ enabled: Bool) {
        dynamicHeaderEnabled = enabled
        HapticManager.shared.buttonPressed()
    }

    // MARK: - Computed Properties

    /// Current time-based header image name (only used when dynamicHeaderEnabled is true)
    var currentHeaderImage: String {
        TimeOfDay.current.headerImageName
    }

    var primaryColor: Color {
        accentColor.color
    }

    var primaryGradient: LinearGradient {
        accentColor.gradient
    }

    var secondaryColor: Color {
        accentColor.secondaryColor
    }

    /// Button gradient using the selected accent color
    var buttonGradient: LinearGradient {
        accentColor.gradient
    }
}

// MARK: - Environment Key

private struct ThemeManagerKey: EnvironmentKey {
    static let defaultValue = ThemeManager.shared
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
}

// MARK: - View Extension for Accent Color

extension View {
    func accentColorOverride() -> some View {
        self.tint(ThemeManager.shared.primaryColor)
    }
}
