import Foundation
import AppKit
import ApplicationServices
import CoreGraphics

// MARK: - PermissionManager
// Checks and requests macOS permissions required by Clipmory.

@MainActor
final class PermissionManager: ObservableObject {
    static let shared = PermissionManager()
    
    @Published var isAccessibilityGranted: Bool = false
    @Published var isScreenRecordingGranted: Bool = false
    
    private var timer: Timer?
    
    private init() {
        checkPermissions()
    }
    
    func checkPermissions() {
        let ax = AXIsProcessTrusted()
        let sr = CGPreflightScreenCaptureAccess()
        
        if isAccessibilityGranted != ax {
            isAccessibilityGranted = ax
        }
        if isScreenRecordingGranted != sr {
            isScreenRecordingGranted = sr
        }
    }
    
    func startMonitoring() {
        checkPermissions()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkPermissions()
            }
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        
        if trusted {
            isAccessibilityGranted = true
            return
        }
        
        openAccessibilitySettings()
    }
    
    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            if !NSWorkspace.shared.open(url) {
                if let fallback = URL(string: "x-apple.systempreferences:com.apple.preference.security") {
                    NSWorkspace.shared.open(fallback)
                }
            }
        }
    }
    
    func requestScreenRecording() {
        if CGPreflightScreenCaptureAccess() {
            isScreenRecordingGranted = true
            return
        }
        
        CGRequestScreenCaptureAccess()
        openScreenRecordingSettings()
    }
    
    func openScreenRecordingSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            if !NSWorkspace.shared.open(url) {
                if let fallback = URL(string: "x-apple.systempreferences:com.apple.preference.security") {
                    NSWorkspace.shared.open(fallback)
                }
            }
        }
    }
}
