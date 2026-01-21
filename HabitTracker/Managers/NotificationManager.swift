//
//  NotificationManager.swift
//  HabitTracker
//
//  Created by Sebastián Kučera on 13.01.2026.
//

import Foundation
import UserNotifications
import SwiftUI
import Combine
import UIKit

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false
    @Published var reminderTime: Date {
        didSet {
            saveReminderTime()
            if isEnabled {
                scheduleReminder()
            }
        }
    }
    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "notificationsEnabled")
            if isEnabled {
                requestAuthorization()
            } else {
                cancelAllNotifications()
            }
        }
    }

    private let notificationCenter = UNUserNotificationCenter.current()
    private let reminderIdentifier = "habitflow.daily.reminder"

    private init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")

        if let savedTime = UserDefaults.standard.object(forKey: "reminderTime") as? Date {
            self.reminderTime = savedTime
        } else {
            var components = DateComponents()
            components.hour = 9
            components.minute = 0
            self.reminderTime = Calendar.current.date(from: components) ?? Date()
        }

        Task {
            await checkAuthorizationStatus()
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    func requestAuthorization() {
        Task {
            do {
                let granted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
                isAuthorized = granted
                if granted {
                    scheduleReminder()
                }
            } catch {
                isAuthorized = false
            }
        }
    }

    func scheduleReminder() {
        cancelAllNotifications()

        guard isEnabled && isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Time to check your habits!"
        content.body = "Don't break your streak. Open Habit Owl to track your progress."
        content.sound = .default
        content.badge = 1

        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: reminderIdentifier,
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request)
    }

    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.setBadgeCount(0)
    }

    private func saveReminderTime() {
        UserDefaults.standard.set(reminderTime, forKey: "reminderTime")
    }

    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
