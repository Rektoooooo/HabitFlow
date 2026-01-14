//
//  WeeklyInsightsView.swift
//  HabitTracker
//
//  Created by Claude on 14.01.2026.
//

import SwiftUI

struct WeeklyInsightsView: View {
    let habit: Habit
    let primaryText: Color
    let secondaryText: Color
    let tertiaryText: Color

    private let daysOfWeek = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    private let daySymbols = ["M", "T", "W", "T", "F", "S", "S"]

    // Calculate completions per day of week
    private var dayStats: [DayStat] {
        let calendar = Calendar.current
        var stats: [Int: (completed: Int, total: Int)] = [:]

        // Initialize all days
        for i in 1...7 {
            stats[i] = (0, 0)
        }

        // Count completions by day of week
        // Look at the last 12 weeks for meaningful data
        let twelveWeeksAgo = calendar.date(byAdding: .weekOfYear, value: -12, to: Date()) ?? Date()

        for completion in habit.completions {
            if completion.date >= twelveWeeksAgo {
                let weekday = calendar.component(.weekday, from: completion.date)
                // Convert Sunday=1...Saturday=7 to Monday=1...Sunday=7
                let adjustedDay = weekday == 1 ? 7 : weekday - 1

                if var stat = stats[adjustedDay] {
                    stat.completed += 1
                    stats[adjustedDay] = stat
                }
            }
        }

        // Calculate total possible days for each day of week in the period
        var currentDate = twelveWeeksAgo
        while currentDate <= Date() {
            let weekday = calendar.component(.weekday, from: currentDate)
            let adjustedDay = weekday == 1 ? 7 : weekday - 1

            // Only count if the habit existed on that day
            if currentDate >= habit.createdAt {
                if var stat = stats[adjustedDay] {
                    stat.total += 1
                    stats[adjustedDay] = stat
                }
            }

            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        // Convert to DayStat array
        return (1...7).map { day in
            let stat = stats[day] ?? (0, 0)
            let percentage = stat.total > 0 ? Double(stat.completed) / Double(stat.total) : 0
            return DayStat(
                dayIndex: day,
                dayName: daysOfWeek[day - 1],
                daySymbol: daySymbols[day - 1],
                completions: stat.completed,
                total: stat.total,
                percentage: percentage
            )
        }
    }

    private var maxPercentage: Double {
        dayStats.map(\.percentage).max() ?? 1.0
    }

    private var bestDay: DayStat? {
        dayStats.filter { $0.total > 0 }.max(by: { $0.percentage < $1.percentage })
    }

    private var worstDay: DayStat? {
        dayStats.filter { $0.total > 0 }.min(by: { $0.percentage < $1.percentage })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Weekly Patterns")
                    .font(.headline)
                    .foregroundStyle(primaryText)

                Spacer()

                Text("Last 12 weeks")
                    .font(.caption)
                    .foregroundStyle(tertiaryText)
            }

            // Bar Chart
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(dayStats, id: \.dayIndex) { stat in
                    DayBarView(
                        stat: stat,
                        maxPercentage: maxPercentage,
                        habitColor: Color(hex: habit.color),
                        isBest: bestDay?.dayIndex == stat.dayIndex,
                        isWorst: worstDay?.dayIndex == stat.dayIndex && bestDay?.dayIndex != stat.dayIndex,
                        primaryText: primaryText,
                        secondaryText: secondaryText,
                        tertiaryText: tertiaryText
                    )
                }
            }
            .frame(height: 140)
            .padding(.top, 8)

            // Insights
            if let best = bestDay, let worst = worstDay, best.dayIndex != worst.dayIndex {
                HStack(spacing: 12) {
                    // Best day
                    HStack(spacing: 8) {
                        Image(systemName: "trophy.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Best day")
                                .font(.caption2)
                                .foregroundStyle(tertiaryText)
                            Text(best.dayName)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(primaryText)
                        }

                        Spacer()

                        Text("\(Int(best.percentage * 100))%")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color(hex: habit.color))
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: habit.color).opacity(0.1))
                    )

                    // Needs work
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Needs work")
                                .font(.caption2)
                                .foregroundStyle(tertiaryText)
                            Text(worst.dayName)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(primaryText)
                        }

                        Spacer()

                        Text("\(Int(worst.percentage * 100))%")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.orange)
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.orange.opacity(0.1))
                    )
                }
            }
        }
        .padding(20)
        .liquidGlass(cornerRadius: 20)
    }
}

// MARK: - Day Stat Model

struct DayStat {
    let dayIndex: Int
    let dayName: String
    let daySymbol: String
    let completions: Int
    let total: Int
    let percentage: Double
}

// MARK: - Day Bar View

struct DayBarView: View {
    let stat: DayStat
    let maxPercentage: Double
    let habitColor: Color
    let isBest: Bool
    let isWorst: Bool
    let primaryText: Color
    let secondaryText: Color
    let tertiaryText: Color

    @Environment(\.colorScheme) private var colorScheme

    private var barHeight: CGFloat {
        guard maxPercentage > 0 else { return 0 }
        return CGFloat(stat.percentage / maxPercentage) * 80
    }

    private var barColor: Color {
        if isBest {
            return habitColor
        } else if isWorst {
            return .orange
        } else {
            return habitColor.opacity(0.6)
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            // Percentage label
            Text("\(Int(stat.percentage * 100))%")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(stat.total > 0 ? secondaryText : tertiaryText)

            // Bar
            VStack {
                Spacer(minLength: 0)

                if stat.total > 0 {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: isBest
                                    ? [habitColor, habitColor.opacity(0.7)]
                                    : isWorst
                                        ? [.orange, .orange.opacity(0.7)]
                                        : [habitColor.opacity(0.7), habitColor.opacity(0.4)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: max(barHeight, 4))
                } else {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                        .frame(height: 4)
                }
            }
            .frame(height: 80)

            // Day label
            Text(stat.daySymbol)
                .font(.system(size: 11, weight: isBest ? .bold : .medium))
                .foregroundStyle(isBest ? habitColor : (isWorst ? .orange : secondaryText))

            // Indicator dot for best/worst
            if isBest {
                Circle()
                    .fill(habitColor)
                    .frame(width: 6, height: 6)
            } else if isWorst {
                Circle()
                    .fill(.orange)
                    .frame(width: 6, height: 6)
            } else {
                Circle()
                    .fill(.clear)
                    .frame(width: 6, height: 6)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.95).ignoresSafeArea()

        WeeklyInsightsView(
            habit: {
                let h = Habit(name: "Exercise", icon: "figure.run", color: "#A855F7")
                return h
            }(),
            primaryText: .white,
            secondaryText: .white.opacity(0.7),
            tertiaryText: .white.opacity(0.5)
        )
        .padding()
    }
}
