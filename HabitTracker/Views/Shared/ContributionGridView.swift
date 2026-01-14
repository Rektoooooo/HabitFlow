//
//  ContributionGridView.swift
//  HabitTracker
//
//  Created by Sebastián Kučera on 12.01.2026.
//

import SwiftUI
import SwiftData

struct ContributionGridView: View {
    @Environment(\.colorScheme) private var colorScheme
    let habit: Habit
    let weeks: Int

    private let calendar = Calendar.current
    private let daysPerWeek = 7
    private let cellSize: CGFloat = 12
    private let cellSpacing: CGFloat = 3

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

    private var emptyCell: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color(red: 0.88, green: 0.86, blue: 0.92)
    }

    init(habit: Habit, weeks: Int = 16) {
        self.habit = habit
        self.weeks = weeks
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Summary stats
            summaryRow

            // Month labels + Grid
            VStack(alignment: .leading, spacing: 6) {
                monthLabelsRow
                gridContent
            }

            // Legend
            legendRow
        }
    }

    // MARK: - Summary Row

    private var summaryRow: some View {
        let completedInRange = gridData.flatMap { $0.days }.filter { $0.isCompleted && $0.date <= Date() }.count
        let totalDays = gridData.flatMap { $0.days }.filter { $0.date <= Date() }.count

        return HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(completedInRange)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: habit.color))
                Text("completions")
                    .font(.caption)
                    .foregroundStyle(secondaryText)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("Last \(weeks) weeks")
                    .font(.caption)
                    .foregroundStyle(secondaryText)
                if totalDays > 0 {
                    Text("\(Int(Double(completedInRange) / Double(totalDays) * 100))% rate")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(tertiaryText)
                }
            }
        }
        .padding(.bottom, 4)
    }

    // MARK: - Month Labels

    private var monthLabelsRow: some View {
        let months = getMonthLabels()
        let columnWidth = cellSize + cellSpacing

        return HStack(spacing: 0) {
            // Spacer for day labels column
            Color.clear.frame(width: 20)

            ForEach(Array(months.enumerated()), id: \.offset) { index, month in
                Text(month.name)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(tertiaryText)
                    .frame(width: CGFloat(month.weeks) * columnWidth, alignment: .leading)
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - Grid Content

    private var gridContent: some View {
        HStack(alignment: .top, spacing: 4) {
            // Day labels (Mon, Wed, Fri)
            VStack(spacing: cellSpacing) {
                ForEach(0..<7, id: \.self) { index in
                    Text(dayLabel(for: index))
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(tertiaryText)
                        .frame(width: 16, height: cellSize)
                }
            }

            // Grid cells
            ScrollView(.horizontal, showsIndicators: false) {
                ScrollViewReader { proxy in
                    HStack(spacing: cellSpacing) {
                        ForEach(gridData) { week in
                            VStack(spacing: cellSpacing) {
                                ForEach(week.days) { day in
                                    gridCell(for: day)
                                        .id(day.date)
                                }
                            }
                            .id(week.weekIndex)
                        }
                    }
                    .onAppear {
                        // Scroll to end (most recent)
                        if let lastWeek = gridData.last {
                            proxy.scrollTo(lastWeek.weekIndex, anchor: .trailing)
                        }
                    }
                }
            }
        }
    }

    private func dayLabel(for index: Int) -> String {
        switch index {
        case 0: return "M"
        case 2: return "W"
        case 4: return "F"
        case 6: return "S"
        default: return ""
        }
    }

    // MARK: - Grid Cell

    private func gridCell(for day: DayData) -> some View {
        let isFuture = day.date > Date()
        let isToday = calendar.isDateInToday(day.date)

        return RoundedRectangle(cornerRadius: 3)
            .fill(cellColor(for: day))
            .frame(width: cellSize, height: cellSize)
            .overlay(
                Group {
                    if isToday {
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color(hex: habit.color), lineWidth: 1.5)
                    }
                }
            )
            .opacity(isFuture ? 0.3 : 1.0)
    }

    private func cellColor(for day: DayData) -> Color {
        guard day.date <= Date() else {
            return emptyCell
        }

        if day.isCompleted {
            return Color(hex: habit.color)
        } else {
            return emptyCell
        }
    }

    // MARK: - Legend

    private var legendRow: some View {
        HStack(spacing: 6) {
            Spacer()

            Text("Less")
                .font(.system(size: 10))
                .foregroundStyle(tertiaryText)

            HStack(spacing: 2) {
                ForEach([0.0, 0.25, 0.5, 0.75, 1.0], id: \.self) { opacity in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(opacity == 0 ? emptyCell : Color(hex: habit.color).opacity(opacity))
                        .frame(width: 10, height: 10)
                }
            }

            Text("More")
                .font(.system(size: 10))
                .foregroundStyle(tertiaryText)
        }
        .padding(.top, 8)
    }

    // MARK: - Data Generation

    private var gridData: [WeekData] {
        var weeksData: [WeekData] = []
        let today = calendar.startOfDay(for: Date())

        // Start from X weeks ago, aligned to Monday
        guard let startDate = calendar.date(byAdding: .weekOfYear, value: -(weeks - 1), to: today) else {
            return []
        }

        // Find the Monday of that week (weekday: 1 = Sunday in US, 2 = Monday)
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: startDate)
        components.weekday = 2 // Monday
        guard let weekStart = calendar.date(from: components) else {
            return []
        }

        let completedDates = Set(habit.completions.map { calendar.startOfDay(for: $0.date) })

        for weekIndex in 0..<weeks {
            guard let currentWeekStart = calendar.date(byAdding: .weekOfYear, value: weekIndex, to: weekStart) else {
                continue
            }

            var days: [DayData] = []
            for dayOffset in 0..<daysPerWeek {
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: currentWeekStart) else {
                    continue
                }

                let isCompleted = completedDates.contains(calendar.startOfDay(for: date))
                days.append(DayData(date: date, isCompleted: isCompleted))
            }

            weeksData.append(WeekData(weekIndex: weekIndex, days: days))
        }

        return weeksData
    }

    private func getMonthLabels() -> [(name: String, weeks: Int, offset: Int)] {
        var months: [(name: String, weeks: Int, offset: Int)] = []
        let today = calendar.startOfDay(for: Date())

        guard let startDate = calendar.date(byAdding: .weekOfYear, value: -(weeks - 1), to: today) else {
            return []
        }

        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: startDate)
        components.weekday = 2
        guard let weekStart = calendar.date(from: components) else {
            return []
        }

        var currentMonth = -1
        var monthWeekCount = 0
        var monthStartOffset = 0

        for weekIndex in 0..<weeks {
            guard let date = calendar.date(byAdding: .weekOfYear, value: weekIndex, to: weekStart) else {
                continue
            }

            let month = calendar.component(.month, from: date)

            if month != currentMonth {
                if currentMonth != -1 && monthWeekCount >= 2 {
                    // Only show month label if it spans at least 2 weeks
                    let monthName = calendar.shortMonthSymbols[currentMonth - 1]
                    months.append((name: monthName, weeks: monthWeekCount, offset: monthStartOffset))
                } else if currentMonth != -1 && monthWeekCount == 1 && !months.isEmpty {
                    // Add single week to previous month's width
                    months[months.count - 1].weeks += 1
                }
                currentMonth = month
                monthWeekCount = 1
                monthStartOffset = weekIndex
            } else {
                monthWeekCount += 1
            }
        }

        // Add the last month
        if currentMonth != -1 && monthWeekCount >= 1 {
            let monthName = calendar.shortMonthSymbols[currentMonth - 1]
            months.append((name: monthName, weeks: monthWeekCount, offset: monthStartOffset))
        }

        return months
    }
}

// MARK: - Data Models

struct WeekData: Identifiable {
    let weekIndex: Int
    let days: [DayData]

    var id: Int { weekIndex }
}

struct DayData: Identifiable {
    let date: Date
    let isCompleted: Bool

    var id: Date { date }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, configurations: config)

    let habit = Habit(name: "Exercise", icon: "figure.run", color: "#A855F7")
    container.mainContext.insert(habit)

    return ContributionGridView(habit: habit)
        .modelContainer(container)
        .padding()
}
