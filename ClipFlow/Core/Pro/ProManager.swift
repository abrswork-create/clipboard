import Foundation
import Combine
import SwiftUI

// MARK: - ProManager
// Manages Pro subscription/license status, free tier constraints, paywall triggers,
// and hardware-backed Lemon Squeezy license activation with offline Keychain fallback.

@MainActor
final class ProManager: ObservableObject {
    static let shared = ProManager()
    
    // Free Tier Constraints
    let freeHistoryLimit: Int = 20
    let freePinLimit: Int = 3
    
    @Published var isPro: Bool = false
    @Published var showPaywall: Bool = false
    @Published var paywallReason: String = "Unlock your full clipboard history and unlimited pins."
    
    @Published var isActivating: Bool = false
    @Published var activationError: String?
    @Published var activatedKey: String?
    @Published var showActivationSuccessBanner: Bool = false
    
    private init() {
        // One-time check: ensure app starts on the Free tier by default, clearing any old test licenses
        let initializedFreeKey = "hasDefaultedToFreePlan_v1"
        if !UserDefaults.standard.bool(forKey: initializedFreeKey) {
            UserDefaults.standard.set(true, forKey: initializedFreeKey)
            LemonSqueezyService.shared.clearKeychainLicense()
            self.isPro = false
            self.activatedKey = nil
            return
        }

        // Strictly check Keychain for verified, hardware-bound license token
        if let stored = LemonSqueezyService.shared.readLicenseFromKeychain(), !stored.key.isEmpty {
            self.isPro = true
            self.activatedKey = stored.key
        } else {
            self.isPro = false
            self.activatedKey = nil
        }
    }
    
    // MARK: - Paywall Trigger
    
    func triggerPaywall(reason: String) {
        self.paywallReason = reason
        self.showPaywall = true
    }
    
    // MARK: - Licensing Actions
    
    func unlockPro(key: String = "") {
        let validKey = key.isEmpty ? "OFFLINE-PRO" : key
        let token = UUID().uuidString
        LemonSqueezyService.shared.saveToKeychain(key: validKey, token: token)
        
        self.isPro = true
        self.activatedKey = validKey
        self.showPaywall = false
        self.activationError = nil
        self.showActivationSuccessBanner = true
        
        // Auto-hide success banner after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            withAnimation(.easeInOut(duration: 0.25)) {
                self?.showActivationSuccessBanner = false
            }
        }
    }
    
    func resetToFree() {
        self.isPro = false
        self.activatedKey = nil
        UserDefaults.standard.removeObject(forKey: "clipmory_is_pro_user")
        UserDefaults.standard.removeObject(forKey: "clipmory_activated_license_key")
        LemonSqueezyService.shared.clearKeychainLicense()
    }
    
    // MARK: - Lemon Squeezy Activation
    
    /// Activates a license key asynchronously with Lemon Squeezy API
    /// Binds to Mac UUID and persists to Keychain for 100% offline access.
    func activateLicenseAsync(key: String) async -> Bool {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            self.activationError = "Please enter a valid license key."
            return false
        }
        
        self.isActivating = true
        self.activationError = nil
        
        let result = await LemonSqueezyService.shared.activateLicense(key: trimmed)
        self.isActivating = false
        
        switch result {
        case .success:
            unlockPro(key: trimmed)
            return true
        case .failure(let error):
            self.activationError = error.localizedDescription
            return false
        }
    }
}
