//
//  HabitStackView.swift
//  HabitTracker
//
//  Created by Claude on 14.01.2026.
//

import SwiftUI
import SwiftData

// MARK: - Stacks List View

struct StacksView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: \HabitStack.createdAt, order: .reverse) private var stacks: [HabitStack]
    @Query(sort: \Habit.createdAt, order: .reverse) private var habits: [Habit]

    @State private var showingCreateStack = false
    @State private var selectedStack: HabitStack?
    @State private var selectedTemplate: StackTemplate?
    @State private var previewTemplate: StackTemplate?

    private var primaryText: Color {
        colorScheme == .dark ? .white : Color(red: 0.2, green: 0.15, blue: 0.3)
    }

    private var secondaryText: Color {
        colorScheme == .dark ? .white.opacity(0.7) : Color(red: 0.4, green: 0.35, blue: 0.5)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                FloatingClouds()

                ScrollView {
                    VStack(spacing: 20) {
                        if stacks.isEmpty {
                            emptyState
                        } else {
                            // Active stacks
                            ForEach(stacks.filter { $0.isActive }) { stack in
                                StackCard(
                                    stack: stack,
                                    habits: habits,
                                    onTap: { selectedStack = stack },
                                    onEdit: { selectedStack = stack }
                                )
                            }
                        }

                        // Templates section
                        templatesSection
                    }
                    .padding(20)
                    .padding(.bottom, 60)
                }
            }
            .navigationTitle("Habit Chains")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateStack = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color(hex: "#A855F7"))
                    }
                }
            }
            .sheet(isPresented: $showingCreateStack) {
                HabitStackBuilderView()
            }
            .sheet(item: $selectedStack) { stack in
                HabitStackBuilderView(existingStack: stack)
            }
            .sheet(item: $selectedTemplate) { template in
                HabitStackBuilderView(template: template)
            }
            .sheet(item: $previewTemplate) { template in
                TemplatePreviewView(
                    template: template,
                    onAdd: {
                        previewTemplate = nil
                        createFromTemplate(template)
                    },
                    onCustomize: {
                        previewTemplate = nil
                        selectedTemplate = template
                    }
                )
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#A855F7").opacity(0.2))
                    .frame(width: 100, height: 100)
                    .blur(radius: 20)

                Image(systemName: "link.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(Color(hex: "#A855F7"))
            }

            Text("No Habit Chains Yet")
                .font(.title3.weight(.bold))
                .foregroundStyle(primaryText)

            Text("Chain habits together to build powerful routines")
                .font(.subheadline)
                .foregroundStyle(secondaryText)
                .multilineTextAlignment(.center)

            Button {
                showingCreateStack = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Your First Chain")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(Color(hex: "#A855F7"))
                )
            }
            .padding(.top, 8)
        }
        .padding(.vertical, 40)
    }

    private var templatesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Pre-built Chains")
                    .font(.headline)
                    .foregroundStyle(primaryText)

                Spacer()

                Text("Tap to preview")
                    .font(.caption)
                    .foregroundStyle(secondaryText)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(StackTemplate.templates) { template in
                    StackTemplateCard(
                        template: template,
                        onPreview: {
                            previewTemplate = template
                        }
                    )
                }
            }
        }
    }

    private func createFromTemplate(_ template: StackTemplate) {
        // Create stack with all habits in one tap
        _ = HabitStackManager.shared.createFromTemplate(template, in: modelContext)
        HapticManager.shared.success()
    }
}

// MARK: - Stack Card

struct StackCard: View {
    let stack: HabitStack
    let habits: [Habit]
    let onTap: () -> Void
    let onEdit: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var stackManager = HabitStackManager.shared

    private var progress: StackProgress {
        stackManager.getProgress(for: stack, habits: habits)
    }

    private var primaryText: Color {
        colorScheme == .dark ? .white : Color(red: 0.2, green: 0.15, blue: 0.3)
    }

    private var secondaryText: Color {
        colorScheme == .dark ? .white.opacity(0.7) : Color(red: 0.4, green: 0.35, blue: 0.5)
    }

    private var tertiaryText: Color {
        colorScheme == .dark ? .white.opacity(0.5) : Color(red: 0.5, green: 0.45, blue: 0.6)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                ZStack {
                    Circle()
                        .fill(Color(hex: stack.color).opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: stack.icon)
                        .font(.title3)
                        .foregroundStyle(Color(hex: stack.color))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(stack.name)
                        .font(.headline)
                        .foregroundStyle(primaryText)

                    Text("\(progress.completedCount)/\(progress.totalCount) completed")
                        .font(.caption)
                        .foregroundStyle(secondaryText)
                }

                Spacer()

                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color(hex: stack.color).opacity(0.2), lineWidth: 4)
                        .frame(width: 44, height: 44)

                    Circle()
                        .trim(from: 0, to: progress.progress)
                        .stroke(Color(hex: stack.color), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(-90))

                    if progress.isComplete {
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color(hex: stack.color))
                    } else {
                        Text("\(Int(progress.progress * 100))%")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color(hex: stack.color))
                    }
                }
            }

            // Chain visualization
            chainVisualization

            // Current habit highlight
            if let current = progress.currentItem {
                currentHabitSection(current)
            } else if progress.isComplete {
                completedBanner
            }
        }
        .padding(16)
        .liquidGlass(cornerRadius: 20)
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("Edit Chain", systemImage: "pencil")
            }

            Button(role: .destructive) {
                deleteStack()
            } label: {
                Label("Delete Chain", systemImage: "trash")
            }
        }
    }

    private var chainVisualization: some View {
        HStack(spacing: 4) {
            ForEach(Array(progress.items.enumerated()), id: \.element.id) { index, item in
                // Habit dot
                ZStack {
                    Circle()
                        .fill(item.isCompleted
                              ? Color(hex: item.habit.color)
                              : Color(hex: item.habit.color).opacity(0.3))
                        .frame(width: 28, height: 28)

                    if item.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                    } else {
                        Image(systemName: item.habit.icon)
                            .font(.caption2)
                            .foregroundStyle(Color(hex: item.habit.color))
                    }
                }

                // Connector
                if index < progress.items.count - 1 {
                    Rectangle()
                        .fill(progress.items[index + 1].isCompleted || item.isCompleted
                              ? Color(hex: stack.color)
                              : Color(hex: stack.color).opacity(0.3))
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private func currentHabitSection(_ current: StackItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.right.circle.fill")
                .font(.subheadline)
                .foregroundStyle(Color(hex: current.habit.color))

            Text("Next: \(current.habit.name)")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(primaryText)

            Spacer()

            Button {
                completeHabit(current.habit)
            } label: {
                Text("Complete")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color(hex: current.habit.color))
                    )
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: current.habit.color).opacity(0.1))
        )
    }

    private var completedBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.headline)
                .foregroundStyle(.green)

            Text("Chain Complete!")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.green)

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.15))
        )
    }

    private func completeHabit(_ habit: Habit) {
        // Add completion for today
        let completion = HabitCompletion(date: Date(), value: 1)
        if habit.completions == nil { habit.completions = [] }
        habit.completions?.append(completion)
        HapticManager.shared.habitCompleted()
    }

    private func deleteStack() {
        stackManager.deleteStack(stack, habits: habits, in: modelContext)
    }
}

// MARK: - Stack Template Card

struct StackTemplateCard: View {
    let template: StackTemplate
    let onPreview: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var primaryText: Color {
        colorScheme == .dark ? .white : Color(red: 0.2, green: 0.15, blue: 0.3)
    }

    private var secondaryText: Color {
        colorScheme == .dark ? .white.opacity(0.7) : Color(red: 0.4, green: 0.35, blue: 0.5)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color(hex: template.color).opacity(0.2))
                        .frame(width: 36, height: 36)

                    Image(systemName: template.icon)
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: template.color))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(primaryText)
                        .lineLimit(1)

                    Text("\(template.habits.count) habits")
                        .font(.caption2)
                        .foregroundStyle(Color(hex: template.color))
                }

                Spacer()
            }

            // Description
            Text(template.description)
                .font(.caption)
                .foregroundStyle(secondaryText)
                .lineLimit(2)

            Spacer(minLength: 0)

            // Habit preview (icons)
            HStack(spacing: -6) {
                ForEach(template.habits.prefix(4), id: \.name) { habit in
                    ZStack {
                        Circle()
                            .fill(Color(hex: habit.color))
                            .frame(width: 24, height: 24)

                        Image(systemName: habit.icon)
                            .font(.system(size: 10))
                            .foregroundStyle(.white)
                    }
                }

                if template.habits.count > 4 {
                    ZStack {
                        Circle()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.1))
                            .frame(width: 24, height: 24)

                        Text("+\(template.habits.count - 4)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(secondaryText)
                    }
                }

                Spacer()
            }

            // Preview button
            Button(action: onPreview) {
                HStack {
                    Image(systemName: "eye.fill")
                        .font(.caption)
                    Text("Preview")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color(hex: template.color))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .frame(height: 180)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.7))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: template.color).opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Compact Stack Card (for HomeView)

struct CompactStackCard: View {
    let stack: HabitStack
    let habits: [Habit]
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var stackManager = HabitStackManager.shared

    private var progress: StackProgress {
        stackManager.getProgress(for: stack, habits: habits)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon with progress ring
                ZStack {
                    Circle()
                        .stroke(Color(hex: stack.color).opacity(0.2), lineWidth: 3)
                        .frame(width: 40, height: 40)

                    Circle()
                        .trim(from: 0, to: progress.progress)
                        .stroke(Color(hex: stack.color), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 40, height: 40)
                        .rotationEffect(.degrees(-90))

                    Image(systemName: stack.icon)
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: stack.color))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(stack.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(colorScheme == .dark ? .white : Color(red: 0.2, green: 0.15, blue: 0.3))

                    if let current = progress.currentItem {
                        Text("Next: \(current.habit.name)")
                            .font(.caption)
                            .foregroundStyle(colorScheme == .dark ? .white.opacity(0.7) : Color(red: 0.4, green: 0.35, blue: 0.5))
                    } else if progress.isComplete {
                        Text("Complete!")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.green)
                    }
                }

                Spacer()

                Text("\(progress.completedCount)/\(progress.totalCount)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(hex: stack.color))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.5))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Template Preview View

struct TemplatePreviewView: View {
    let template: StackTemplate
    let onAdd: () -> Void
    let onCustomize: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var store = StoreManager.shared

    @State private var showingPaywall = false

    private var primaryText: Color {
        colorScheme == .dark ? .white : Color(red: 0.2, green: 0.15, blue: 0.3)
    }

    private var secondaryText: Color {
        colorScheme == .dark ? .white.opacity(0.7) : Color(red: 0.4, green: 0.35, blue: 0.5)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                FloatingClouds()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: template.color).opacity(0.2))
                                    .frame(width: 80, height: 80)

                                Image(systemName: template.icon)
                                    .font(.system(size: 36))
                                    .foregroundStyle(Color(hex: template.color))
                            }

                            Text(template.name)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(primaryText)

                            Text(template.description)
                                .font(.subheadline)
                                .foregroundStyle(secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)

                        // Habits list
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Included Habits")
                                .font(.headline)
                                .foregroundStyle(primaryText)

                            VStack(spacing: 0) {
                                ForEach(Array(template.habits.enumerated()), id: \.element.name) { index, habit in
                                    HStack(spacing: 12) {
                                        // Order number
                                        ZStack {
                                            Circle()
                                                .fill(Color(hex: template.color))
                                                .frame(width: 28, height: 28)

                                            Text("\(index + 1)")
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(.white)
                                        }

                                        // Habit icon
                                        ZStack {
                                            Circle()
                                                .fill(Color(hex: habit.color).opacity(0.2))
                                                .frame(width: 40, height: 40)

                                            Image(systemName: habit.icon)
                                                .font(.body)
                                                .foregroundStyle(Color(hex: habit.color))
                                        }

                                        Text(habit.name)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(primaryText)

                                        Spacer()
                                    }
                                    .padding(.vertical, 10)

                                    if index < template.habits.count - 1 {
                                        HStack {
                                            Rectangle()
                                                .fill(Color(hex: template.color).opacity(0.3))
                                                .frame(width: 2, height: 16)
                                                .padding(.leading, 13)
                                            Spacer()
                                        }
                                    }
                                }
                            }
                            .padding(16)
                            .liquidGlass(cornerRadius: 16)
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(20)
                }

                // Bottom buttons
                VStack {
                    Spacer()

                    VStack(spacing: 12) {
                        Button {
                            if store.isPremium {
                                onAdd()
                            } else {
                                showingPaywall = true
                            }
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Chain")
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color(hex: template.color))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        Button {
                            if store.isPremium {
                                onCustomize()
                            } else {
                                showingPaywall = true
                            }
                        } label: {
                            HStack {
                                Image(systemName: "slider.horizontal.3")
                                Text("Customize")
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color(hex: template.color))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color(hex: template.color).opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(20)
                    .background(
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .ignoresSafeArea()
                    )
                }
            }
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(secondaryText)
                    }
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }
}

#Preview {
    StacksView()
        .modelContainer(for: [Habit.self, HabitStack.self], inMemory: true)
}
