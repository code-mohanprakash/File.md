// StoreKitService.swift
// FileFairy
//
// Stub — all features are free. isPremium is always true.
// StoreKit APIs are not called.

import StoreKit
import Observation

@Observable
final class StoreKitService {

    // MARK: - Product IDs (kept for source compatibility)

    enum ProductID: String, CaseIterable {
        case monthly = "com.filefairy.premium.monthly"
        case annual  = "com.filefairy.premium.annual"
    }

    // MARK: - State

    var products: [Product] = []
    /// Always true — every feature is available to every user.
    let isPremium: Bool = true
    var purchaseInProgress: Bool = false
    var errorMessage: String?

    // MARK: - Lifecycle (no-ops)

    func start() {}
    func stop() {}

    // MARK: - Fetch Products (no-op)

    @MainActor
    func fetchProducts() async {}

    // MARK: - Purchase (no-op, returns true)

    @MainActor
    func purchase(_ product: Product) async -> Bool { true }

    // MARK: - Restore (no-op)

    @MainActor
    func restore() async {}

    // MARK: - Helpers

    var monthlyProduct: Product? { nil }
    var annualProduct: Product? { nil }
    var annualSavingsPercent: Int { 0 }
}
