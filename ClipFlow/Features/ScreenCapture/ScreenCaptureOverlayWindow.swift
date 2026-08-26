import AppKit
import SwiftUI

class ScreenCaptureOverlayWindow: NSWindow {
    
    private let onSelectionComplete: (CGRect) -> Void
    
    init(screen: NSScreen, onSelectionComplete: @escaping (CGRect) -> Void) {
        self.onSelectionComplete = onSelectionComplete
        
        super.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        
        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .screenSaver // High level to cover everything
        self.ignoresMouseEvents = false // We need mouse events
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isReleasedWhenClosed = false // Prevent double-free when removing from array
        
        let overlayView = ScreenCaptureOverlayView { [weak self] rect in
            self?.onSelectionComplete(rect)
        }
        
        self.contentView = NSHostingView(rootView: overlayView)
    }
    
    override var canBecomeKey: Bool {
        return true
    }
}
