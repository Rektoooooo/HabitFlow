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
        ("link", "Habit Stacking", "Chain habits together"),
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
                FloatingClouds(theme: .habitTracker(colorScheme))

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
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                selectedProduct = store.yearlyProduct ?? store.products.first
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Pro Badge
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accentPurple.opacity(0.4), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)

                // Icon container
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [accentPurple, accentPink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)

                    Image(systemName: "sparkles")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }

            VStack(spacing: 8) {
                Text("Unlock HabitFlow Pro")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(primaryText)

                Text("Build better habits with powerful tools")
                    .font(.subheadline)
                    .foregroundStyle(secondaryText)
            }
        }
        .padding(.top, 10)
    }

    // MARK: - Social Proof

    private var socialProofSection: some View {
        HStack(spacing: 20) {
            StatBadge(value: "10K+", label: "Active Users", icon: "person.2.fill")
            StatBadge(value: "4.8", label: "App Rating", icon: "star.fill")
            StatBadge(value: "1M+", label: "Habits Tracked", icon: "checkmark.circle.fill")
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .liquidGlass(cornerRadius: 16)
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Everything in Pro")
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

                // Lifetime (if available)
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
                        Text("Start Pro")
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
        }
    }

    // MARK: - Legal

    private var legalSection: some View {
        VStack(spacing: 12) {
            // Guarantee
            HStack(spacing: 8) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundStyle(.green)
                Text("7-day free trial included")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(secondaryText)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(Color.green.opacity(0.1))
            .clipShape(Capsule())

            Text("Cancel anytime. Subscription auto-renews unless turned off at least 24 hours before the period ends. Manage in Settings.")
                .font(.caption2)
                .foregroundStyle(tertiaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            HStack(spacing: 20) {
                Link("Terms of Use", destination: URL(string: "https://habitflow.app/terms")!)
                Link("Privacy Policy", destination: URL(string: "https://habitflow.app/privacy")!)
            }
            .font(.caption)
            .foregroundStyle(secondaryText)
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
    }
}

#Preview {
    PaywallView()
}
