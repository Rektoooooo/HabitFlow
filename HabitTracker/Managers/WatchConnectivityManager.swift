//
//  WatchConnectivityManager.swift
//  HabitTracker
//
//  Created by Claude on 14.01.2026.
//

import Foundation
import WatchConnectivity
import SwiftData
import Combine

// MARK: - Watch Connectivity Manager (iPhone Side)

class WatchConnectivityManager: NSObject, ObservableObject {
    @MainActor static let shared = WatchConnectivityManager()

    @Published var isWatchAppInstalled = false
    @Published var isReachable = false

    private let suiteName = "group.ic-servis.com.HabitTracker"
    private let habitsKey = "watchHabits"

    private var session: WCSession?
    private var modelContext: ModelContext?

    override init() {
        super.init()
        setupWatchConnectivity()
    }

    // MARK: - Setup

    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else {
            #if DEBUG
            print("WatchConnectivity not supported on this device")
            #endif
            return
        }

        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }

    /// Set the model context for handling completions from Watch
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Send Habits to Watch

    func sendHabitsToWatch(_ habits: [Habit]) {
        guard let session = session, session.activationState == .activated else {
            #if DEBUG
            print("WCSession not activated")
            #endif
            return
        }

        // Don't spam sync attempts if no Watch is paired
        guard session.isPaired else {
            return
        }

        // Only sync if Watch app is installed
        guard session.isWatchAppInstalled else {
            #if DEBUG
            print("Watch app not installed, skipping sync")
            #endif
            return
        }

        // Convert to watch-compatible data
        let watchHabits = habits.map { habit in
            WatchHabitData(
                id: habit.id,
                name: habit.name,
                icon: habit.icon,
                color: habit.color,
                isCompletedToday: habit.isCompletedToday,
                currentStreak: habit.currentStreak
            )
        }

        // Encode to JSON
        guard let data = try? JSONEncoder().encode(watchHabits) else {
            #if DEBUG
            print("Failed to encode habits for Watch")
            #endif
            return
        }

        // Also save to App Group for complications
        if let defaults = UserDefaults(suiteName: suiteName) {
            defaults.set(data, forKey: habitsKey)
        }

        // Send to Watch using transferUserInfo (queued, reliable)
        let userInfo: [String: Any] = [
            "type": "habitsUpdate",
            "data": data,
            "timestamp": Date().timeIntervalSince1970
        ]

        // Use application context for reliable sync (works better in simulator)
        do {
            try session.updateApplicationContext(userInfo)
            #if DEBUG
            print("Updated application context with \(watchHabits.count) habits")
            #endif
        } catch {
            #if DEBUG
            print("Failed to update application context: \(error.localizedDescription)")
            #endif
        }

        // Also use transferUserInfo for queued delivery
        session.transferUserInfo(userInfo)
        #if DEBUG
        print("Sent \(watchHabits.count) habits to Watch")
        #endif

        // If reachable, also send immediate message for faster update
        if session.isReachable {
            session.sendMessage(userInfo, replyHandler: nil) { error in
                #if DEBUG
                print("Failed to send immediate message: \(error.localizedDescription)")
                #endif
            }
        }
    }

    // MARK: - Handle Completion from Watch

    private func handleCompletionFromWatch(habitId: UUID, completed: Bool) {
        guard let context = modelContext else {
            #if DEBUG
            print("No model context available")
            #endif
            return
        }

        Task { @MainActor in
            do {
                let descriptor = FetchDescriptor<Habit>(
                    predicate: #Predicate { $0.id == habitId }
                )

                guard let habit = try context.fetch(descriptor).first else {
                    #if DEBUG
                    print("Habit not found: \(habitId)")
                    #endif
                    return
                }

                let calendar = Calendar.current

                if completed {
                    // Add completion if not already completed
                    if !habit.isCompletedToday {
                        let completion = HabitCompletion(date: Date(), habit: habit)
                        if habit.completions == nil { habit.completions = [] }
                        habit.completions?.append(completion)
                        context.insert(completion)
                        HapticManager.shared.habitCompleted()
                    }
                } else {
                    // Remove today's completion
                    if let todayCompletion = habit.safeCompletions.first(where: { calendar.isDateInToday($0.date) }) {
                        habit.completions?.removeAll { $0.id == todayCompletion.id }
                        context.delete(todayCompletion)
                    }
                }

                try context.save()

                // Notify widgets and sync back to Watch
                NotificationCenter.default.post(name: .habitsDidChange, object: nil)

                #if DEBUG
                print("Processed completion from Watch for habit: \(habit.name)")
                #endif

            } catch {
                #if DEBUG
                print("Failed to handle completion from Watch: \(error)")
                #endif
            }
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            #if DEBUG
            if let error = error {
                print("WCSession activation failed: \(error.localizedDescription)")
                return
            }
            print("WCSession activated with state: \(activationState.rawValue)")
            #else
            if error != nil { return }
            #endif
            isWatchAppInstalled = session.isWatchAppInstalled
            isReachable = session.isReachable
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        #if DEBUG
        print("WCSession became inactive")
        #endif
    }

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        #if DEBUG
        print("WCSession deactivated")
        #endif
        // Reactivate for switching watches
        session.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isReachable = session.isReachable
            #if DEBUG
            print("Watch reachability changed: \(session.isReachable)")
            #endif
        }
    }

    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in
            isWatchAppInstalled = session.isWatchAppInstalled
            #if DEBUG
            print("Watch app installed: \(session.isWatchAppInstalled)")
            #endif
        }
    }

    // Receive messages from Watch
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        guard let type = message["type"] as? String else { return }

        Task { @MainActor in
            switch type {
            case "completion":
                if let idString = message["habitId"] as? String,
                   let habitId = UUID(uuidString: idString),
                   let completed = message["completed"] as? Bool {
                    handleCompletionFromWatch(habitId: habitId, completed: completed)
                }

            case "requestSync":
                // Watch is requesting fresh data
                #if DEBUG
                print("Watch requested sync")
                #endif
                NotificationCenter.default.post(name: .watchRequestedSync, object: nil)

            default:
                #if DEBUG
                print("Unknown message type from Watch: \(type)")
                #endif
            }
        }
    }

    // Receive user info transfers (queued delivery)
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        guard let type = userInfo["type"] as? String else { return }

        Task { @MainActor in
            switch type {
            case "completion":
                if let idString = userInfo["habitId"] as? String,
                   let habitId = UUID(uuidString: idString),
                   let completed = userInfo["completed"] as? Bool {
                    handleCompletionFromWatch(habitId: habitId, completed: completed)
                }

            default:
                #if DEBUG
                print("Unknown userInfo type from Watch: \(type)")
                #endif
            }
        }
    }
}

// MARK: - Watch Habit Data (Shared Model)

struct WatchHabitData: Codable, Identifiable {
    let id: UUID
    let name: String
    let icon: String
    let color: String
    var isCompletedToday: Bool
    let currentStreak: Int
}

// MARK: - Notification Names

extension Notification.Name {
    static let watchRequestedSync = Notification.Name("watchRequestedSync")
}
