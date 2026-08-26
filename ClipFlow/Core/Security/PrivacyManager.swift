import Foundation

// MARK: - PrivacyManager
// Coordinates Private Mode, App Exclusions, and sensitive content policy.

@MainActor
final class PrivacyManager {
    static let shared = PrivacyManager()
    private init() {}
    
    func canRecord(sourceAppBundleId: String?) -> Bool {
        let settings = SettingsRepository.shared.load()
        
        // 1. Check if global history recording is disabled
        if !settings.enableHistory {
            return false
        }
        
        // 2. Check App Exclusions
        if let bundleId = sourceAppBundleId, settings.excludedBundleIdentifiers.contains(bundleId) {
            return false
        }
        
        return true
    }
    
    // MARK: - Sensitive Content Detection
    
    /// Evaluates a string to determine if it contains sensitive data like Credit Cards, API Keys, or Private Keys.
    func containsSensitiveContent(_ text: String) -> Bool {
        let settings = SettingsRepository.shared.load()
        guard settings.sensitiveContentDetection else { return false }
        
        let patterns = [
            // Credit Cards (Visa, Mastercard, Amex, Discover)
            "(?:4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14}|3[47][0-9]{13}|6(?:011|5[0-9]{2})[0-9]{12})",
            
            // AWS Keys
            "(?:A3T[A-Z0-9]|AKIA|AGPA|AIDA|AROA|AIPA|ANPA|ANVA|ASIA)[A-Z0-9]{16}",
            
            // Private Keys (RSA, DSA, EC, OPENSSH)
            "-----BEGIN (?:RSA|DSA|EC|OPENSSH|PRIVATE) KEY-----",
            
            // Generic Bearer Tokens / API Keys (high entropy or specific prefixes)
            "(?:Bearer\\s+[A-Za-z0-9\\-\\._~\\+/]+=*)",
            "sk_live_[0-9a-zA-Z]{24}", // Stripe Secret
            "ghp_[0-9a-zA-Z]{36}"      // GitHub Personal Access Token
        ]
        
        for pattern in patterns {
            if text.range(of: pattern, options: .regularExpression) != nil {
                return true
            }
        }
        
        return false
    }
}
