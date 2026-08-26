import AppKit
import CoreGraphics
import ApplicationServices

@MainActor
final class ScreenCaptureService {
    static let shared = ScreenCaptureService()
    
    private var overlayWindows: [NSWindow] = []
    
    private init() {}
    
    func startCapture() {
        // Preflight Screen Recording Permissions
        if !CGPreflightScreenCaptureAccess() {
            let granted = CGRequestScreenCaptureAccess()
            if !granted {
                showPermissionAlert()
                return
            }
        }
        
        showOverlays()
    }
    
    private func showOverlays() {
        guard overlayWindows.isEmpty else { return }
        
        // Force the app to become active so the first click immediately starts the selection
        // instead of just bringing the app to the foreground.
        NSApp.activate(ignoringOtherApps: true)
        
        for screen in NSScreen.screens {
            let window = ScreenCaptureOverlayWindow(screen: screen) { [weak self] selectedRect in
                self?.handleSelection(rect: selectedRect, on: screen)
            }
            overlayWindows.append(window)
            window.makeKeyAndOrderFront(nil)
        }
        
        // Hide cursor and maybe set a crosshair
        NSCursor.crosshair.push()
    }
    
    private func handleSelection(rect: CGRect, on screen: NSScreen) {
        // Defer teardown to the next run loop iteration to avoid crashing
        // while the SwiftUI drag gesture is still unwinding.
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Close all overlays immediately
            for window in self.overlayWindows {
                window.close()
            }
            self.overlayWindows.removeAll()
            NSCursor.pop()
            
            // If rect is essentially empty, cancel
            guard rect.width > 5 && rect.height > 5 else { return }
            
            // The overlay returns rect in the standard Cocoa (bottom-left) coordinate space relative to the screen.
            // `CGWindowListCreateImage` expects global CoreGraphics (top-left) coordinates.
            let globalRect = self.convertToCGCoordinateSpace(rect: rect, screen: screen)
            
            self.captureAndCopyToPasteboard(globalRect: globalRect)
        }
    }
    
    private func captureAndCopyToPasteboard(globalRect: CGRect) {
        // Wait a tiny bit for the overlay windows to fully disappear from screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard let cgImage = CGWindowListCreateImage(globalRect, .optionOnScreenOnly, kCGNullWindowID, .bestResolution) else {
                print("Failed to capture screen image.")
                return
            }
            
            let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
            
            // We want ClipFlow's monitor to pick this up, so we DO NOT use PasteService.willWriteToPasteboard
            // Wait, we need it to go to history, but not necessarily trigger an infinite loop if we paste it.
            // If we just write it to Pasteboard, ClipboardMonitor will pick it up automatically.
            
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.writeObjects([nsImage])
            
            print("Successfully wrote captured image to pasteboard.")
        }
    }
    
    private func convertToCGCoordinateSpace(rect: CGRect, screen: NSScreen) -> CGRect {
        // screen.frame is in global bottom-left coordinates.
        // rect is local to the screen, but its origin is relative to the screen's bottom-left.
        
        // Find global bottom-left coordinate
        let globalX = screen.frame.origin.x + rect.origin.x
        let globalY = screen.frame.origin.y + rect.origin.y
        
        // Convert to global top-left
        let primaryScreenHeight = NSScreen.screens[0].frame.height
        // In CG coords, Y=0 is top of primary screen, going down.
        // In Cocoa coords, Y=0 is bottom of primary screen, going up.
        let cgY = primaryScreenHeight - (globalY + rect.height)
        
        return CGRect(x: globalX, y: cgY, width: rect.width, height: rect.height)
    }
    
    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Screen Recording Permission Required"
        alert.informativeText = "ClipFlow needs screen recording access to capture the selected area. Please grant permission in System Settings > Privacy & Security > Screen Recording."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
