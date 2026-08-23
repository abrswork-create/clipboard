import AppKit
import Foundation

// MARK: - PasteService
// Writes a selected clipboard item back to NSPasteboard and triggers a paste action
// using accessibility APIs (CGEvent). Implemented in TASK 17.

enum PasteService {
    
    // Notifications used to tell ClipboardMonitor to ignore our own pasteboard writes
    static let willWriteToPasteboard = Notification.Name("ClipFlow.willWriteToPasteboard")
    static let didWriteToPasteboard  = Notification.Name("ClipFlow.didWriteToPasteboard")
    
    @MainActor
    static func paste(_ item: ClipboardItem) {
        // 1. Check for Accessibility Permissions
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let isTrusted = AXIsProcessTrustedWithOptions(options)
        
        guard isTrusted else {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Required"
            alert.informativeText = "ClipFlow needs Accessibility permissions to simulate the ⌘V keystroke for auto-pasting. Please enable it in System Settings > Privacy & Security > Accessibility."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Open System Settings")
            
            let response = alert.runModal()
            if response == .alertSecondButtonReturn {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                    NSWorkspace.shared.open(url)
                }
            }
            return
        }

        // 2. Tell monitor to ignore changes
        NotificationCenter.default.post(name: willWriteToPasteboard, object: nil)

        // 3. Write to pasteboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        if let text = item.text {
            pasteboard.setString(text, forType: .string)
        } else if item.type == .image, let imagePath = item.imagePath, let image = NSImage(contentsOfFile: imagePath) {
            pasteboard.writeObjects([image])
        } else {
            // Nothing to paste, re-enable monitor and exit
            NotificationCenter.default.post(name: didWriteToPasteboard, object: nil)
            return
        }
        
        // 4. Hide ClipFlow window to restore focus to the previous app
        NSApp.hide(nil)
        
        // 5. Fire Cmd+V
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            triggerCmdV()
            
            // 6. Re-enable monitor after a slight delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NotificationCenter.default.post(name: didWriteToPasteboard, object: nil)
            }
        }
    }
    
    // MARK: - CGEvent Helper
    
    private static func triggerCmdV() {
        let vKeyCode: CGKeyCode = 0x09 // 'v'
        
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }
        
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true)
        let keyUp   = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false)
        
        let cmdFlag = CGEventFlags.maskCommand
        keyDown?.flags = cmdFlag
        keyUp?.flags   = cmdFlag
        
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}
