// PremiumViewModel.swift
// FileFairy

import SwiftUI
import StoreKit
import Observation

@Observable
final class PremiumViewModel {

    // MARK: - State

    var selectedPlan: StoreKitService.ProductID = .annual
    var isLoading = false
    var showSuccess = false
    var errorMessage: String?

    private let storeService: StoreKitService

    // MARK: - Init

    init(storeService: StoreKitService = StoreKitService()) {
        self.storeService = storeService
    }

    // MARK: - Computed

    var products: [Product] { storeService.products }
    var isPremium: Bool { storeService.isPremium }
    var purchaseInProgress: Bool { storeService.purchaseInProgress }
    var annualSavingsPercent: Int { storeService.annualSavingsPercent }

    var monthlyProduct: Product? { storeService.monthlyProduct }
    var annualProduct: Product? { storeService.annualProduct }

    var selectedProduct: Product? {
        switch selectedPlan {
        case .monthly: return monthlyProduct
        case .annual:  return annualProduct
        }
    }

    // MARK: - Premium Features

    static let features: [(icon: String, title: String, description: String)] = [
        ("scissors", "PDF Split", "Extract specific pages from any PDF"),
        ("arrow.down.doc.fill", "PDF Compress", "Reduce PDF file size with quality options"),
        ("arrow.up.left.and.arrow.down.right", "Image Resize", "Resize images to custom dimensions"),
        ("rectangle.stack.fill", "Unlimited PDF Merge", "Merge any number of PDFs"),
        ("square.stack.3d.up.fill", "Batch Operations", "Convert multiple files at once"),
        ("sparkles", "Priority Support", "Get help when you need it"),
    ]

    // MARK: - Actions

    @MainActor
    func loadProducts() async {
        isLoading = true
        await storeService.fetchProducts()
        isLoading = false
    }

    @MainActor
    func purchase() async {
        guard let product = selectedProduct else { return }
        errorMessage = nil

        let success = await storeService.purchase(product)
        if success {
            showSuccess = true
        } else if let msg = storeService.errorMessage {
            errorMessage = msg
        }
    }

    @MainActor
    func restore() async {
        errorMessage = nil
        await storeService.restore()
        if storeService.isPremium {
            showSuccess = true
        } else if let msg = storeService.errorMessage {
            errorMessage = msg
        } else {
            errorMessage = "No active subscription found"
        }
    }
}
