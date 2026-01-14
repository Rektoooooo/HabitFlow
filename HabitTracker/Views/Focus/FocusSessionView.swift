//
//  FocusSessionView.swift
//  HabitTracker
//
//  Created by Claude on 14.01.2026.
//

import SwiftUI
import SwiftData

// MARK: - Focus Session Timer View

struct FocusSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var manager = FocusSessionManager.shared

    @State private var showingCancelAlert = false
    @State private var pulseAnimation = false

    private var habitColor: Color {
        Color(hex: manager.currentHabit?.color ?? "#A855F7")
    }

    var body: some View {
        ZStack {
            // Background
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 40) {
                // Header
                headerSection

                Spacer()

                // Timer Ring
                timerRing

                Spacer()

                // Controls
                controlButtons

                // Bottom info
                bottomInfo
            }
            .padding(24)
        }
        .alert("End Session?", isPresented: $showingCancelAlert) {
            Button("Continue", role: .cancel) {}
            Button("End Session", role: .destructive) {
                manager.cancel()
                dismiss()
            }
        } message: {
            Text("Your progress won't be saved and the habit won't be marked complete.")
        }
        .onChange(of: manager.state) { _, newState in
            if newState == .completed {
                manager.complete(in: modelContext)
            }
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    habitColor.opacity(0.3),
                    colorScheme == .dark ? Color.black : Color.white
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Animated glow when running
            if manager.state == .running {
                Circle()
                    .fill(habitColor.opacity(0.2))
                    .frame(width: 300, height: 300)
                    .blur(radius: 100)
                    .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                    .animation(
                        .easeInOut(duration: 2)
                        .repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )
                    .onAppear { pulseAnimation = true }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            // Habit icon
            ZStack {
                Circle()
                    .fill(habitColor.opacity(0.2))
                    .frame(width: 60, height: 60)

                Image(systemName: manager.currentHabit?.icon ?? "timer")
                    .font(.title2)
                    .foregroundStyle(habitColor)
            }

            // Habit name
            Text(manager.currentHabit?.name ?? "Focus Session")
                .font(.title3.weight(.semibold))
                .foregroundStyle(colorScheme == .dark ? .white : .black)

            // State label
            Text(stateLabel)
                .font(.subheadline)
                .foregroundStyle(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.6))
        }
    }

    private var stateLabel: String {
        switch manager.state {
        case .idle: return "Ready"
        case .running: return "Stay focused..."
        case .paused: return "Paused"
        case .completed: return "Great job!"
        }
    }

    // MARK: - Timer Ring

    private var timerRing: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(habitColor.opacity(0.2), lineWidth: 12)
                .frame(width: 260, height: 260)

            // Progress ring
            Circle()
                .trim(from: 0, to: manager.progress)
                .stroke(
                    habitColor,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 260, height: 260)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: manager.progress)

            // Time display
            VStack(spacing: 8) {
                if manager.state == .completed {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(habitColor)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Text(manager.formattedTime)
                        .font(.system(size: 56, weight: .light, design: .rounded))
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                        .monospacedDigit()
                        .contentTransition(.numericText())

                    Text("remaining")
                        .font(.subheadline)
                        .foregroundStyle(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: manager.state)
        }
    }

    // MARK: - Control Buttons

    private var controlButtons: some View {
        HStack(spacing: 40) {
            // Cancel button
            Button {
                showingCancelAlert = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.15))
                        .frame(width: 64, height: 64)

                    Image(systemName: "xmark")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.red)
                }
            }
            .opacity(manager.state == .completed ? 0 : 1)

            // Play/Pause button
            Button {
                if manager.state == .running {
                    manager.pause()
                } else if manager.state == .paused {
                    manager.resume()
                } else if manager.state == .completed {
                    dismiss()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(habitColor)
                        .frame(width: 80, height: 80)
                        .shadow(color: habitColor.opacity(0.4), radius: 10, x: 0, y: 5)

                    Image(systemName: playPauseIcon)
                        .font(.title.weight(.semibold))
                        .foregroundStyle(.white)
                }
            }
            .scaleEffect(manager.state == .completed ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: manager.state)

            // Skip to complete (hidden placeholder for alignment)
            Circle()
                .fill(Color.clear)
                .frame(width: 64, height: 64)
                .opacity(0)
        }
    }

    private var playPauseIcon: String {
        switch manager.state {
        case .idle: return "play.fill"
        case .running: return "pause.fill"
        case .paused: return "play.fill"
        case .completed: return "checkmark"
        }
    }

    // MARK: - Bottom Info

    private var bottomInfo: some View {
        VStack(spacing: 8) {
            if manager.state != .completed {
                HStack(spacing: 16) {
                    // Elapsed time
                    VStack(spacing: 2) {
                        Text("Elapsed")
                            .font(.caption)
                            .foregroundStyle(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.4))

                        Text(manager.formattedElapsed)
                            .font(.subheadline.weight(.medium).monospacedDigit())
                            .foregroundStyle(colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.7))
                    }

                    Divider()
                        .frame(height: 24)

                    // Total duration
                    VStack(spacing: 2) {
                        Text("Duration")
                            .font(.caption)
                            .foregroundStyle(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.4))

                        Text("\(manager.totalSeconds / 60) min")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.7))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                )
            } else {
                Text("Habit completed!")
                    .font(.headline)
                    .foregroundStyle(habitColor)
            }
        }
    }
}

// MARK: - Focus Setup Sheet

struct FocusSetupSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var manager = FocusSessionManager.shared

    let habit: Habit

    @State private var selectedPreset: FocusDuration? = .standard
    @State private var customMinutes: Double = 25
    @State private var useCustomDuration = false

    private var habitColor: Color {
        Color(hex: habit.color)
    }

    private var effectiveDuration: Int {
        if useCustomDuration {
            return Int(customMinutes) * 60
        } else {
            return selectedPreset?.seconds ?? 1500
        }
    }

    private var primaryText: Color {
        colorScheme == .dark ? .white : Color(red: 0.2, green: 0.15, blue: 0.3)
    }

    private var secondaryText: Color {
        colorScheme == .dark ? .white.opacity(0.7) : Color(red: 0.4, green: 0.35, blue: 0.5)
    }

    var body: some View {
        ZStack {
            // Background with floating clouds
            FloatingClouds(theme: .habitTracker(colorScheme))

            VStack(spacing: 0) {
                // Custom header
                sheetHeader
                    .padding(.top, 16)
                    .padding(.horizontal, 20)

                // Content
                VStack(spacing: 16) {
                    // Habit info card
                    habitHeader

                    // Duration presets
                    durationPresets

                    // Custom duration
                    customDurationSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                Spacer()

                // Start button
                startButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            }
        }
        .presentationDetents([.height(useCustomDuration ? 520 : 420)])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Sheet Header

    private var sheetHeader: some View {
        HStack {
            Text("Focus Session")
                .font(.headline)
                .foregroundStyle(primaryText)
        }
    }

    // MARK: - Habit Header

    private var habitHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(habitColor.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: habit.icon)
                    .font(.title3)
                    .foregroundStyle(habitColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.headline)
                    .foregroundStyle(primaryText)

                Text("Focus session")
                    .font(.caption)
                    .foregroundStyle(secondaryText)
            }

            Spacer()

            // Current duration display
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(effectiveDuration / 60)")
                    .font(.title.weight(.bold))
                    .foregroundStyle(habitColor)
                Text("min")
                    .font(.caption)
                    .foregroundStyle(secondaryText)
            }
        }
        .padding(16)
        .liquidGlass(cornerRadius: 20)
    }

    // MARK: - Duration Presets

    private var durationPresets: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Duration")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(primaryText)

            HStack(spacing: 10) {
                ForEach(FocusDuration.allCases) { duration in
                    DurationPresetButton(
                        duration: duration,
                        isSelected: !useCustomDuration && selectedPreset == duration,
                        habitColor: habitColor,
                        colorScheme: colorScheme
                    ) {
                        selectedPreset = duration
                        useCustomDuration = false
                        HapticManager.shared.buttonPressed()
                    }
                }
            }
        }
    }

    // MARK: - Custom Duration Section

    private var customDurationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.subheadline)
                        .foregroundStyle(habitColor)
                    Text("Custom")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(primaryText)
                }

                Spacer()

                Toggle("", isOn: $useCustomDuration)
                    .tint(habitColor)
                    .labelsHidden()
            }

            if useCustomDuration {
                VStack(spacing: 10) {
                    // Large duration display
                    Text("\(Int(customMinutes)) min")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(habitColor)

                    Slider(value: $customMinutes, in: 5...120, step: 5)
                        .tint(habitColor)

                    HStack {
                        Text("5 min")
                            .font(.caption2)
                            .foregroundStyle(secondaryText)
                        Spacer()
                        Text("2 hours")
                            .font(.caption2)
                            .foregroundStyle(secondaryText)
                    }
                }
            }
        }
        .padding(16)
        .liquidGlass(cornerRadius: 16)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: useCustomDuration)
    }

    // MARK: - Start Button

    private var startButton: some View {
        Button {
            manager.startSession(
                habit: habit,
                duration: effectiveDuration,
                in: modelContext
            )
            dismiss()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                Text("Start \(effectiveDuration / 60) min Session")
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(habitColor)
            )
            .shadow(color: habitColor.opacity(0.4), radius: 8, x: 0, y: 4)
        }
    }
}

// MARK: - Duration Preset Button

struct DurationPresetButton: View {
    let duration: FocusDuration
    let isSelected: Bool
    let habitColor: Color
    let colorScheme: ColorScheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(duration.minutes)")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isSelected ? .white : (colorScheme == .dark ? .white : Color(red: 0.2, green: 0.15, blue: 0.3)))
                Text("min")
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : (colorScheme == .dark ? .white.opacity(0.6) : Color(red: 0.4, green: 0.35, blue: 0.5)))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? habitColor : (colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.7)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.clear : (colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05)), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Duration Option Card

struct DurationOptionCard: View {
    let duration: FocusDuration
    let isSelected: Bool
    let habitColor: Color
    let colorScheme: ColorScheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: duration.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? habitColor : (colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.5)))

                Text(duration.label)
                    .font(.headline)
                    .foregroundStyle(colorScheme == .dark ? .white : .black)

                Text(duration.description)
                    .font(.caption)
                    .foregroundStyle(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected
                          ? habitColor.opacity(0.15)
                          : (colorScheme == .dark ? Color.white.opacity(0.08) : Color.white))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? habitColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Floating Focus Button (Mini Timer)

struct FloatingFocusButton: View {
    @ObservedObject private var manager = FocusSessionManager.shared
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if manager.state != .idle && !manager.isShowingTimer {
            Button {
                manager.isShowingTimer = true
            } label: {
                HStack(spacing: 8) {
                    // Progress ring
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 3)
                            .frame(width: 32, height: 32)

                        Circle()
                            .trim(from: 0, to: manager.progress)
                            .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 32, height: 32)
                            .rotationEffect(.degrees(-90))

                        Image(systemName: manager.state == .paused ? "pause.fill" : "timer")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                    }

                    Text(manager.formattedTime)
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color(hex: manager.currentHabit?.color ?? "#A855F7"))
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                )
            }
        }
    }
}

#Preview {
    FocusSessionView()
        .modelContainer(for: [Habit.self, FocusSession.self], inMemory: true)
}
