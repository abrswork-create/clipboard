import Foundation
import AppKit
import LocalAuthentication

// MARK: - PrivacyManager
// Coordinates Private Mode, App Exclusions, sensitive content policy, and biometric/passcode authentication.

@MainActor
final class PrivacyManager {
    static let shared = PrivacyManager()
    private init() {}
    
    var isAuthenticating: Bool = false
    
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
        return SensitiveDataDetector.containsSensitiveData(text)
    }
    
    // MARK: - Biometric & Password Authentication
    
    /// Requests Touch ID or Mac password authentication to reveal sensitive content.
    func authenticateUser(reason: String = "reveal sensitive clipboard content") async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            print("Device owner authentication unavailable: \(String(describing: error))")
            return false
        }
        
        isAuthenticating = true
        
        let success: Bool = await withCheckedContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { ok, authError in
                DispatchQueue.main.async {
                    if let authError = authError {
                        print("Authentication failed: \(authError.localizedDescription)")
                    }
                    continuation.resume(returning: ok)
                }
            }
        }
        
        // Small delay to allow macOS system auth UI to dismiss cleanly before re-enabling deactivation dismissal
        try? await Task.sleep(nanoseconds: 300_000_000)
        isAuthenticating = false
        NSApp.activate(ignoringOtherApps: true)
        
        return success
    }
}
