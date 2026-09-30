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
    private var authenticatedItemIDs: Set<UUID> = []
    
    func isItemAuthenticated(_ id: UUID) -> Bool {
        return authenticatedItemIDs.contains(id)
    }
    
    func markItemAuthenticated(_ id: UUID) {
        authenticatedItemIDs.insert(id)
    }
    
    func unmarkItemAuthenticated(_ id: UUID) {
        authenticatedItemIDs.remove(id)
    }
    
    func resetSessionAuth() {
        authenticatedItemIDs.removeAll()
    }
    
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
    
    /// Evaluates a string and optional source bundle ID to determine if it contains sensitive data like Passwords, API Keys, or Credit Cards.
    func containsSensitiveContent(_ text: String, sourceBundleId: String? = nil) -> Bool {
        let settings = SettingsRepository.shared.load()
        guard settings.sensitiveContentDetection else { return false }
        if let bundleId = sourceBundleId, ClipboardClassifier.isPasswordManagerBundleId(bundleId) {
            return true
        }
        return SensitiveDataDetector.containsSensitiveData(text)
    }
    
    // MARK: - Biometric & Password Authentication
    
    /// Requests Touch ID or Mac password authentication to access sensitive content or modify security settings.
    func authenticateUser(reason: String = "access sensitive clipboard content") async -> Bool {
        isAuthenticating = true
        
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            NSLog("[PrivacyManager] Device owner authentication unavailable: %@", String(describing: error))
            isAuthenticating = false
            return true
        }
        
        let previousKeyWindow = NSApp.keyWindow
        
        let success: Bool = await withCheckedContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { ok, authError in
                DispatchQueue.main.async {
                    if let authError = authError {
                        NSLog("[PrivacyManager] Authentication failed or cancelled: %@", authError.localizedDescription)
                    }
                    continuation.resume(returning: ok)
                }
            }
        }
        
        // Re-focus the previous key window or panel
        if let keyWin = previousKeyWindow, keyWin.isVisible {
            keyWin.makeKeyAndOrderFront(nil)
        } else if let win = NSApp.windows.first(where: { $0 is ClipboardPanel && $0.isVisible }) {
            win.makeKeyAndOrderFront(nil)
        }
        NSApp.activate(ignoringOtherApps: true)
        
        // Small delay to allow macOS system auth UI to dismiss cleanly before re-enabling deactivation dismissal
        try? await Task.sleep(nanoseconds: 400_000_000)
        isAuthenticating = false
        
        return success
    }
}
