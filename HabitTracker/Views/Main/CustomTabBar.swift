//
//  CustomTabBar.swift
//  HabitTracker
//
//  Created by Sebastián Kučera on 13.01.2026.
//

import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    let onAddTapped: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Home Tab
            TabBarButton(
                icon: selectedTab == 0 ? "house.fill" : "house",
                title: "Home",
                isSelected: selectedTab == 0
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = 0
                }
            }

            Spacer()

            // Center Add Button (Instagram-style)
            CenterAddButton(action: onAddTapped)
                .offset(y: -20)

            Spacer()

            // Settings Tab
            TabBarButton(
                icon: selectedTab == 1 ? "gearshape.fill" : "gearshape",
                title: "Settings",
                isSelected: selectedTab == 1
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = 1
                }
            }
        }
        .padding(.horizontal, 50)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(
            Rectangle()
                .fill(AppTheme.Colors.cardBackground)
                .ignoresSafeArea(edges: .bottom)
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: -5)
        )
    }
}

// MARK: - Tab Bar Button

struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)

                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundStyle(isSelected ? AppTheme.Colors.accentPrimary : AppTheme.Colors.textTertiary)
            .frame(width: 60)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Center Add Button

struct CenterAddButton: View {
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            ZStack {
                // Outer glow
                Circle()
                    .fill(AppTheme.Gradients.buttonGradient)
                    .frame(width: 64, height: 64)
                    .blur(radius: 15)
                    .opacity(0.6)

                // Main button
                Circle()
                    .fill(AppTheme.Gradients.buttonGradient)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                    )
                    .shadow(color: AppTheme.Colors.accentPrimary.opacity(0.5), radius: 12, x: 0, y: 6)
            }
            .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(.plain)
        .pressEvents {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = true
            }
        } onRelease: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = false
            }
        }
    }
}

// MARK: - Press Events Modifier

struct PressEventsModifier: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress() }
                    .onEnded { _ in onRelease() }
            )
    }
}

extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEventsModifier(onPress: onPress, onRelease: onRelease))
    }
}

#Preview {
    ZStack {
        AppTheme.Colors.background.ignoresSafeArea()

        VStack {
            Spacer()
            CustomTabBar(selectedTab: .constant(0)) {
                print("Add tapped")
            }
        }
    }
}
