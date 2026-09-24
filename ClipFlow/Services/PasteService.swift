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
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        let isTrusted = AXIsProcessTrustedWithOptions(options)
        
        guard isTrusted else {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Required"
            alert.informativeText = "Clipmory needs Accessibility permissions to simulate the ⌘V keystroke for auto-pasting. Please enable it in System Settings > Privacy & Security > Accessibility."
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
        } else if item.type == .image, let imagePath = item.imagePath {
            let fileURL = URL(fileURLWithPath: imagePath)
            if fileURL.pathExtension.lowercased() == "gif", let gifData = try? Data(contentsOf: fileURL) {
                pasteboard.setData(gifData, forType: NSPasteboard.PasteboardType("com.compuserve.gif"))
                if let image = NSImage(data: gifData), let tiff = image.tiffRepresentation {
                    pasteboard.setData(tiff, forType: .tiff)
                }
                pasteboard.writeObjects([fileURL as NSURL])
            } else if let image = NSImage(contentsOfFile: imagePath) {
                pasteboard.writeObjects([image])
            } else {
                NotificationCenter.default.post(name: didWriteToPasteboard, object: nil)
                return
            }
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
    
    @MainActor
    static func paste(items: [ClipboardItem], textSeparator: String = "\n") {
        guard !items.isEmpty else { return }
        if items.count == 1, let single = items.first {
            paste(single)
            return
        }

        // 1. Check for Accessibility Permissions
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        let isTrusted = AXIsProcessTrustedWithOptions(options)
        
        guard isTrusted else {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Required"
            alert.informativeText = "Clipmory needs Accessibility permissions to simulate the ⌘V keystroke for auto-pasting. Please enable it in System Settings > Privacy & Security > Accessibility."
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
        guard writeToPasteboard(items, textSeparator: textSeparator) else {
            NotificationCenter.default.post(name: didWriteToPasteboard, object: nil)
            return
        }

        // 4. Hide Clipmory window to restore focus to the previous app
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

    @MainActor
    @discardableResult
    static func copy(items: [ClipboardItem], textSeparator: String = "\n") -> Bool {
        guard !items.isEmpty else { return false }
        NotificationCenter.default.post(name: willWriteToPasteboard, object: nil)
        let success = writeToPasteboard(items, textSeparator: textSeparator)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NotificationCenter.default.post(name: didWriteToPasteboard, object: nil)
        }
        return success
    }

    @MainActor
    private static func writeToPasteboard(_ items: [ClipboardItem], textSeparator: String) -> Bool {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        let imageItems = items.filter { $0.type == .image || $0.type == .file }
        let textItems = items.filter { $0.text != nil && $0.type != .image }

        if !imageItems.isEmpty && textItems.isEmpty {
            var urls: [NSURL] = []
            var nsImages: [NSImage] = []

            for item in imageItems {
                if let path = item.imagePath ?? item.filePath {
                    let fileURL = URL(fileURLWithPath: path)
                    if FileManager.default.fileExists(atPath: fileURL.path) {
                        urls.append(fileURL as NSURL)
                    }
                    if let img = NSImage(contentsOfFile: path) {
                        nsImages.append(img)
                    }
                }
            }

            if !urls.isEmpty {
                pasteboard.writeObjects(urls)
                return true
            } else if !nsImages.isEmpty {
                pasteboard.writeObjects(nsImages)
                return true
            }
            return false
        } else {
            var textParts: [String] = []
            for item in items {
                if let text = item.text, !text.isEmpty {
                    textParts.append(text)
                } else if let path = item.filePath ?? item.imagePath {
                    textParts.append(path)
                }
            }

            if !textParts.isEmpty {
                let combined = textParts.joined(separator: textSeparator)
                pasteboard.setString(combined, forType: .string)
                return true
            }
            return false
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
