//
//  HealthKitManager.swift
//  HabitTracker
//
//  Created by Sebastián Kučera on 13.01.2026.
//

import Foundation
import HealthKit
import Combine

@MainActor
class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()

    @Published var isAuthorized = false
    @Published var authorizationStatus: [HKObjectType: HKAuthorizationStatus] = [:]

    // HealthKit types we need
    static let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
    static let waterType = HKObjectType.quantityType(forIdentifier: .dietaryWater)!
    static let caloriesType = HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!

    private let readTypes: Set<HKObjectType> = [
        sleepType,
        waterType,
        caloriesType
    ]

    private init() {
        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Availability

    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Authorization

    func checkAuthorizationStatus() async {
        guard isHealthKitAvailable else {
            isAuthorized = false
            return
        }

        var statuses: [HKObjectType: HKAuthorizationStatus] = [:]
        for type in readTypes {
            statuses[type] = healthStore.authorizationStatus(for: type)
        }
        self.authorizationStatus = statuses

        // Consider authorized if at least one type is authorized
        self.isAuthorized = statuses.values.contains { $0 == .sharingAuthorized }
    }

    func requestAuthorization() async throws {
        guard isHealthKitAvailable else {
            throw HealthKitError.notAvailable
        }

        // Request authorization from HealthKit
        try await healthStore.requestAuthorization(toShare: [], read: readTypes)

        // Mark that we've requested authorization for these types
        // (HealthKit doesn't reveal actual read permission status for privacy)
        markAuthorizationRequested(for: readTypes)

        await checkAuthorizationStatus()
    }

    /// Check if authorization was already requested for a specific habit type.
    /// For read-only access, HealthKit doesn't reveal the actual authorization status,
    /// so we check if we need to request authorization (if not, we've already asked).
    func isAuthorized(for habitType: HabitType) -> Bool {
        switch habitType {
        case .healthKitSleep:
            return hasRequestedAuthorization(for: Self.sleepType)
        case .healthKitWater:
            return hasRequestedAuthorization(for: Self.waterType)
        case .healthKitCalories:
            return hasRequestedAuthorization(for: Self.caloriesType)
        case .manual:
            return true
        }
    }

    /// Check if we've already requested authorization for a specific type.
    /// Uses statusForAuthorizationRequest which tells us if we need to show the prompt.
    private func hasRequestedAuthorization(for type: HKObjectType) -> Bool {
        // Check if we've stored that authorization was requested
        let key = "healthkit.authorized.\(type.identifier)"
        return UserDefaults.standard.bool(forKey: key)
    }

    /// Mark that we've requested authorization for a specific type
    private func markAuthorizationRequested(for types: Set<HKObjectType>) {
        for type in types {
            let key = "healthkit.authorized.\(type.identifier)"
            UserDefaults.standard.set(true, forKey: key)
        }
    }

    // MARK: - Fetch Sleep Data

    func fetchSleepData(for date: Date) async throws -> TimeInterval {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            throw HealthKitError.queryFailed
        }

        // For sleep, we want to capture sleep that ENDED on this day
        // (e.g., sleep from 23:00 yesterday to 07:00 today should count for today)
        // Look back from 6 PM previous day to capture overnight sleep
        guard let sleepWindowStart = calendar.date(byAdding: .hour, value: -6, to: startOfDay) else {
            throw HealthKitError.queryFailed
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: sleepWindowStart,
            end: endOfDay,
            options: .strictEndDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: Self.sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let categorySamples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: 0)
                    return
                }

                // Sum up asleep time (all sleep stages)
                // Only count sleep sessions that END on this day (woke up today)
                let totalSleep = categorySamples
                    .filter { sample in
                        let value = sample.value
                        let isAsleep = value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                               value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                               value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                               value == HKCategoryValueSleepAnalysis.asleepREM.rawValue
                        // Only include sleep that ended on the target day
                        let endsOnTargetDay = sample.endDate >= startOfDay && sample.endDate < endOfDay
                        return isAsleep && endsOnTargetDay
                    }
                    .reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }

                continuation.resume(returning: totalSleep)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Fetch Water Data

    func fetchWaterData(for date: Date) async throws -> Double {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            throw HealthKitError.queryFailed
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: Self.waterType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let ml = statistics?.sumQuantity()?.doubleValue(for: .literUnit(with: .milli)) ?? 0
                continuation.resume(returning: ml)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Fetch Calories Data

    func fetchCaloriesData(for date: Date) async throws -> Double {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            throw HealthKitError.queryFailed
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: Self.caloriesType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let kcal = statistics?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                continuation.resume(returning: kcal)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Sync Habit from HealthKit

    func syncHabitFromHealthKit(_ habit: Habit, for date: Date = Date()) async throws -> Double? {
        guard habit.dataSource == .healthKit else { return nil }

        switch habit.habitType {
        case .healthKitSleep:
            let seconds = try await fetchSleepData(for: date)
            return seconds / 3600 // Convert to hours

        case .healthKitWater:
            return try await fetchWaterData(for: date)

        case .healthKitCalories:
            return try await fetchCaloriesData(for: date)

        case .manual:
            return nil
        }
    }
}

// MARK: - Errors

enum HealthKitError: LocalizedError {
    case notAvailable
    case notAuthorized
    case queryFailed

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .notAuthorized:
            return "Please authorize HealthKit access in Settings"
        case .queryFailed:
            return "Failed to fetch health data"
        }
    }
}
