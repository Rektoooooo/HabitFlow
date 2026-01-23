//
//  PaywallView.swift
//  HabitTracker
//
//  Created by Sebastián Kučera on 12.01.2026.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var store = StoreManager.shared
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    // Premium features with descriptions
    private let premiumFeatures: [(icon: String, title: String, description: String)] = [
        ("infinity", "Unlimited Habits", "Track as many habits as you want"),
        ("applewatch", "Apple Watch", "Track habits from your wrist"),
        ("widget.small.badge.plus", "All Widgets", "Home screen & history widgets"),
        ("chart.line.uptrend.xyaxis", "Advanced Insights", "Weekly patterns & statistics"),
        ("timer", "Focus Sessions", "Timed habit sessions with breaks"),
        ("link", "Habit Chains", "Chain habits together"),
        ("lightbulb.fill", "Smart Suggestions", "AI-powered habit recommendations"),
        ("icloud.fill", "iCloud Sync", "Access on all your devices")
    ]

    // Adaptive colors
    private var primaryText: Color {
        colorScheme == .dark ? .white : Color(hex: "#1F1535")
    }

    private var secondaryText: Color {
        colorScheme == .dark ? .white.opacity(0.7) : Color(hex: "#6B5B7A")
    }

    private var tertiaryText: Color {
        colorScheme == .dark ? .white.opacity(0.5) : Color(hex: "#9B8BA8")
    }

    private var accentPurple: Color { Color(hex: "#A855F7") }
    private var accentPink: Color { Color(hex: "#EC4899") }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                FloatingClouds()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // Header
                        headerSection

                        // Stats/Social Proof
                        socialProofSection

                        // Features
                        featuresSection

                        // Pricing Cards
                        pricingSection

                        // Purchase Button
                        purchaseButtonSection

                        // Legal
                        legalSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(tertiaryText)
                    }
                    .accessibilityLabel("Close")
                    .accessibilityHint("Double tap to close the subscription screen")
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onChange(of: store.showError) { _, newValue in
                if newValue, let message = store.errorMessage {
                    errorMessage = message
                    showError = true
                    store.dismissError()
                }
            }
            .onAppear {
                selectedProduct = store.monthlyProduct ?? store.products.first
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Premium Mascot
            Image("PremiumMascot")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)

            VStack(spacing: 8) {
                Text("Unlock Habit Owl Premium")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(primaryText)

                Text("Build better habits with powerful tools")
                    .font(.subheadline)
                    .foregroundStyle(secondaryText)
            }
        }
        .padding(.top, 10)
    }

    // MARK: - Value Props

    private var socialProofSection: some View {
        HStack(spacing: 20) {
            StatBadge(value: "No Ads", label: "Ever", icon: "hand.raised.fill")
            StatBadge(value: "Secure", label: "iCloud Sync", icon: "lock.shield.fill")
            StatBadge(value: "Fast", label: "Support", icon: "bubble.left.fill")
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .liquidGlass(cornerRadius: 16)
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Everything in Premium")
                .font(.headline)
                .foregroundStyle(primaryText)
                .padding(.horizontal, 4)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(premiumFeatures, id: \.title) { feature in
                    FeatureCard(
                        icon: feature.icon,
                        title: feature.title,
                        accentColor: accentPurple,
                        primaryText: primaryText,
                        secondaryText: secondaryText
                    )
                }
            }
        }
    }

    // MARK: - Pricing

    private var pricingSection: some View {
        VStack(spacing: 12) {
            if store.isLoading {
                ProgressView()
                    .tint(accentPurple)
                    .frame(height: 160)
            } else {
                // Monthly
                if let monthly = store.monthlyProduct {
                    PricingCard(
                        product: monthly,
                        isSelected: selectedProduct?.id == monthly.id,
                        badge: nil,
                        badgeColor: .clear,
                        savingsText: nil,
                        primaryText: primaryText,
                        secondaryText: secondaryText,
                        accentColor: accentPurple
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedProduct = monthly
                        }
                    }
                }

                // Yearly - Best Value
                if let yearly = store.yearlyProduct {
                    PricingCard(
                        product: yearly,
                        isSelected: selectedProduct?.id == yearly.id,
                        badge: "BEST VALUE",
                        badgeColor: .green,
                        savingsText: calculateSavings(),
                        primaryText: primaryText,
                        secondaryText: secondaryText,
                        accentColor: accentPurple
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedProduct = yearly
                        }
                    }
                }

                // Lifetime
                if let lifetime = store.lifetimeProduct {
                    PricingCard(
                        product: lifetime,
                        isSelected: selectedProduct?.id == lifetime.id,
                        badge: "ONE TIME",
                        badgeColor: .orange,
                        savingsText: "Pay once, own forever",
                        primaryText: primaryText,
                        secondaryText: secondaryText,
                        accentColor: accentPurple
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedProduct = lifetime
                        }
                    }
                }
            }
        }
    }

    // MARK: - Purchase Button

    private var purchaseButtonSection: some View {
        VStack(spacing: 12) {
            // Main CTA Button
            Button {
                Task {
                    await purchase()
                }
            } label: {
                HStack(spacing: 8) {
                    if isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Start Premium")
                            .fontWeight(.semibold)

                        Image(systemName: "arrow.right")
                            .font(.subheadline.weight(.semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    LinearGradient(
                        colors: [accentPurple, accentPink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: accentPurple.opacity(0.4), radius: 12, y: 6)
            }
            .disabled(selectedProduct == nil || isPurchasing)
            .opacity(selectedProduct == nil ? 0.6 : 1)
            .accessibilityLabel(isPurchasing ? "Purchasing" : "Start Premium subscription")
            .accessibilityHint("Double tap to purchase the selected subscription plan")

            // Restore Button
            Button {
                Task {
                    try? await store.restorePurchases()
                }
            } label: {
                Text("Restore Purchases")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(secondaryText)
            }
            .accessibilityLabel("Restore Purchases")
            .accessibilityHint("Double tap to restore previously purchased subscriptions")
        }
    }

    // MARK: - Legal

    private var legalSection: some View {
        VStack(spacing: 16) {
            // Guarantee
            HStack(spacing: 8) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundStyle(.green)
                Text("Cancel anytime")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(secondaryText)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(Color.green.opacity(0.1))
            .clipShape(Capsule())

            // Subscription terms - required by App Store
            VStack(spacing: 8) {
                if let product = selectedProduct {
                    if product.type == .autoRenewable {
                        Text("Subscription auto-renews at \(product.displayPrice)/\(product.subscription?.subscriptionPeriod.unit == .year ? "year" : "month") unless cancelled at least 24 hours before the current period ends. Manage subscriptions in Settings.")
                            .font(.caption)
                            .foregroundStyle(secondaryText)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    Text("Cancel anytime. Subscription auto-renews unless turned off at least 24 hours before the period ends. Manage in Settings.")
                        .font(.caption)
                        .foregroundStyle(secondaryText)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 20)

            // Terms and Privacy links - required by App Store
            HStack(spacing: 24) {
                if let termsURL = URL(string: "https://sebkucera.dev/habitowl/tos") {
                    Link(destination: termsURL) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.text")
                                .font(.caption)
                            Text("Terms of Use")
                        }
                    }
                    .accessibilityLabel("Terms of Use")
                    .accessibilityHint("Opens terms of use in browser")
                }

                Text("•")
                    .foregroundStyle(tertiaryText)

                if let privacyURL = URL(string: "https://sebkucera.dev/habitowl/privacy-policy") {
                    Link(destination: privacyURL) {
                        HStack(spacing: 4) {
                            Image(systemName: "hand.raised")
                                .font(.caption)
                            Text("Privacy Policy")
                        }
                    }
                    .accessibilityLabel("Privacy Policy")
                    .accessibilityHint("Opens privacy policy in browser")
                }
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(accentPurple)
        }
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private func calculateSavings() -> String? {
        guard let monthly = store.monthlyProduct,
              let yearly = store.yearlyProduct else { return nil }

        let monthlyPerYear = NSDecimalNumber(decimal: monthly.price).doubleValue * 12
        let yearlyCost = NSDecimalNumber(decimal: yearly.price).doubleValue
        let savings = ((monthlyPerYear - yearlyCost) / monthlyPerYear) * 100

        return "Save \(Int(savings))%"
    }

    private func purchase() async {
        guard let product = selectedProduct else { return }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            if let _ = try await store.purchase(product) {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(Color(hex: "#A855F7"))
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Feature Card

struct FeatureCard: View {
    let icon: String
    let title: String
    let accentColor: Color
    let primaryText: Color
    let secondaryText: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(accentColor)
                .frame(width: 28, height: 28)
                .background(accentColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(primaryText)
                .lineLimit(1)

            Spacer(minLength: 0)
        }
        .padding(10)
        .liquidGlass(cornerRadius: 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) feature included")
    }
}

// MARK: - Pricing Card

struct PricingCard: View {
    let product: Product
    let isSelected: Bool
    let badge: String?
    let badgeColor: Color
    let savingsText: String?
    let primaryText: Color
    let secondaryText: Color
    let accentColor: Color
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var periodText: String {
        if product.type == .nonConsumable {
            return "lifetime"
        }
        return product.subscription?.subscriptionPeriod.unit == .year ? "year" : "month"
    }

    private var perMonthPrice: String? {
        guard product.type != .nonConsumable,
              let period = product.subscription?.subscriptionPeriod,
              period.unit == .year else { return nil }

        let monthlyPrice = product.price / 12
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceFormatStyle.locale
        return formatter.string(from: monthlyPrice as NSDecimalNumber)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? accentColor : secondaryText.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 14, height: 14)
                    }
                }

                // Plan details
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(product.subscription?.subscriptionPeriod.displayName ?? "Lifetime")
                            .font(.headline)
                            .foregroundStyle(primaryText)

                        if let badge = badge {
                            Text(badge)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(badgeColor)
                                .clipShape(Capsule())
                        }
                    }

                    if let savings = savingsText {
                        Text(savings)
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }

                Spacer()

                // Price
                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(primaryText)

                    if let perMonth = perMonthPrice {
                        Text("\(perMonth)/mo")
                            .font(.caption)
                            .foregroundStyle(secondaryText)
                    } else {
                        Text("/\(periodText)")
                            .font(.caption)
                            .foregroundStyle(secondaryText)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.7))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected
                            ? accentColor
                            : (colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05)),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(product.subscription?.subscriptionPeriod.displayName ?? "Lifetime") plan, \(product.displayPrice)")
        .accessibilityHint(isSelected ? "Currently selected" : "Double tap to select this plan")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    PaywallView()
}
