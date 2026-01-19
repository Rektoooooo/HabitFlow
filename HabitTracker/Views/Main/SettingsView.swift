//
//  SettingsView.swift
//  HabitTracker
//
//  Created by Sebastián Kučera on 12.01.2026.
//

import SwiftUI
import StoreKit

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.requestReview) private var requestReview
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @ObservedObject private var store = StoreManager.shared
    @ObservedObject private var notificationManager = NotificationManager.shared
    @ObservedObject private var healthKitManager = HealthKitManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared

    @State private var showingPaywall = false
    @State private var iCloudAvailable = false
    @State private var isCheckingICloud = true

    // Adaptive text colors
    private var primaryText: Color {
        colorScheme == .dark ? .white : Color(red: 0.2, green: 0.15, blue: 0.3)
    }

    private var secondaryText: Color {
        colorScheme == .dark ? .white.opacity(0.7) : Color(red: 0.4, green: 0.35, blue: 0.5)
    }

    private var tertiaryText: Color {
        colorScheme == .dark ? .white.opacity(0.5) : Color(red: 0.5, green: 0.45, blue: 0.6)
    }

    private var accentColor: Color {
        themeManager.primaryColor
    }

    private var dividerColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.1) : Color.gray.opacity(0.2)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Floating clouds background
                FloatingClouds()

                ScrollView {
                    VStack(spacing: 24) {
                        // Premium Section
                        premiumSection

                        // Appearance Section
                        appearanceSection

                        // Notifications Section
                        notificationSection

                        // Data & Privacy Section
                        dataPrivacySection

                        // Support Section
                        supportSection

                        // About Section
                        aboutSection

                        // Developer Section (DEBUG only)
                        #if DEBUG
                        developerSection
                        #endif

                        // App Version
                        versionSection
                    }
                    .padding(20)
                    .padding(.bottom, 60)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .task {
                await checkiCloudStatus()
            }
        }
        .preferredColorScheme(themeManager.appearanceMode.colorScheme)
    }

    // MARK: - iCloud Status Check

    private func checkiCloudStatus() async {
        // Use FileManager to check iCloud availability (safe, won't crash)
        // This checks if user is signed into iCloud on the device
        let isAvailable = FileManager.default.ubiquityIdentityToken != nil
        await MainActor.run {
            iCloudAvailable = isAvailable
            isCheckingICloud = false
        }
    }

    // MARK: - Premium Section

    private var premiumSection: some View {
        VStack(spacing: 0) {
            if store.isPremium {
                // Premium active
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)

                        Image(systemName: "crown.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Premium Active")
                            .font(.headline)
                            .foregroundStyle(primaryText)

                        Text("You have access to all features")
                            .font(.caption)
                            .foregroundStyle(secondaryText)
                    }

                    Spacer()

                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                }
                .padding(20)
            } else {
                // Upgrade prompt
                Button {
                    showingPaywall = true
                } label: {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.yellow.opacity(0.3), .orange.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 50, height: 50)

                            Image(systemName: "crown")
                                .font(.title2)
                                .foregroundStyle(.yellow)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Upgrade to Premium")
                                .font(.headline)
                                .foregroundStyle(primaryText)

                            Text("Unlock unlimited habits & more")
                                .font(.caption)
                                .foregroundStyle(secondaryText)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(tertiaryText)
                    }
                    .padding(20)
                }

            }
        }
        .liquidGlass(cornerRadius: 20)
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Appearance")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(secondaryText)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                // Appearance Customization (Premium)
                NavigationLink {
                    AppearanceView()
                } label: {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(themeManager.primaryGradient)
                                .frame(width: 40, height: 40)

                            Image(systemName: "paintpalette.fill")
                                .font(.body)
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 8) {
                                Text("Theme & Colors")
                                    .font(.body)
                                    .foregroundStyle(primaryText)

                                if !store.isPremium {
                                    Text("PRO")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(
                                            Capsule()
                                                .fill(themeManager.primaryGradient)
                                        )
                                }
                            }

                            Text("\(themeManager.appearanceMode.displayName) mode, \(themeManager.accentColor.displayName)")
                                .font(.caption)
                                .foregroundStyle(secondaryText)
                        }

                        Spacer()

                        // Color preview circles
                        HStack(spacing: -6) {
                            ForEach([AccentColor.purple, .pink, .blue, .green], id: \.self) { color in
                                Circle()
                                    .fill(color.color)
                                    .frame(width: 18, height: 18)
                                    .overlay(
                                        Circle()
                                            .stroke(colorScheme == .dark ? Color.black : Color.white, lineWidth: 2)
                                    )
                            }
                        }

                        Image(systemName: "chevron.right")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(tertiaryText)
                    }
                    .padding(16)
                }
                .accessibilityLabel("Theme and Colors, currently \(themeManager.appearanceMode.displayName) mode with \(themeManager.accentColor.displayName) accent")
                .accessibilityHint("Double tap to customize app appearance")
            }
            .liquidGlass(cornerRadius: 20)
        }
    }

    // MARK: - Notification Section

    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Notifications")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(secondaryText)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                // Enable Notifications Toggle
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.red.opacity(0.2))
                            .frame(width: 40, height: 40)

                        Image(systemName: "bell.fill")
                            .font(.body)
                            .foregroundStyle(.red)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily Reminder")
                            .font(.body)
                            .foregroundStyle(primaryText)

                        Text(notificationManager.isEnabled ? "Enabled" : "Disabled")
                            .font(.caption)
                            .foregroundStyle(secondaryText)
                    }

                    Spacer()

                    Toggle("", isOn: $notificationManager.isEnabled)
                        .tint(accentColor)
                        .onChange(of: notificationManager.isEnabled) { _, _ in
                            HapticManager.shared.lightTap()
                        }
                }
                .padding(16)

                if notificationManager.isEnabled {
                    Divider()
                        .background(dividerColor)
                        .padding(.leading, 66)

                    // Reminder Time Picker
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.orange.opacity(0.2))
                                .frame(width: 40, height: 40)

                            Image(systemName: "clock.fill")
                                .font(.body)
                                .foregroundStyle(.orange)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Reminder Time")
                                .font(.body)
                                .foregroundStyle(primaryText)

                            Text("When to remind you")
                                .font(.caption)
                                .foregroundStyle(secondaryText)
                        }

                        Spacer()

                        DatePicker(
                            "",
                            selection: $notificationManager.reminderTime,
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                        .tint(accentColor)
                    }
                    .padding(16)
                }

                if notificationManager.isEnabled && !notificationManager.isAuthorized {
                    Divider()
                        .background(dividerColor)
                        .padding(.leading, 66)

                    Button {
                        notificationManager.openSettings()
                    } label: {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.yellow.opacity(0.2))
                                    .frame(width: 40, height: 40)

                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.body)
                                    .foregroundStyle(.yellow)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Enable in Settings")
                                    .font(.body)
                                    .foregroundStyle(primaryText)

                                Text("Notifications are blocked")
                                    .font(.caption)
                                    .foregroundStyle(secondaryText)
                            }

                            Spacer()

                            Image(systemName: "arrow.up.right")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(tertiaryText)
                        }
                        .padding(16)
                    }
                }
            }
            .liquidGlass(cornerRadius: 20)
        }
    }

    // MARK: - Data & Privacy Section

    private var dataPrivacySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Data & Privacy")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(secondaryText)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                // iCloud Sync Status
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 40, height: 40)

                        if isCheckingICloud {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.blue)
                        } else {
                            Image(systemName: iCloudAvailable ? "checkmark.icloud.fill" : "icloud.slash.fill")
                                .font(.body)
                                .foregroundStyle(.blue)
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("iCloud Sync")
                            .font(.body)
                            .foregroundStyle(primaryText)

                        Text(isCheckingICloud ? "Checking..." : (iCloudAvailable ? "Syncing across devices" : "Sign in to iCloud in Settings"))
                            .font(.caption)
                            .foregroundStyle(secondaryText)
                    }

                    Spacer()

                    if !isCheckingICloud {
                        Image(systemName: iCloudAvailable ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .foregroundStyle(iCloudAvailable ? .green : .orange)
                    }
                }
                .padding(16)

                Divider()
                    .background(dividerColor)
                    .padding(.leading, 66)

                // HealthKit Status
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.pink.opacity(0.2))
                            .frame(width: 40, height: 40)

                        Image(systemName: "heart.fill")
                            .font(.body)
                            .foregroundStyle(.pink)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Apple Health")
                            .font(.body)
                            .foregroundStyle(primaryText)

                        Text(healthKitManager.isHealthKitAvailable ? "Connected" : "Not available")
                            .font(.caption)
                            .foregroundStyle(secondaryText)
                    }

                    Spacer()

                    if healthKitManager.isHealthKitAvailable {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(tertiaryText)
                    }
                }
                .padding(16)
            }
            .liquidGlass(cornerRadius: 20)
        }
    }

    // MARK: - Support Section

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Support")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(secondaryText)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                // Rate App
                SettingsRow(
                    icon: "star.fill",
                    iconColor: .yellow,
                    title: "Rate App",
                    subtitle: "Help us with a review",
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                    tertiaryText: tertiaryText
                ) {
                    requestReview()
                }

                Divider()
                    .background(dividerColor)
                    .padding(.leading, 66)

                // Share App
                SettingsRow(
                    icon: "square.and.arrow.up.fill",
                    iconColor: .green,
                    title: "Share App",
                    subtitle: "Tell your friends",
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                    tertiaryText: tertiaryText,
                    showChevron: false
                ) {
                    shareApp()
                }

                Divider()
                    .background(dividerColor)
                    .padding(.leading, 66)

                // Send Feedback
                SettingsRow(
                    icon: "envelope.fill",
                    iconColor: .blue,
                    title: "Send Feedback",
                    subtitle: "We'd love to hear from you",
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                    tertiaryText: tertiaryText
                ) {
                    sendFeedback()
                }
            }
            .liquidGlass(cornerRadius: 20)
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Legal")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(secondaryText)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                // Privacy Policy
                SettingsRow(
                    icon: "hand.raised.fill",
                    iconColor: .purple,
                    title: "Privacy Policy",
                    subtitle: nil,
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                    tertiaryText: tertiaryText
                ) {
                    openURL("https://sebkucera.dev/dottihabits/privacy-policy")
                }

                Divider()
                    .background(dividerColor)
                    .padding(.leading, 66)

                // Terms of Use
                SettingsRow(
                    icon: "doc.text.fill",
                    iconColor: .gray,
                    title: "Terms of Use",
                    subtitle: nil,
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                    tertiaryText: tertiaryText
                ) {
                    openURL("https://sebkucera.dev/dottihabits/tos")
                }
            }
            .liquidGlass(cornerRadius: 20)
        }
    }

    // MARK: - Developer Section (DEBUG only)

    #if DEBUG
    private var developerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Developer")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.orange)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                // Toggle Premium
                Button {
                    store.debugTogglePremium()
                } label: {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.orange.opacity(0.2))
                                .frame(width: 40, height: 40)

                            Image(systemName: store.isPremium ? "lock.open.fill" : "lock.fill")
                                .font(.body)
                                .foregroundStyle(.orange)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(store.isPremium ? "Lock Premium" : "Unlock Premium")
                                .font(.body)
                                .foregroundStyle(primaryText)

                            Text("Toggle premium status for testing")
                                .font(.caption)
                                .foregroundStyle(secondaryText)
                        }

                        Spacer()

                        Text(store.isPremium ? "ON" : "OFF")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(store.isPremium ? .green : tertiaryText)
                    }
                    .padding(16)
                }

                Divider()
                    .background(dividerColor)
                    .padding(.leading, 66)

                // Reset Onboarding
                Button {
                    hasCompletedOnboarding = false
                } label: {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.red.opacity(0.2))
                                .frame(width: 40, height: 40)

                            Image(systemName: "arrow.counterclockwise")
                                .font(.body)
                                .foregroundStyle(.red)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Reset Onboarding")
                                .font(.body)
                                .foregroundStyle(primaryText)

                            Text("Show onboarding on next launch")
                                .font(.caption)
                                .foregroundStyle(secondaryText)
                        }

                        Spacer()
                    }
                    .padding(16)
                }

                Divider()
                    .background(dividerColor)
                    .padding(.leading, 66)

                // Clear Notifications
                Button {
                    notificationManager.cancelAllNotifications()
                } label: {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.yellow.opacity(0.2))
                                .frame(width: 40, height: 40)

                            Image(systemName: "bell.slash.fill")
                                .font(.body)
                                .foregroundStyle(.yellow)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Clear Notifications")
                                .font(.body)
                                .foregroundStyle(primaryText)

                            Text("Cancel all pending notifications")
                                .font(.caption)
                                .foregroundStyle(secondaryText)
                        }

                        Spacer()
                    }
                    .padding(16)
                }
            }
            .liquidGlass(cornerRadius: 20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 2)
            )
        }
    }
    #endif

    // MARK: - Version Section

    private var versionSection: some View {
        VStack(spacing: 8) {
            Image("ProfileMascot")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .opacity(0.8)

            Text("Dotti")
                .font(.headline)
                .foregroundStyle(secondaryText)

            Text("Version \(appVersion)")
                .font(.caption)
                .foregroundStyle(tertiaryText)

            Text("Made with love")
                .font(.caption2)
                .foregroundStyle(tertiaryText)
        }
        .padding(.vertical, 20)
    }

    // MARK: - Helper Properties

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    // MARK: - Actions

    private func shareApp() {
        let appURL = URL(string: "https://apps.apple.com/app/dotti/id123456789")! // Replace with actual App Store URL
        let message = "Check out Dotti - the best app to build better habits!"

        let activityVC = UIActivityViewController(
            activityItems: [message, appURL],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            // For iPad - set source view for popover
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            rootVC.present(activityVC, animated: true)
        }
    }

    private func sendFeedback() {
        let email = "sebastian.kucera@icloud.com"
        let subject = "Dotti Feedback - v\(appVersion)"
        let body = "\n\n---\nApp Version: \(appVersion)\niOS Version: \(UIDevice.current.systemVersion)\nDevice: \(UIDevice.current.model)"

        let urlString = "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"

        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }

    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    let primaryText: Color
    let secondaryText: Color
    let tertiaryText: Color
    var showChevron: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.body)
                        .foregroundStyle(iconColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(primaryText)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(secondaryText)
                    }
                }

                Spacer()

                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(tertiaryText)
                }
            }
            .padding(16)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(subtitle != nil ? "\(title), \(subtitle!)" : title)
        .accessibilityHint("Double tap to open")
    }
}

#Preview {
    SettingsView()
}
