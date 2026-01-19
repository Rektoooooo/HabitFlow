//
//  ContentView.swift
//  HabitFlowWatch Watch App
//
//  Created by Sebastián Kučera on 14.01.2026.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataManager: WatchDataManager
    @EnvironmentObject var connectivityManager: WatchConnectivityManagerWatch

    // App theme colors
    private let primaryPurple = Color(hex: "#A855F7")
    private let primaryPink = Color(hex: "#EC4899")

    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [
                        Color(hex: "#1a1a2e"),
                        Color(hex: "#16213e"),
                        Color(hex: "#0f0f23")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {
                        // Check premium status
                        if !dataManager.isPremium {
                            premiumRequiredState
                        } else {
                            // Progress Header
                            ProgressHeaderView(
                                completed: dataManager.completedCount,
                                total: dataManager.totalCount
                            )
                            .padding(.top, 4)

                            // Habit List
                            if dataManager.habits.isEmpty {
                                emptyState
                            } else {
                                ForEach(dataManager.habits) { habit in
                                    HabitRowView(habit: habit) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            dataManager.toggleCompletion(for: habit.id)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
            .navigationTitle("Dotti")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            dataManager.loadHabits()
        }
    }

    // MARK: - Premium Required State

    private var premiumRequiredState: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.yellow.opacity(0.3), Color.orange.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                Image(systemName: "crown.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text("Premium Feature")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)

            Text("Upgrade to Premium on your iPhone to use the Watch app")
                .font(.system(size: 11))
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [primaryPurple.opacity(0.3), primaryPink.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                Image(systemName: "checkmark.circle")
                    .font(.system(size: 24))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [primaryPurple, primaryPink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text("No Habits")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)

            Text("Open Dotti on your iPhone to add habits")
                .font(.system(size: 11))
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
    }
}

#Preview {
    ContentView()
        .environmentObject(WatchDataManager.shared)
        .environmentObject(WatchConnectivityManagerWatch.shared)
}
