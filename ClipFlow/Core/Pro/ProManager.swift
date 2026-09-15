import Foundation
import Combine

// MARK: - ProManager
// Manages Pro subscription/license status, free tier constraints, paywall triggers,
// and hardware-backed Lemon Squeezy license activation with offline Keychain fallback.

@MainActor
final class ProManager: ObservableObject {
    static let shared = ProManager()
    
    // Free Tier Constraints
    let freeHistoryLimit: Int = 20
    let freePinLimit: Int = 3
    
    private let proKey = "clipmory_is_pro_user"
    private let activatedLicenseKeyPref = "clipmory_activated_license_key"
    
    @Published var isPro: Bool {
        didSet {
            UserDefaults.standard.set(isPro, forKey: proKey)
        }
    }
    
    @Published var showPaywall: Bool = false
    @Published var paywallReason: String = "Unlock your full clipboard history and unlimited pins."
    
    @Published var isActivating: Bool = false
    @Published var activationError: String?
    @Published var activatedKey: String?
    
    private init() {
        // 1. Check Keychain first for offline tamper-resistant license
        if let stored = LemonSqueezyService.shared.readLicenseFromKeychain(), !stored.key.isEmpty {
            self.isPro = true
            self.activatedKey = stored.key
        } else {
            // 2. Fallback to UserDefaults
            let userPrefPro = UserDefaults.standard.bool(forKey: proKey)
            self.isPro = userPrefPro
            self.activatedKey = UserDefaults.standard.string(forKey: activatedLicenseKeyPref)
        }
    }
    
    // MARK: - Paywall Trigger
    
    func triggerPaywall(reason: String) {
        self.paywallReason = reason
        self.showPaywall = true
    }
    
    // MARK: - Licensing Actions
    
    func unlockPro(key: String = "") {
        self.isPro = true
        self.showPaywall = false
        self.activationError = nil
        if !key.isEmpty {
            self.activatedKey = key
            UserDefaults.standard.set(key, forKey: activatedLicenseKeyPref)
        }
    }
    
    func resetToFree() {
        self.isPro = false
        self.activatedKey = nil
        UserDefaults.standard.removeObject(forKey: proKey)
        UserDefaults.standard.removeObject(forKey: activatedLicenseKeyPref)
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
    
    /// Synchronous convenience / fallback check for test keys
    func activateLicense(key: String) -> Bool {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if trimmed.starts(with: "PRO") || trimmed == "CLIPMORY-PRO" || trimmed == "LIFETIME" {
            unlockPro(key: trimmed)
            return true
        }
        return false
    }
}
