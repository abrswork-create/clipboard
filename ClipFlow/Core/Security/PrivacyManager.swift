import Foundation

// MARK: - PrivacyManager
// Coordinates Private Mode, App Exclusions, and sensitive content policy.

final class PrivacyManager {
    static let shared = PrivacyManager()
    private init() {}
    
    func canRecord(sourceAppBundleId: String?) -> Bool {
        let settings = SettingsRepository.shared.load()
        
        // 1. Check if global Private Mode is enabled
        if settings.privateModeEnabled {
            return false
        }
        
        // 2. Check App Exclusions
        if let bundleId = sourceAppBundleId, settings.excludedBundleIdentifiers.contains(bundleId) {
            return false
        }
        
        return true
    }
}
