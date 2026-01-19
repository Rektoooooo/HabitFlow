//
//  HealthKitPermissionView.swift
//  HabitTracker
//
//  Created by Sebastián Kučera on 13.01.2026.
//

import SwiftUI

struct HealthKitPermissionView: View {
    let habitType: HabitType
    let onAuthorized: () -> Void
    let onSkip: () -> Void

    @ObservedObject private var healthKitManager = HealthKitManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var isRequesting = false
    @State private var error: String?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // Adaptive colors
    private var primaryText: Color {
        colorScheme == .dark ? .white : Color(red: 0.2, green: 0.15, blue: 0.3)
    }

    private var secondaryText: Color {
        colorScheme == .dark ? .white.opacity(0.7) : Color(red: 0.4, green: 0.35, blue: 0.5)
    }

    private var tertiaryText: Color {
        colorScheme == .dark ? .white.opacity(0.5) : Color(red: 0.5, green: 0.45, blue: 0.6)
    }

    private var accentColor: Color {
        themeManager.primaryColor
    }

    private var accentGradient: LinearGradient {
        themeManager.primaryGradient
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Floating clouds background
                FloatingClouds()

                VStack(spacing: 32) {
                    Spacer()

                    // Icon
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.2))
                            .frame(width: 120, height: 120)

                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(accentGradient)
                    }

                    // Text
                    VStack(spacing: 12) {
                        Text("Connect Apple Health")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(primaryText)

                        Text("Allow Dotti to read your \(dataTypeDescription) data to automatically track your progress.")
                            .font(.subheadline)
                            .foregroundStyle(secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }

                    // Permissions list
                    VStack(alignment: .leading, spacing: 16) {
                        PermissionRow(icon: "lock.shield.fill", title: "Your data stays private", color: .green, primaryText: primaryText)
                        PermissionRow(icon: "arrow.down.circle.fill", title: "Read-only access", color: .blue, primaryText: primaryText)
                        PermissionRow(icon: "gear", title: "Change anytime in Settings", color: .gray, primaryText: primaryText)
                    }
                    .padding(.vertical, 20)

                    Spacer()

                    // Error message
                    if let error = error {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }

                    // Buttons
                    VStack(spacing: 16) {
                        // Authorize Button
                        Button {
                            requestAuthorization()
                        } label: {
                            if isRequesting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Connect Health")
                            }
                        }
                        .primaryButtonStyle()
                        .disabled(isRequesting)

                        // Skip Button
                        Button {
                            onSkip()
                        } label: {
                            Text("Enter Manually Instead")
                                .font(.subheadline)
                                .foregroundStyle(secondaryText)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Apple Health")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(tertiaryText)
                    }
                }
            }
        }
    }

    private var dataTypeDescription: String {
        switch habitType {
        case .healthKitSleep:
            return "sleep"
        case .healthKitWater:
            return "water intake"
        case .healthKitCalories:
            return "calorie"
        case .manual:
            return "health"
        }
    }

    private func requestAuthorization() {
        isRequesting = true
        error = nil

        Task { @MainActor in
            do {
                try await healthKitManager.requestAuthorization()
                isRequesting = false
                onAuthorized()
            } catch {
                self.error = error.localizedDescription
                isRequesting = false
            }
        }
    }
}

// MARK: - Permission Row

struct PermissionRow: View {
    let icon: String
    let title: String
    let color: Color
    let primaryText: Color

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(color)
            }

            Text(title)
                .font(.subheadline)
                .foregroundStyle(primaryText)

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

#Preview {
    HealthKitPermissionView(
        habitType: .healthKitSleep,
        onAuthorized: {},
        onSkip: {}
    )
}
