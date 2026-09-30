import AppKit
import Foundation

// MARK: - PasteService
// Writes a selected clipboard item back to NSPasteboard and triggers a paste action
// using accessibility APIs (CGEvent). Implemented in TASK 17.

enum PasteService {
    
    // Notifications used to tell ClipboardMonitor to ignore our own pasteboard writes
    static let willWriteToPasteboard = Notification.Name("Clipmory.willWriteToPasteboard")
    static let didWriteToPasteboard  = Notification.Name("Clipmory.didWriteToPasteboard")
    
    // Guard against rapid duplicate paste triggers (e.g. accidental double clicks or key repeats)
    private static var isPasting = false
    private static var lastPasteTime: TimeInterval = 0
    
    @MainActor
    static func paste(_ item: ClipboardItem) {
        // 0. Check for sensitive item authentication requirement
        let settings = SettingsRepository.shared.load()
        let shouldMask = settings.sensitiveContentAction == .hide || settings.sensitiveContentAction == .showFirstThree
        let isSensitive = item.isSensitive || (item.text != nil && PrivacyManager.shared.containsSensitiveContent(item.text!, sourceBundleId: item.sourceBundleIdentifier))

        if isSensitive && shouldMask && settings.requireAuthForSensitiveContent && !PrivacyManager.shared.isItemAuthenticated(item.id) {
            Task {
                let success = await PrivacyManager.shared.authenticateUser(reason: "paste sensitive clipboard content")
                if success {
                    PrivacyManager.shared.markItemAuthenticated(item.id)
                    paste(item)
                }
            }
            return
        }

        // Prevent duplicate or re-entrant paste triggers within 350ms
        let now = ProcessInfo.processInfo.systemUptime
        guard !isPasting && (now - lastPasteTime > 0.35) else {
            return
        }
        isPasting = true
        lastPasteTime = now

        // 1. Check for Accessibility Permissions
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        let isTrusted = AXIsProcessTrustedWithOptions(options)
        
        guard isTrusted else {
            isPasting = false
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Required"
            alert.informativeText = "Clipmory needs Accessibility permissions to simulate the ⌘V keystroke for auto-pasting. Please enable it in System Settings > Privacy & Security > Accessibility."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "Cancel")
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                PermissionManager.shared.openAccessibilitySettings()
            }
            return
        }

        // 2. Tell monitor to ignore changes
        NotificationCenter.default.post(name: willWriteToPasteboard, object: nil)

        // 3. Write to pasteboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        if let text = item.text, item.type != .image, item.imagePath == nil {
            pasteboard.setString(text, forType: .string)
        } else if let pbItem = makePasteboardItem(for: item) {
            pasteboard.writeObjects([pbItem])
        } else {
            // Nothing to paste, re-enable monitor and exit
            NotificationCenter.default.post(name: didWriteToPasteboard, object: nil)
            isPasting = false
            return
        }
        
        // 4. Dismiss panel and restore target application focus
        dismissAndRestoreFocus()
        
        // 5. Fire Cmd+V
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            triggerCmdV()
            
            // 6. Re-enable monitor and release debounce lock after a slight delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                NotificationCenter.default.post(name: didWriteToPasteboard, object: nil)
                isPasting = false
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

        // 0. Check for sensitive items requiring authentication
        let settings = SettingsRepository.shared.load()
        let shouldMask = settings.sensitiveContentAction == .hide || settings.sensitiveContentAction == .showFirstThree

        if settings.requireAuthForSensitiveContent && shouldMask {
            let unauthenticated = items.filter { item in
                let isSensitive = item.isSensitive || (item.text != nil && PrivacyManager.shared.containsSensitiveContent(item.text!, sourceBundleId: item.sourceBundleIdentifier))
                return isSensitive && !PrivacyManager.shared.isItemAuthenticated(item.id)
            }
            if !unauthenticated.isEmpty {
                Task {
                    let success = await PrivacyManager.shared.authenticateUser(reason: "paste sensitive clipboard content")
                    if success {
                        for item in unauthenticated {
                            PrivacyManager.shared.markItemAuthenticated(item.id)
                        }
                        paste(items: items, textSeparator: textSeparator)
                    }
                }
                return
            }
        }

        // Prevent duplicate or re-entrant paste triggers within 350ms
        let now = ProcessInfo.processInfo.systemUptime
        guard !isPasting && (now - lastPasteTime > 0.35) else {
            return
        }
        isPasting = true
        lastPasteTime = now

        // 1. Check for Accessibility Permissions
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        let isTrusted = AXIsProcessTrustedWithOptions(options)
        
        guard isTrusted else {
            isPasting = false
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Required"
            alert.informativeText = "Clipmory needs Accessibility permissions to simulate the ⌘V keystroke for auto-pasting. Please enable it in System Settings > Privacy & Security > Accessibility."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "Cancel")
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                PermissionManager.shared.openAccessibilitySettings()
            }
            return
        }

        // 2. Pure text items: Join with separator and single Cmd+V
        let isAllPureText = items.allSatisfy {
            $0.type != .image && $0.type != .file && $0.imagePath == nil && $0.filePath == nil && $0.text != nil
        }
        
        if isAllPureText {
            NotificationCenter.default.post(name: willWriteToPasteboard, object: nil)
            guard writeToPasteboard(items, textSeparator: textSeparator) else {
                NotificationCenter.default.post(name: didWriteToPasteboard, object: nil)
                isPasting = false
                return
            }

            dismissAndRestoreFocus()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                triggerCmdV()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    NotificationCenter.default.post(name: didWriteToPasteboard, object: nil)
                    isPasting = false
                }
            }
            return
        }

        // 3. Multi-image, file, or media items:
        // Web applications (ChatGPT, Photopea, Canva, etc.) and many desktop apps only consume
        // the first image per Cmd+V event from the system clipboard.
        // Sequential pasting dispatches each image with a small interval so that every single image
        // is cleanly received and attached by the target application.
        dismissAndRestoreFocus()

        let interval: Double = 0.35
        let startDelay: Double = 0.35

        for (index, item) in items.enumerated() {
            let delay = startDelay + (Double(index) * interval)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                NotificationCenter.default.post(name: willWriteToPasteboard, object: nil)
                writeSingleItemToPasteboard(item)
                triggerCmdV()
            }
        }

        // After all items are pasted, write the full multi-item collection back to pasteboard
        // and re-enable ClipboardMonitor
        let finalDelay = startDelay + (Double(items.count) * interval) + 0.15
        DispatchQueue.main.asyncAfter(deadline: .now() + finalDelay) {
            NotificationCenter.default.post(name: willWriteToPasteboard, object: nil)
            _ = writeToPasteboard(items, textSeparator: textSeparator)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NotificationCenter.default.post(name: didWriteToPasteboard, object: nil)
                isPasting = false
            }
        }
    }

    @MainActor
    @discardableResult
    private static func writeSingleItemToPasteboard(_ item: ClipboardItem) -> Bool {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        if let text = item.text, item.type != .image, item.imagePath == nil {
            return pasteboard.setString(text, forType: .string)
        } else if let pbItem = makePasteboardItem(for: item) {
            return pasteboard.writeObjects([pbItem])
        }
        return false
    }

    @MainActor
    @discardableResult
    static func copy(items: [ClipboardItem], textSeparator: String = "\n") -> Bool {
        guard !items.isEmpty else { return false }

        // Check for sensitive items requiring authentication
        let settings = SettingsRepository.shared.load()
        let shouldMask = settings.sensitiveContentAction == .hide || settings.sensitiveContentAction == .showFirstThree

        if settings.requireAuthForSensitiveContent && shouldMask {
            let unauthenticated = items.filter { item in
                let isSensitive = item.isSensitive || (item.text != nil && PrivacyManager.shared.containsSensitiveContent(item.text!, sourceBundleId: item.sourceBundleIdentifier))
                return isSensitive && !PrivacyManager.shared.isItemAuthenticated(item.id)
            }
            if !unauthenticated.isEmpty {
                Task {
                    let success = await PrivacyManager.shared.authenticateUser(reason: "copy sensitive clipboard content")
                    if success {
                        for item in unauthenticated {
                            PrivacyManager.shared.markItemAuthenticated(item.id)
                        }
                        _ = copy(items: items, textSeparator: textSeparator)
                    }
                }
                return false
            }
        }

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

        // 1. If all items are pure text items, join them with the separator
        let isAllPureText = items.allSatisfy {
            $0.type != .image && $0.type != .file && $0.imagePath == nil && $0.filePath == nil && $0.text != nil
        }
        if isAllPureText {
            let textParts = items.compactMap { $0.text }
            let combined = textParts.joined(separator: textSeparator)
            pasteboard.setString(combined, forType: .string)
            return true
        }

        // 2. Multi-photo, file, or mixed items: Write rich NSPasteboardItems for each
        var pbItems: [NSPasteboardItem] = []
        for item in items {
            if let pbItem = makePasteboardItem(for: item) {
                pbItems.append(pbItem)
            }
        }

        if !pbItems.isEmpty {
            return pasteboard.writeObjects(pbItems)
        }

        return false
    }

    @MainActor
    private static func makePasteboardItem(for item: ClipboardItem) -> NSPasteboardItem? {
        let pbItem = NSPasteboardItem()
        
        // Handle images and image files
        if let path = item.imagePath ?? item.filePath, FileManager.default.fileExists(atPath: path) {
            let fileURL = URL(fileURLWithPath: path)
            let ext = fileURL.pathExtension.lowercased()
            let isImageExt = ["png", "jpg", "jpeg", "gif", "webp", "tiff", "bmp", "heic"].contains(ext)
            
            if item.type == .image || isImageExt {
                var addedAnyImage = false
                
                // 1. GIF support
                if ext == "gif", let gifData = try? Data(contentsOf: fileURL) {
                    pbItem.setData(gifData, forType: NSPasteboard.PasteboardType("com.compuserve.gif"))
                    if let img = NSImage(data: gifData), let tiff = img.tiffRepresentation {
                        pbItem.setData(tiff, forType: .tiff)
                    }
                    addedAnyImage = true
                } else {
                    // Try to load raw PNG data directly if available
                    if ext == "png", let directData = try? Data(contentsOf: fileURL) {
                        pbItem.setData(directData, forType: .png)
                        addedAnyImage = true
                    }
                    
                    // Generate TIFF and PNG representations via NSImage
                    if let img = FileStorage.loadImage(at: path) ?? NSImage(contentsOfFile: path) {
                        if let tiff = img.tiffRepresentation {
                            if !addedAnyImage,
                               let rep = NSBitmapImageRep(data: tiff),
                               let png = rep.representation(using: .png, properties: [:]) {
                                pbItem.setData(png, forType: .png)
                                addedAnyImage = true
                            }
                            pbItem.setData(tiff, forType: .tiff)
                            addedAnyImage = true
                        }
                    }
                }
                
                // 2. Set fileURL AFTER image data so image data (.png / .tiff) has higher flavor precedence
                pbItem.setString(fileURL.absoluteString, forType: .fileURL)
                
                if addedAnyImage {
                    return pbItem
                }
            } else if item.type == .file {
                // Non-image file
                pbItem.setString(fileURL.absoluteString, forType: .fileURL)
                return pbItem
            }
        }
        
        // Handle plain text
        if let text = item.text {
            pbItem.setString(text, forType: .string)
            return pbItem
        }
        
        return nil
    }
    
    // MARK: - Focus and Event Helpers
    
    @MainActor
    private static func dismissAndRestoreFocus() {
        AppDelegate.shared?.closeMainWindow()
        if let targetApp = AppDelegate.shared?.previousApp,
           targetApp.bundleIdentifier != Bundle.main.bundleIdentifier {
            targetApp.activate(options: [.activateIgnoringOtherApps])
        } else {
            NSApp.hide(nil)
        }
    }
    
    private static func triggerCmdV() {
        let vKeyCode: CGKeyCode = 0x09 // 'v'
        
        guard let source = CGEventSource(stateID: .combinedSessionState) ?? CGEventSource(stateID: .hidSystemState) else { return }
        
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true)
        let keyUp   = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false)
        
        let cmdFlag = CGEventFlags.maskCommand
        keyDown?.flags = cmdFlag
        keyUp?.flags   = cmdFlag
        
        // Post ONLY to cgSessionEventTap so the active application receives a single Cmd+V event.
        // Posting to both cgSessionEventTap and cghidEventTap caused the event to be delivered twice in many applications.
        keyDown?.post(tap: .cgSessionEventTap)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            keyUp?.post(tap: .cgSessionEventTap)
        }
    }
}
