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
            print("WatchConnectivity not supported")
            return
        }

        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }

    // MARK: - Send Completion to iPhone

    func sendCompletion(habitId: UUID, completed: Bool) {
        guard let session = session, session.activationState == .activated else {
            print("WCSession not activated")
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
                print("Failed to send immediate completion: \(error.localizedDescription)")
            }
        }

        // Play haptic feedback
        WKInterfaceDevice.current().play(completed ? .success : .click)

        print("Sent completion to iPhone: \(habitId) = \(completed)")
    }

    // MARK: - Request Sync from iPhone

    func requestSync() {
        guard let session = session, session.isReachable else {
            print("iPhone not reachable")
            return
        }

        let message: [String: Any] = [
            "type": "requestSync",
            "timestamp": Date().timeIntervalSince1970
        ]

        session.sendMessage(message, replyHandler: nil) { error in
            print("Failed to request sync: \(error.localizedDescription)")
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManagerWatch: WCSessionDelegate {

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed: \(error.localizedDescription)")
            return
        }

        print("WCSession activated: \(activationState.rawValue)")

        Task { @MainActor in
            isReachable = session.isReachable
        }

        // Check for any existing application context
        let context = session.receivedApplicationContext
        if !context.isEmpty {
            print("Found existing application context")
            processIncomingData(context)
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isReachable = session.isReachable
            print("iPhone reachability changed: \(session.isReachable)")

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
        print("Received application context from iPhone")
        processIncomingData(applicationContext)
    }

    // Process incoming data from iPhone
    private nonisolated func processIncomingData(_ data: [String: Any]) {
        guard let type = data["type"] as? String else { return }

        Task { @MainActor in
            switch type {
            case "habitsUpdate":
                if let habitsData = data["data"] as? Data,
                   let habits = try? JSONDecoder().decode([WatchHabitData].self, from: habitsData) {
                    WatchDataManager.shared.saveHabits(habits)
                    print("Received \(habits.count) habits from iPhone")

                    // Play notification haptic
                    WKInterfaceDevice.current().play(.notification)
                }

            default:
                print("Unknown message type from iPhone: \(type)")
            }
        }
    }
}
