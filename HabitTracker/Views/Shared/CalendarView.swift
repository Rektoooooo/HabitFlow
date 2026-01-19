//
//  CalendarView.swift
//  HabitTracker
//
//  Created by Sebastián Kučera on 12.01.2026.
//

import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    let habit: Habit
    @State private var selectedMonth = Date()

    private let calendar = Calendar.current
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

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

    private var cardBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.1) : Color(red: 0.9, green: 0.88, blue: 0.95)
    }

    var body: some View {
        VStack(spacing: 20) {
            // Month Navigation
            monthNavigation

            // Days of Week Header
            daysOfWeekHeader

            // Calendar Grid
            calendarGrid
        }
    }

    // MARK: - Month Navigation

    private var monthNavigation: some View {
        HStack {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(secondaryText)
                    .frame(width: 44, height: 44)
                    .background(cardBackground)
                    .clipShape(Circle())
            }

            Spacer()

            Text(selectedMonth.formatted(.dateTime.month(.wide).year()))
                .font(.headline)
                .foregroundStyle(primaryText)

            Spacer()

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(calendar.isDate(selectedMonth, equalTo: Date(), toGranularity: .month)
                                     ? tertiaryText
                                     : secondaryText)
                    .frame(width: 44, height: 44)
                    .background(cardBackground)
                    .clipShape(Circle())
            }
            .disabled(calendar.isDate(selectedMonth, equalTo: Date(), toGranularity: .month))
        }
    }

    // MARK: - Days of Week Header

    private var daysOfWeekHeader: some View {
        HStack(spacing: 0) {
            ForEach(daysOfWeek, id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(tertiaryText)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        let days = generateDaysForMonth()
        let completedDates = Set(habit.safeCompletions.map { calendar.startOfDay(for: $0.date) })

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(days, id: \.self) { date in
                if let date = date {
                    let isCompleted = completedDates.contains(calendar.startOfDay(for: date))
                    dayCell(for: date, isCompleted: isCompleted)
                        .onTapGesture {
                            toggleCompletion(for: date, isCurrentlyCompleted: isCompleted)
                        }
                } else {
                    Color.clear
                        .frame(height: 40)
                }
            }
        }
    }

    private func dayCell(for date: Date, isCompleted: Bool) -> some View {
        let isToday = calendar.isDateInToday(date)
        let isFuture = date > Date()
        let day = calendar.component(.day, from: date)

        return ZStack {
            if isCompleted {
                Circle()
                    .fill(Color(hex: habit.color))
            } else if isToday {
                Circle()
                    .stroke(Color(hex: habit.color), lineWidth: 2)
            }

            Text("\(day)")
                .font(.subheadline)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundStyle(
                    isCompleted ? .white :
                    isFuture ? tertiaryText :
                    primaryText
                )
        }
        .frame(height: 40)
        .contentShape(Circle())
        .opacity(isFuture ? 0.5 : 1)
        .allowsHitTesting(!isFuture)
    }

    // MARK: - Toggle Completion

    private func toggleCompletion(for date: Date, isCurrentlyCompleted: Bool) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            let targetDate = calendar.startOfDay(for: date)

            if isCurrentlyCompleted {
                // Remove completion for this date
                if let completion = habit.safeCompletions.first(where: {
                    calendar.isDate($0.date, inSameDayAs: targetDate)
                }) {
                    modelContext.delete(completion)
                }
            } else {
                // Add completion for this date
                let completion = HabitCompletion(date: targetDate, habit: habit)
                modelContext.insert(completion)
            }

            // Update widgets after a short delay to ensure data is saved
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NotificationCenter.default.post(name: .habitsDidChange, object: nil)
            }
        }
    }

    // MARK: - Helper Methods

    private func generateDaysForMonth() -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: selectedMonth),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth)) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(date)
            }
        }

        let remainingCells = (7 - days.count % 7) % 7
        days.append(contentsOf: Array(repeating: nil, count: remainingCells))

        return days
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, configurations: config)

    let habit = Habit(name: "Exercise", icon: "figure.run", color: "#A855F7")
    container.mainContext.insert(habit)

    return CalendarView(habit: habit)
        .modelContainer(container)
        .padding()
}
