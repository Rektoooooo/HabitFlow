//
//  WidgetPromoBanner.swift
//  HabitTracker
//
//  Created by Sebastián Kučera on 19.01.2026.
//

import SwiftUI

struct WidgetPromoBanner: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var themeManager = ThemeManager.shared
    @AppStorage("dismissedWidgetPromo") private var dismissed = false
    @State private var showingInstructions = false

    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Header with dismiss button
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.subheadline)
                        .foregroundStyle(themeManager.primaryGradient)

                    Text("Widgets")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(colorScheme == .dark ? .white : Color(hex: "#1F1535"))
                }

                Spacer()

                Button {
                    dismissed = true
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(colorScheme == .dark ? .white.opacity(0.5) : Color(hex: "#6B5B7A"))
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                        )
                }
                .accessibilityLabel("Dismiss widget promotion")
            }

            // Content
            HStack(spacing: 16) {
                // Widget Preview
                widgetPreview

                // Text content
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add Dotti to your Home Screen")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(colorScheme == .dark ? .white : Color(hex: "#1F1535"))

                    Text("Quick access to track habits without opening the app")
                        .font(.caption)
                        .foregroundStyle(colorScheme == .dark ? .white.opacity(0.7) : Color(hex: "#6B5B7A"))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Button {
                        showingInstructions = true
                    } label: {
                        Text("Learn How")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(themeManager.primaryGradient)
                            .clipShape(Capsule())
                    }
                    .accessibilityHint("Shows instructions for adding widgets")
                }

                Spacer(minLength: 0)
            }
        }
        .padding(16)
        .liquidGlass(cornerRadius: 20)
        .sheet(isPresented: $showingInstructions) {
            WidgetInstructionsSheet()
        }
    }

    // MARK: - Widget Preview

    private var widgetPreview: some View {
        VStack(spacing: 6) {
            // Mini widget representation
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(themeManager.primaryGradient)
                        .frame(width: 8, height: 8)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.3) : Color.black.opacity(0.15))
                        .frame(width: 30, height: 4)

                    Spacer()
                }

                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green.opacity(0.7))
                        .frame(width: 8, height: 8)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.3) : Color.black.opacity(0.15))
                        .frame(width: 24, height: 4)

                    Spacer()
                }

                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.orange.opacity(0.7))
                        .frame(width: 8, height: 8)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.3) : Color.black.opacity(0.15))
                        .frame(width: 20, height: 4)

                    Spacer()
                }
            }
            .padding(10)
            .frame(width: 70, height: 70)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
            )
        }
    }
}

// MARK: - Widget Instructions Sheet

struct WidgetInstructionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                FloatingClouds()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header illustration
                        headerSection

                        // Steps
                        stepsSection

                        // Tip
                        tipSection

                        // Done button
                        Button {
                            dismiss()
                        } label: {
                            Text("Got it!")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(themeManager.primaryGradient)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.top, 8)

                        Spacer(minLength: 40)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Add Widget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(colorScheme == .dark ? .white.opacity(0.5) : Color(hex: "#9B8BA8"))
                    }
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Widget illustration
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(themeManager.primaryColor.opacity(0.15))
                    .frame(width: 120, height: 120)

                Image(systemName: "apps.iphone")
                    .font(.system(size: 50))
                    .foregroundStyle(themeManager.primaryGradient)
            }

            VStack(spacing: 6) {
                Text("Add Dotti Widget")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(colorScheme == .dark ? .white : Color(hex: "#1F1535"))

                Text("Follow these simple steps")
                    .font(.subheadline)
                    .foregroundStyle(colorScheme == .dark ? .white.opacity(0.7) : Color(hex: "#6B5B7A"))
            }
        }
    }

    // MARK: - Steps Section

    private var stepsSection: some View {
        VStack(spacing: 16) {
            InstructionStep(
                number: 1,
                title: "Long press on Home Screen",
                description: "Touch and hold any empty area until the apps start jiggling",
                icon: "hand.tap.fill"
            )

            InstructionStep(
                number: 2,
                title: "Tap the + button",
                description: "Look for the + button in the top-left corner",
                icon: "plus.circle.fill"
            )

            InstructionStep(
                number: 3,
                title: "Search for Dotti",
                description: "Type \"Dotti\" in the search bar to find the widget",
                icon: "magnifyingglass"
            )

            InstructionStep(
                number: 4,
                title: "Choose a size and tap Add",
                description: "Pick small, medium, or large widget and add it",
                icon: "square.grid.2x2.fill"
            )
        }
    }

    // MARK: - Tip Section

    private var tipSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.title3)
                .foregroundStyle(.yellow)

            VStack(alignment: .leading, spacing: 2) {
                Text("Pro Tip")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(colorScheme == .dark ? .white : Color(hex: "#1F1535"))

                Text("You can also add widgets to your Lock Screen for even quicker access!")
                    .font(.caption)
                    .foregroundStyle(colorScheme == .dark ? .white.opacity(0.7) : Color(hex: "#6B5B7A"))
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.yellow.opacity(colorScheme == .dark ? 0.15 : 0.1))
        )
    }
}

// MARK: - Instruction Step

struct InstructionStep: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var themeManager = ThemeManager.shared

    let number: Int
    let title: String
    let description: String
    let icon: String

    var body: some View {
        HStack(spacing: 14) {
            // Number badge
            ZStack {
                Circle()
                    .fill(themeManager.primaryGradient)
                    .frame(width: 36, height: 36)

                Text("\(number)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(themeManager.primaryColor)

                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(colorScheme == .dark ? .white : Color(hex: "#1F1535"))
                }

                Text(description)
                    .font(.caption)
                    .foregroundStyle(colorScheme == .dark ? .white.opacity(0.6) : Color(hex: "#6B5B7A"))
            }

            Spacer()
        }
        .padding(14)
        .liquidGlass(cornerRadius: 14)
    }
}

#Preview {
    VStack {
        WidgetPromoBanner(onDismiss: {})
            .padding()
        Spacer()
    }
    .background(FloatingClouds())
}

#Preview("Instructions") {
    WidgetInstructionsSheet()
}
