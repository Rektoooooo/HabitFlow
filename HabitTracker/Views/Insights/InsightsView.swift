//
//  InsightsView.swift
//  HabitTracker
//
//  Created by Claude on 14.01.2026.
//

import SwiftUI
import SwiftData

struct InsightsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: \Habit.createdAt, order: .reverse) private var habits: [Habit]
    @ObservedObject private var insightsEngine = InsightsEngine.shared

    @State private var insights: [Insight] = []
    @State private var selectedFilter: InsightType? = nil

    private var primaryText: Color {
        colorScheme == .dark ? .white : Color(red: 0.15, green: 0.12, blue: 0.25)
    }

    private var secondaryText: Color {
        colorScheme == .dark ? .white.opacity(0.7) : Color(red: 0.4, green: 0.35, blue: 0.5)
    }

    private var filteredInsights: [Insight] {
        guard let filter = selectedFilter else { return insights }
        return insights.filter { $0.type == filter }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                FloatingClouds(theme: .habitTracker(colorScheme))

                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        headerSection

                        // Filter pills
                        filterSection

                        // Featured insight (first high priority)
                        if let featured = filteredInsights.first(where: { $0.priority >= .high }) {
                            FeaturedInsightCard(insight: featured)
                        }

                        // Rest of insights
                        insightsSection

                        Spacer(minLength: 40)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Color(hex: "#A855F7"))
                }
            }
            .onAppear {
                refreshInsights()
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#3B82F6"), Color(hex: "#8B5CF6")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)

                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text("Your Insights")
                .font(.title3.weight(.bold))
                .foregroundStyle(primaryText)

            Text("Personalized analytics based on your habit patterns and progress.")
                .font(.subheadline)
                .foregroundStyle(secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 10)
    }

    // MARK: - Filter Section

    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // All filter
                FilterPill(
                    title: "All",
                    icon: "sparkles",
                    isSelected: selectedFilter == nil,
                    color: Color(hex: "#A855F7")
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedFilter = nil
                    }
                }

                // Type filters
                ForEach(InsightType.allCases, id: \.rawValue) { type in
                    FilterPill(
                        title: type.rawValue.capitalized,
                        icon: type.icon,
                        isSelected: selectedFilter == type,
                        color: type.color
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedFilter = type
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Insights Section

    private var insightsSection: some View {
        VStack(spacing: 12) {
            let displayedInsights = filteredInsights.filter { insight in
                // Skip the featured one if it was already shown
                if let featured = filteredInsights.first(where: { $0.priority >= .high }) {
                    return insight.id != featured.id
                }
                return true
            }

            if displayedInsights.isEmpty && filteredInsights.isEmpty {
                emptyState
            } else {
                ForEach(displayedInsights) { insight in
                    InsightCardView(insight: insight)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 50))
                .foregroundStyle(secondaryText.opacity(0.5))

            Text("No Insights Yet")
                .font(.headline)
                .foregroundStyle(primaryText)

            Text("Keep tracking your habits to unlock personalized insights about your patterns and progress.")
                .font(.subheadline)
                .foregroundStyle(secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 40)
    }

    // MARK: - Helpers

    private func refreshInsights() {
        insights = insightsEngine.generateInsights(for: habits)
    }
}

// MARK: - Filter Pill

struct FilterPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption.weight(.medium))
            }
            .foregroundStyle(isSelected ? .white : (colorScheme == .dark ? .white.opacity(0.7) : color))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? color : color.opacity(0.15))
            )
        }
    }
}

#Preview {
    InsightsView()
        .modelContainer(for: Habit.self, inMemory: true)
}
