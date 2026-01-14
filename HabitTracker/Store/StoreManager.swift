//
//  StoreManager.swift
//  HabitTracker
//
//  Created by Sebastián Kučera on 12.01.2026.
//

import Foundation
import StoreKit
import Combine

@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()

    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false
    @Published var isPremium = false

    private let productIDs: Set<String> = [
        "habittracker.premium.monthly",
        "habittracker.premium.yearly",
        "habittracker.premium.lifetime"
    ]

    static let maxFreeHabits = 5

    private var updateListenerTask: Task<Void, Error>?

    init() {
        updateListenerTask = listenForTransactions()
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            products = try await Product.products(for: productIDs)
                .sorted { $0.price < $1.price }
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchasedProducts()
            await transaction.finish()
            return transaction

        case .userCancelled:
            return nil

        case .pending:
            return nil

        @unknown default:
            return nil
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async throws {
        try await AppStore.sync()
        await updatePurchasedProducts()
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updatePurchasedProducts()
                    await transaction.finish()
                } catch {
                    print("Transaction failed verification: \(error)")
                }
            }
        }
    }

    // MARK: - Update Purchased Products

    func updatePurchasedProducts() async {
        var purchased: Set<String> = []

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                if transaction.revocationDate == nil {
                    purchased.insert(transaction.productID)
                }
            } catch {
                print("Failed to verify transaction: \(error)")
            }
        }

        self.purchasedProductIDs = purchased
        self.isPremium = !purchased.isEmpty
    }

    // MARK: - Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Helpers

    var monthlyProduct: Product? {
        products.first { $0.id == "habittracker.premium.monthly" }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == "habittracker.premium.yearly" }
    }

    var lifetimeProduct: Product? {
        products.first { $0.id == "habittracker.premium.lifetime" }
    }

    func canAddMoreHabits(currentCount: Int) -> Bool {
        return isPremium || currentCount < Self.maxFreeHabits
    }

    // MARK: - Debug (Development Only)

    #if DEBUG
    func debugTogglePremium() {
        isPremium.toggle()
    }
    #endif
}

// MARK: - Store Error

enum StoreError: LocalizedError {
    case verificationFailed
    case purchaseFailed
    case productNotFound

    var errorDescription: String? {
        switch self {
        case .verificationFailed: return "Transaction verification failed"
        case .purchaseFailed: return "Purchase could not be completed"
        case .productNotFound: return "Product not found"
        }
    }
}

// MARK: - Subscription Period Extension

extension Product.SubscriptionPeriod {
    var displayName: String {
        switch unit {
        case .day:
            return value == 7 ? "Weekly" : "\(value) Day\(value > 1 ? "s" : "")"
        case .week:
            return "\(value) Week\(value > 1 ? "s" : "")"
        case .month:
            return value == 1 ? "Monthly" : "\(value) Months"
        case .year:
            return value == 1 ? "Yearly" : "\(value) Years"
        @unknown default:
            return "Unknown"
        }
    }
}
