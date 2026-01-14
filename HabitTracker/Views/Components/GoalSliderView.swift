//
//  GoalSliderView.swift
//  HabitTracker
//
//  Created by Sebastián Kučera on 13.01.2026.
//

import SwiftUI

struct GoalSliderView: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String
    let color: Color

    @State private var isDragging = false

    init(
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double = 1,
        unit: String,
        color: Color = AppTheme.Colors.accentPrimary
    ) {
        self._value = value
        self.range = range
        self.step = step
        self.unit = unit
        self.color = color
    }

    private var progress: CGFloat {
        let normalized = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        return CGFloat(max(0, min(1, normalized)))
    }

    var body: some View {
        VStack(spacing: 20) {
            // Value display
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(formattedValue)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .contentTransition(.numericText())

                Text(unit)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }

            // Custom slider track
            GeometryReader { geometry in
                let width = geometry.size.width
                let thumbSize: CGFloat = 28

                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)

                    // Filled track with gradient
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.8), color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(thumbSize, progress * width), height: 8)

                    // Glow effect
                    Capsule()
                        .fill(color.opacity(0.4))
                        .frame(width: max(thumbSize, progress * width), height: 16)
                        .blur(radius: 8)

                    // Thumb
                    Circle()
                        .fill(.white)
                        .frame(width: thumbSize, height: thumbSize)
                        .shadow(color: color.opacity(0.5), radius: isDragging ? 12 : 6)
                        .scaleEffect(isDragging ? 1.1 : 1.0)
                        .offset(x: max(0, min(width - thumbSize, progress * width - thumbSize / 2)))
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { gesture in
                                    isDragging = true
                                    let newProgress = gesture.location.x / width
                                    let clampedProgress = max(0, min(1, newProgress))
                                    let rawValue = range.lowerBound + (range.upperBound - range.lowerBound) * Double(clampedProgress)
                                    let steppedValue = round(rawValue / step) * step
                                    value = max(range.lowerBound, min(range.upperBound, steppedValue))
                                }
                                .onEnded { _ in
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        isDragging = false
                                    }
                                    // Haptic feedback
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                        )
                }
                .frame(height: thumbSize)
            }
            .frame(height: 28)

            // Range labels
            HStack {
                Text(formatValueForUnit(range.lowerBound))
                    .font(.caption)
                    .foregroundStyle(AppTheme.Colors.textTertiary)

                Spacer()

                Text(formatValueForUnit(range.upperBound))
                    .font(.caption)
                    .foregroundStyle(AppTheme.Colors.textTertiary)
            }
        }
        .padding(20)
        .frostedCard(cornerRadius: 20)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: value)
    }

    private var formattedValue: String {
        formatValueForUnit(value)
    }

    private func formatValueForUnit(_ val: Double) -> String {
        switch unit {
        case "hours":
            let hours = Int(val)
            let minutes = Int((val - Double(hours)) * 60)
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            }
            return "\(hours)"
        case "ml":
            if val >= 1000 {
                return String(format: "%.1f", val / 1000)
            }
            return "\(Int(val))"
        case "kcal":
            return "\(Int(val))"
        default:
            if val == floor(val) {
                return "\(Int(val))"
            }
            return String(format: "%.1f", val)
        }
    }
}

// MARK: - Preset Goal Buttons

struct GoalPresetButtons: View {
    @Binding var value: Double
    let presets: [Double]
    let unit: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            ForEach(presets, id: \.self) { preset in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        value = preset
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Text(formatPreset(preset))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(value == preset ? .white : AppTheme.Colors.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(value == preset ? color : Color.white.opacity(0.1))
                        )
                }
            }
        }
    }

    private func formatPreset(_ val: Double) -> String {
        switch unit {
        case "hours":
            return "\(Int(val))h"
        case "ml":
            if val >= 1000 {
                return String(format: "%.1fL", val / 1000)
            }
            return "\(Int(val))ml"
        case "kcal":
            return "\(Int(val))"
        default:
            return "\(Int(val))"
        }
    }
}

#Preview {
    ZStack {
        AppTheme.Colors.background
            .ignoresSafeArea()

        VStack(spacing: 24) {
            GoalSliderView(
                value: .constant(2000),
                range: 500...4000,
                step: 100,
                unit: "ml",
                color: .cyan
            )

            GoalPresetButtons(
                value: .constant(2000),
                presets: [1500, 2000, 2500, 3000],
                unit: "ml",
                color: .cyan
            )
        }
        .padding()
    }
}
