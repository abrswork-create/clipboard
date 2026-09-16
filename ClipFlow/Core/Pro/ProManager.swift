import Foundation
import Combine
import SwiftUI

// MARK: - ProManager
// Manages Pro subscription/license status, hardware-bound 7-Day Free Trial,
// and hardware-backed Lemon Squeezy license activation.

@MainActor
final class ProManager: ObservableObject {
    static let shared = ProManager()
    
    // Trial duration: 7 Days
    let trialDurationDays: Int = 7
    private let trialDurationSeconds: TimeInterval = 7 * 86400
    
    // MARK: Published Licensing & Trial States
    
    @Published var isPro: Bool = false
    @Published var isTrialActive: Bool = false
    @Published var isTrialExpired: Bool = false
    @Published var trialDaysRemaining: Int = 7
    @Published var hasFullAccess: Bool = true
    
    @Published var showPaywall: Bool = false
    @Published var paywallReason: String = "Unlock your full clipboard history and unlimited pins."
    
    @Published var isActivating: Bool = false
    @Published var activationError: String?
    @Published var activatedKey: String?
    @Published var showActivationSuccessBanner: Bool = false
    
    private init() {
#if APP_STORE
        // In Mac App Store build, entitlements are managed by StoreKit 2
        self.isPro = false
        self.activatedKey = nil
#else
        // 1. Check local hardware-bound Pro license token (Web/Lemon Squeezy)
        if let stored = LemonSqueezyService.shared.readLicenseFromKeychain(), !stored.key.isEmpty {
            self.isPro = true
            self.activatedKey = stored.key
        } else {
            self.isPro = false
            self.activatedKey = nil
        }
#endif
        
        // 2. Refresh 7-Day Free Trial status linked to permanent Mac hardware UUID
        refreshTrialStatus()
    }
    
    // MARK: - Hardware-Bound Trial Verification

    private var trialFileURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("ClipFlow", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent(".trial_record")
    }
    
    /// Evaluates or initializes the 7-Day Free Trial tied permanently to the Mac's hardware UUID.
    func refreshTrialStatus() {
        let macUUID = LemonSqueezyService.shared.getMacUUID()
        let trialStartDate = getOrCreateTrialRecord(uuid: macUUID)
        
        let elapsed = Date().timeIntervalSince(trialStartDate)
        
        if elapsed < 0 {
            // System clock manipulation detected: lock trial
            self.isTrialActive = false
            self.isTrialExpired = true
            self.trialDaysRemaining = 0
        } else if elapsed < trialDurationSeconds {
            self.isTrialActive = true
            self.isTrialExpired = false
            let remainingSecs = trialDurationSeconds - elapsed
            self.trialDaysRemaining = max(1, Int(ceil(remainingSecs / 86400)))
        } else {
            self.isTrialActive = false
            self.isTrialExpired = true
            self.trialDaysRemaining = 0
        }
        
        // Full access is granted if user is Pro OR within the 7-day free trial
        self.hasFullAccess = self.isPro || self.isTrialActive
    }
    
    private func getOrCreateTrialRecord(uuid: String) -> Date {
        // 1. Read hardware-encrypted trial file
        let file = trialFileURL
        if FileManager.default.fileExists(atPath: file.path),
           let encryptedBase64 = try? String(contentsOf: file, encoding: .utf8),
           let decryptedStr = EncryptionService.shared.decrypt(base64: encryptedBase64) {
            let parts = decryptedStr.components(separatedBy: ":")
            if parts.count >= 2, let timestamp = Double(parts[1]) {
                return Date(timeIntervalSince1970: timestamp)
            }
        }
        
        // 2. If no valid record exists, initialize first-run trial timestamp now
        let now = Date()
        let payload = "\(uuid):\(now.timeIntervalSince1970)"
        if let encrypted = EncryptionService.shared.encrypt(text: payload) {
            try? encrypted.write(to: file, atomically: true, encoding: .utf8)
            try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: file.path)
        }
        
        return now
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
        self.hasFullAccess = true
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
    
    /// Unlocks Pro directly from Apple StoreKit 2 transaction verification
    func unlockProStoreKit() {
        self.isPro = true
        self.activatedKey = "APP_STORE_PURCHASE"
        self.hasFullAccess = true
        self.showPaywall = false
        self.activationError = nil
        self.showActivationSuccessBanner = true
        
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
        refreshTrialStatus()
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
