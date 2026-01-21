//
//  HabitTrackerApp.swift
//  HabitTracker
//
//  Created by Sebastián Kučera on 12.01.2026.
//

import SwiftUI
import SwiftData
import WatchConnectivity

@main
struct HabitTrackerApp: App {
    let modelContainer: ModelContainer?
    let initializationError: Error?
    let isUsingLocalStorage: Bool

    init() {
        var container: ModelContainer?
        var error: Error?
        var usingLocalStorage = false

        do {
            // Schema for all models
            let schema = Schema([
                Habit.self,
                HabitCompletion.self,
                HabitStack.self,
                FocusSession.self
            ])

            // Configuration with iCloud sync
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private("iCloud.ic-servis.com.HabitTracker")
            )

            container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )

            #if DEBUG
            print("SwiftData with CloudKit initialized successfully")
            #endif
        } catch let cloudKitError {
            // Fallback to local-only storage if CloudKit fails
            #if DEBUG
            print("CloudKit initialization failed: \(cloudKitError.localizedDescription)")
            print("Falling back to local storage")
            #endif

            do {
                let schema = Schema([
                    Habit.self,
                    HabitCompletion.self,
                    HabitStack.self,
                    FocusSession.self
                ])

                let localConfig = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    cloudKitDatabase: .none
                )

                container = try ModelContainer(
                    for: schema,
                    configurations: [localConfig]
                )
                usingLocalStorage = true
            } catch let localError {
                // Store error for display instead of crashing
                error = localError
                #if DEBUG
                print("Failed to create ModelContainer: \(localError)")
                #endif
            }
        }

        self.modelContainer = container
        self.initializationError = error
        self.isUsingLocalStorage = usingLocalStorage
    }

    var body: some Scene {
        WindowGroup {
            if let container = modelContainer {
                ContentView()
                    .onAppear {
                        // Set model context for Watch connectivity
                        WatchConnectivityManager.shared.setModelContext(container.mainContext)
                    }
                    .modelContainer(container)
                    .environment(\.isUsingLocalStorage, isUsingLocalStorage)
            } else {
                DataErrorView(error: initializationError)
            }
        }
    }
}

// MARK: - Local Storage Environment Key

private struct IsUsingLocalStorageKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var isUsingLocalStorage: Bool {
        get { self[IsUsingLocalStorageKey.self] }
        set { self[IsUsingLocalStorageKey.self] = newValue }
    }
}

// MARK: - Data Error View

struct DataErrorView: View {
    let error: Error?
    @State private var showingDetails = false

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text("Unable to Load Data")
                    .font(.title2.weight(.bold))

                Text("Habit Owl couldn't initialize its database. Please try the following steps:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Recovery steps
            VStack(alignment: .leading, spacing: 12) {
                RecoveryStepRow(number: 1, text: "Close this app completely (swipe up)")
                RecoveryStepRow(number: 2, text: "Wait a few seconds")
                RecoveryStepRow(number: 3, text: "Reopen Habit Owl")
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
            .padding(.horizontal, 24)

            if let error = error {
                Button {
                    showingDetails.toggle()
                } label: {
                    HStack {
                        Text("Technical Details")
                            .font(.caption)
                        Image(systemName: showingDetails ? "chevron.up" : "chevron.down")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }

                if showingDetails {
                    Text(error.localizedDescription)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 32)
                        .multilineTextAlignment(.center)
                }
            }

            Spacer()

            Text("If the problem persists after restarting, try restarting your device or reinstalling the app.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

private struct RecoveryStepRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.accentColor))

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
    }
}
