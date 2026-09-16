import Foundation
import StoreKit

// MARK: - StoreKitManager
// Manages In-App Purchases, StoreKit 2 transactions, and receipt entitlement synchronization
// for the official Apple Mac App Store release.

@MainActor
final class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()
    
    // Product ID configured in App Store Connect
    static let proLifetimeProductID = "com.clipflow.ClipFlow.pro.lifetime"
    
    @Published var products: [Product] = []
    @Published var isPurchasing: Bool = false
    @Published var isRestoring: Bool = false
    @Published var purchaseError: String? = nil
    @Published var showSuccessAlert: Bool = false
    
    var proProduct: Product? {
        products.first(where: { $0.id == Self.proLifetimeProductID })
    }
    
    var localizedPrice: String {
        proProduct?.displayPrice ?? "$29.99"
    }
    
    private var transactionListener: Task<Void, Error>?
    
    private init() {
        transactionListener = listenForTransactions()
        Task {
            await fetchProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    // MARK: - Fetch Products from App Store
    
    func fetchProducts() async {
        do {
            let fetched = try await Product.products(for: [Self.proLifetimeProductID])
            self.products = fetched
        } catch {
            print("StoreKit: Failed to fetch products: \(error)")
        }
    }
    
    // MARK: - Purchase Flow
    
    func purchasePro() async -> Bool {
        guard let product = proProduct else {
            // Attempt to re-fetch if not loaded yet
            await fetchProducts()
            guard let retryProduct = proProduct else {
                self.purchaseError = "Unable to connect to the App Store. Please try again."
                return false
            }
            return await executePurchase(product: retryProduct)
        }
        return await executePurchase(product: product)
    }
    
    private func executePurchase(product: Product) async -> Bool {
        self.isPurchasing = true
        self.purchaseError = nil
        defer { self.isPurchasing = false }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updatePurchasedProducts()
                await transaction.finish()
                self.showSuccessAlert = true
                return true
                
            case .userCancelled:
                return false
                
            case .pending:
                self.purchaseError = "Purchase is pending authorization from your Apple ID account."
                return false
                
            @unknown default:
                return false
            }
        } catch {
            self.purchaseError = error.localizedDescription
            return false
        }
    }
    
    // MARK: - Restore Purchases (Mandatory for Mac App Store)
    
    func restorePurchases() async {
        self.isRestoring = true
        self.purchaseError = nil
        defer { self.isRestoring = false }
        
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
        } catch {
            self.purchaseError = "Failed to restore purchases: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Transaction Verification & Entitlements
    
    func updatePurchasedProducts() async {
        var hasActiveEntitlement = false
        
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == Self.proLifetimeProductID && transaction.revocationDate == nil {
                    hasActiveEntitlement = true
                    await transaction.finish()
                }
            }
        }
        
        if hasActiveEntitlement {
            ProManager.shared.unlockProStoreKit()
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.networkError(URLError(.cannotDecodeContentData))
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Background Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await self.updatePurchasedProducts()
                    await transaction.finish()
                }
            }
        }
    }
}
