import Foundation
import Combine

// MARK: - ProManager
// Manages Pro subscription/license status, free tier constraints, and paywall triggers.

@MainActor
final class ProManager: ObservableObject {
    static let shared = ProManager()
    
    // Free Tier Constraints
    let freeHistoryLimit: Int = 20
    let freePinLimit: Int = 3
    
    private let proKey = "clipmory_is_pro_user"
    
    @Published var isPro: Bool {
        didSet {
            UserDefaults.standard.set(isPro, forKey: proKey)
        }
    }
    
    @Published var showPaywall: Bool = false
    @Published var paywallReason: String = "Unlock your full clipboard history and unlimited pins."
    
    private init() {
        self.isPro = UserDefaults.standard.bool(forKey: proKey)
    }
    
    // MARK: - Paywall Trigger
    
    func triggerPaywall(reason: String) {
        self.paywallReason = reason
        self.showPaywall = true
    }
    
    // MARK: - Licensing Actions
    
    func unlockPro() {
        self.isPro = true
        self.showPaywall = false
    }
    
    func resetToFree() {
        self.isPro = false
    }
    
    func activateLicense(key: String) -> Bool {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        // Accept valid license format (e.g. PRO-... or TEST-PRO)
        if trimmed.starts(with: "PRO") || trimmed == "CLIPMORY-PRO" || trimmed == "LIFETIME" {
            unlockPro()
            return true
        }
        return false
    }
}
