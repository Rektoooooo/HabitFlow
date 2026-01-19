//
//  OnboardingView.swift
//  HabitTracker
//
//  Created by Sebastián Kučera on 12.01.2026.
//

import SwiftUI
import AuthenticationServices

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @StateObject private var authManager = AuthenticationManager.shared
    @Environment(\.colorScheme) private var colorScheme

    @State private var showContent = false
    @State private var showButtons = false
    @State private var isSigningIn = false

    // Feature highlights
    private let features = [
        ("checkmark.circle.fill", "Track Daily Habits", "Build consistency with easy tracking"),
        ("flame.fill", "Streak Motivation", "Stay motivated with streak counters"),
        ("heart.fill", "Health Integration", "Sync with Apple Health automatically"),
        ("chart.bar.fill", "Visual Progress", "See your growth with beautiful stats")
    ]

    var body: some View {
        ZStack {
            // Background
            backgroundView

            // Content
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 80)

                // Logo and title
                headerSection
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : -30)

                Spacer()
                    .frame(height: 40)

                // Features
                featuresSection
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                Spacer()

                // Sign in buttons
                signInSection
                    .opacity(showButtons ? 1 : 0)
                    .offset(y: showButtons ? 0 : 30)

                Spacer()
                    .frame(height: 50)
            }
            .padding(.horizontal, 24)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                showContent = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.8)) {
                showButtons = true
            }
        }
    }

    // MARK: - Background

    private var backgroundView: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.06, blue: 0.18),
                    Color(red: 0.15, green: 0.10, blue: 0.28),
                    Color(red: 0.10, green: 0.08, blue: 0.22)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Accent blobs
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "#A855F7").opacity(0.4),
                            Color(hex: "#A855F7").opacity(0.0)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: -100, y: -200)
                .blur(radius: 60)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "#EC4899").opacity(0.3),
                            Color(hex: "#EC4899").opacity(0.0)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 180
                    )
                )
                .frame(width: 360, height: 360)
                .offset(x: 120, y: 300)
                .blur(radius: 50)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "#06B6D4").opacity(0.25),
                            Color(hex: "#06B6D4").opacity(0.0)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .offset(x: 80, y: -100)
                .blur(radius: 40)
        }
        .ignoresSafeArea()
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 20) {
            // Mascot
            Image("ProfileMascot")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .shadow(color: Color(hex: "#A855F7").opacity(0.5), radius: 30, x: 0, y: 10)

            // App name
            Text("Dotti")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(hex: "#A855F7"),
                            Color(hex: "#EC4899")
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: Color(hex: "#A855F7").opacity(0.5), radius: 20, x: 0, y: 0)

            // Tagline
            Text("Build better habits,\none day at a time")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(spacing: 16) {
            ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                featureRow(icon: feature.0, title: feature.1, subtitle: feature.2)
                    .opacity(showContent ? 1 : 0)
                    .offset(x: showContent ? 0 : -20)
                    .animation(.easeOut(duration: 0.5).delay(Double(index) * 0.1 + 0.5), value: showContent)
            }
        }
        .padding(.horizontal, 8)
    }

    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "#A855F7").opacity(0.3),
                                Color(hex: "#EC4899").opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "#A855F7"), Color(hex: "#EC4899")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - Sign In Section

    private var signInSection: some View {
        VStack(spacing: 16) {
            // Sign in with Apple button
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                isSigningIn = true
                authManager.handleSignInWithApple(result)

                // Check if sign in was successful
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if authManager.isSignedIn {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            hasCompletedOnboarding = true
                        }
                    }
                    isSigningIn = false
                }
            }
            .signInWithAppleButtonStyle(.white)
            .frame(height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(hex: "#A855F7").opacity(0.5),
                                Color(hex: "#EC4899").opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(color: Color(hex: "#A855F7").opacity(0.3), radius: 20, x: 0, y: 10)
            .disabled(isSigningIn)
            .opacity(isSigningIn ? 0.7 : 1)

            // Skip button
            Button {
                authManager.signInAsGuest()
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    hasCompletedOnboarding = true
                }
            } label: {
                Text("Continue without signing in")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .disabled(isSigningIn)
            .accessibilityLabel("Continue without signing in")
            .accessibilityHint("Double tap to skip sign in and continue as a guest")

            // Privacy note
            Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.4))
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
