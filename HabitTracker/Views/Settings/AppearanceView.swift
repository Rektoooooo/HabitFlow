//
//  AppearanceView.swift
//  HabitTracker
//
//  Created by Sebastián Kučera on 19.01.2026.
//

import SwiftUI

struct AppearanceView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var storeManager = StoreManager.shared

    @State private var selectedAccent: AccentColor
    @State private var selectedMode: AppearanceMode
    @State private var showingPaywall = false

    private var primaryText: Color {
        colorScheme == .dark ? .white : Color(hex: "#1F1535")
    }

    private var secondaryText: Color {
        colorScheme == .dark ? .white.opacity(0.7) : Color(hex: "#6B5B7A")
    }

    private var tertiaryText: Color {
        colorScheme == .dark ? .white.opacity(0.5) : Color(hex: "#9B8BA8")
    }

    init() {
        _selectedAccent = State(initialValue: ThemeManager.shared.accentColor)
        _selectedMode = State(initialValue: ThemeManager.shared.appearanceMode)
    }

    var body: some View {
        ZStack {
            // Background
            FloatingClouds()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header with mascot
                    headerSection

                    // Preview Section
                    previewSection

                    // Appearance Mode
                    appearanceModeSection

                    // Accent Color
                    accentColorSection

                    // Dynamic Header
                    dynamicHeaderSection

                    // Premium badge if not premium
                    if !storeManager.isPremium {
                        premiumBadge
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .onChange(of: selectedAccent) { _, newValue in
            if storeManager.isPremium {
                themeManager.setAccentColor(newValue)
            }
        }
        .onChange(of: selectedMode) { _, newValue in
            // Appearance mode is FREE for all users
            themeManager.setAppearanceMode(newValue)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Mascot
            Image("ProfileMascot")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)

            VStack(spacing: 6) {
                Text("App Appearance")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(primaryText)

                Text("Customize your Habit Owl experience")
                    .font(.subheadline)
                    .foregroundStyle(secondaryText)
            }
        }
        .padding(.top, 20)
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview")
                .font(.headline)
                .foregroundStyle(primaryText)

            VStack(spacing: 16) {
                // Primary Button Preview
                Button {} label: {
                    Text("Complete Habit")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(selectedAccent.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(true)

                // Progress Bar Preview
                HStack {
                    Text("Daily Progress")
                        .font(.subheadline)
                        .foregroundStyle(primaryText)

                    Spacer()

                    Text("75%")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(selectedAccent.color)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(selectedAccent.gradient)
                            .frame(width: geo.size.width * 0.75, height: 8)
                    }
                }
                .frame(height: 8)

                // Badge Chips Preview
                HStack(spacing: 10) {
                    PreviewChip(icon: "flame.fill", text: "7 day streak", color: selectedAccent.color, colorScheme: colorScheme)
                    PreviewChip(icon: "star.fill", text: "All Done", color: selectedAccent.color, colorScheme: colorScheme)
                    Spacer()
                }
            }
            .padding(20)
            .liquidGlass(cornerRadius: 20)
        }
    }

    // MARK: - Appearance Mode Section

    private var appearanceModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Appearance Mode")
                .font(.headline)
                .foregroundStyle(primaryText)

            HStack(spacing: 12) {
                ForEach(AppearanceMode.allCases) { mode in
                    AppearanceModeButton(
                        mode: mode,
                        isSelected: selectedMode == mode,
                        accentColor: selectedAccent.color,
                        colorScheme: colorScheme
                    ) {
                        // Appearance mode is FREE for all users
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedMode = mode
                        }
                    }
                }
            }

            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.caption)
                Text("System follows your device's appearance settings")
                    .font(.caption)
            }
            .foregroundStyle(tertiaryText)
            .padding(.top, 4)
        }
    }

    // MARK: - Accent Color Section

    private var accentColorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Accent Color")
                .font(.headline)
                .foregroundStyle(primaryText)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(AccentColor.allCases) { color in
                    AccentColorButton(
                        color: color,
                        isSelected: selectedAccent == color,
                        isPremium: storeManager.isPremium
                    ) {
                        if storeManager.isPremium {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedAccent = color
                            }
                        } else {
                            showingPaywall = true
                        }
                    }
                }
            }

            HStack(spacing: 6) {
                Image(systemName: "paintbrush.fill")
                    .font(.caption)
                Text("Choose a color that matches your style")
                    .font(.caption)
            }
            .foregroundStyle(tertiaryText)
            .padding(.top, 4)
        }
    }

    // MARK: - Dynamic Header Section

    private var dynamicHeaderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Dynamic Header")
                    .font(.headline)
                    .foregroundStyle(primaryText)

                if !storeManager.isPremium {
                    Text("PRO")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(selectedAccent.gradient)
                        )
                }
            }

            VStack(spacing: 16) {
                // Toggle
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Time-based Background")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(primaryText)

                        Text("Header changes with time of day")
                            .font(.caption)
                            .foregroundStyle(secondaryText)
                    }

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { themeManager.dynamicHeaderEnabled },
                        set: { newValue in
                            if storeManager.isPremium {
                                themeManager.setDynamicHeader(newValue)
                            } else {
                                showingPaywall = true
                            }
                        }
                    ))
                    .tint(selectedAccent.color)
                    .disabled(!storeManager.isPremium)
                }

                // Time states preview
                if themeManager.dynamicHeaderEnabled || storeManager.isPremium {
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            TimeStatePreview(
                                imageName: "HeaderMorning",
                                label: "Morning",
                                time: "5am-12pm",
                                isActive: TimeOfDay.current == .morning && themeManager.dynamicHeaderEnabled,
                                accentColor: selectedAccent.color
                            )
                            TimeStatePreview(
                                imageName: "HeaderAfternoon",
                                label: "Afternoon",
                                time: "12pm-5pm",
                                isActive: TimeOfDay.current == .afternoon && themeManager.dynamicHeaderEnabled,
                                accentColor: selectedAccent.color
                            )
                        }
                        HStack(spacing: 8) {
                            TimeStatePreview(
                                imageName: "HeaderEvening",
                                label: "Evening",
                                time: "5pm-9pm",
                                isActive: TimeOfDay.current == .evening && themeManager.dynamicHeaderEnabled,
                                accentColor: selectedAccent.color
                            )
                            TimeStatePreview(
                                imageName: "HeaderNight",
                                label: "Night",
                                time: "9pm-5am",
                                isActive: TimeOfDay.current == .night && themeManager.dynamicHeaderEnabled,
                                accentColor: selectedAccent.color
                            )
                        }
                    }
                }
            }
            .padding(16)
            .liquidGlass(cornerRadius: 20)

            HStack(spacing: 6) {
                Image(systemName: "sun.horizon.fill")
                    .font(.caption)
                Text("Background adapts from sunrise to night")
                    .font(.caption)
            }
            .foregroundStyle(tertiaryText)
            .padding(.top, 4)
        }
    }

    // MARK: - Premium Badge

    private var premiumBadge: some View {
        Button {
            showingPaywall = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.title3)
                    .foregroundStyle(.yellow)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Unlock Customization")
                        .font(.headline)
                        .foregroundStyle(primaryText)

                    Text("Get Premium to personalize your app")
                        .font(.caption)
                        .foregroundStyle(secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(tertiaryText)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(selectedAccent.color.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(selectedAccent.color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .accessibilityLabel("Unlock Customization")
        .accessibilityHint("Double tap to view premium options")
    }
}

// MARK: - Preview Chip

struct PreviewChip: View {
    let icon: String
    let text: String
    let color: Color
    let colorScheme: ColorScheme

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption2.weight(.medium))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
        )
    }
}

// MARK: - Appearance Mode Button

struct AppearanceModeButton: View {
    let mode: AppearanceMode
    let isSelected: Bool
    let accentColor: Color
    let colorScheme: ColorScheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? accentColor : (colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05)))
                        .frame(width: 56, height: 56)

                    Image(systemName: mode.icon)
                        .font(.title2)
                        .foregroundStyle(isSelected ? .white : (colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.5)))
                }

                Text(mode.displayName)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isSelected ? accentColor : (colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.6)))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.7))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(mode.displayName) mode")
        .accessibilityHint(isSelected ? "Currently selected" : "Double tap to select")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Accent Color Button

struct AccentColorButton: View {
    let color: AccentColor
    let isSelected: Bool
    let isPremium: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color.gradient)
                    .frame(width: 60, height: 60)
                    .shadow(color: color.color.opacity(0.4), radius: isSelected ? 8 : 0, x: 0, y: 4)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                }

                if !isPremium && color != .purple {
                    Circle()
                        .fill(Color.black.opacity(0.4))
                        .frame(width: 60, height: 60)

                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.white)
                }
            }
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(color.displayName) color")
        .accessibilityHint(isSelected ? "Currently selected" : "Double tap to select")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Time State Preview

struct TimeStatePreview: View {
    let imageName: String
    let label: String
    let time: String
    let isActive: Bool
    let accentColor: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isActive ? accentColor : Color.clear, lineWidth: 2)
                )

            VStack(spacing: 2) {
                Text(label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isActive ? accentColor : .primary)

                Text(time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isActive ? accentColor.opacity(0.1) : Color.clear)
        )
    }
}

#Preview {
    NavigationStack {
        AppearanceView()
    }
}
