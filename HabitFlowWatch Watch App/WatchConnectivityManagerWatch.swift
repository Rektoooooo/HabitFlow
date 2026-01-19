//
//  WatchConnectivityManagerWatch.swift
//  HabitFlowWatch
//
//  Created by Claude on 14.01.2026.
//

import Foundation
import WatchConnectivity
import WatchKit
import Combine

// MARK: - Watch Connectivity Manager (Watch Side)

class WatchConnectivityManagerWatch: NSObject, ObservableObject {
    @MainActor static let shared = WatchConnectivityManagerWatch()

    @Published var isReachable = false

    private var session: WCSession?

    override init() {
        super.init()
        setupWatchConnectivity()
    }

    // MARK: - Setup

    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else {
            #if DEBUG
            print("WatchConnectivity not supported")
            #endif
            return
        }

        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }

    // MARK: - Send Completion to iPhone

    func sendCompletion(habitId: UUID, completed: Bool) {
        guard let session = session, session.activationState == .activated else {
            #if DEBUG
            print("WCSession not activated")
            #endif
            return
        }

        let userInfo: [String: Any] = [
            "type": "completion",
            "habitId": habitId.uuidString,
            "completed": completed,
            "timestamp": Date().timeIntervalSince1970
        ]

        // Use transferUserInfo for reliable delivery
        session.transferUserInfo(userInfo)

        // Also try immediate message if reachable
        if session.isReachable {
            session.sendMessage(userInfo, replyHandler: nil) { error in
                #if DEBUG
                print("Failed to send immediate completion: \(error.localizedDescription)")
                #endif
            }
        }

        // Play haptic feedback
        WKInterfaceDevice.current().play(completed ? .success : .click)

        #if DEBUG
        print("Sent completion to iPhone: \(habitId) = \(completed)")
        #endif
    }

    // MARK: - Request Sync from iPhone

    func requestSync() {
        guard let session = session, session.isReachable else {
            #if DEBUG
            print("iPhone not reachable")
            #endif
            return
        }

        let message: [String: Any] = [
            "type": "requestSync",
            "timestamp": Date().timeIntervalSince1970
        ]

        session.sendMessage(message, replyHandler: nil) { error in
            #if DEBUG
            print("Failed to request sync: \(error.localizedDescription)")
            #endif
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManagerWatch: WCSessionDelegate {

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        #if DEBUG
        if let error = error {
            print("WCSession activation failed: \(error.localizedDescription)")
            return
        }
        print("WCSession activated: \(activationState.rawValue)")
        #else
        if error != nil { return }
        #endif

        Task { @MainActor in
            isReachable = session.isReachable
        }

        // Check for any existing application context
        let context = session.receivedApplicationContext
        if !context.isEmpty {
            #if DEBUG
            print("Found existing application context")
            #endif
            processIncomingData(context)
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isReachable = session.isReachable
            #if DEBUG
            print("iPhone reachability changed: \(session.isReachable)")
            #endif

            // Request sync when iPhone becomes reachable
            if session.isReachable {
                requestSync()
            }
        }
    }

    // Receive messages from iPhone
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        processIncomingData(message)
    }

    // Receive user info transfers (queued delivery)
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        processIncomingData(userInfo)
    }

    // Receive application context (most reliable for simulator)
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        #if DEBUG
        print("Received application context from iPhone")
        #endif
        processIncomingData(applicationContext)
    }

    // Process incoming data from iPhone
    private nonisolated func processIncomingData(_ data: [String: Any]) {
        guard let type = data["type"] as? String else { return }

        Task { @MainActor in
            switch type {
            case "habitsUpdate":
                // Extract premium status
                let isPremium = data["isPremium"] as? Bool ?? false

                if let habitsData = data["data"] as? Data,
                   let habits = try? JSONDecoder().decode([WatchHabitData].self, from: habitsData) {
                    WatchDataManager.shared.saveHabits(habits, isPremium: isPremium)
                    #if DEBUG
                    print("Received \(habits.count) habits from iPhone (Premium: \(isPremium))")
                    #endif

                    // Play notification haptic only if premium
                    if isPremium {
                        WKInterfaceDevice.current().play(.notification)
                    }
                } else {
                    // Update premium status even if no habits data
                    WatchDataManager.shared.updatePremiumStatus(isPremium)
                }

            default:
                #if DEBUG
                print("Unknown message type from iPhone: \(type)")
                #endif
            }
        }
    }
}
