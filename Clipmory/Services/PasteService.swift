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

        #if !APP_STORE
        // 1. Check Assistive Auto-Insert preference
        let shouldAutoInsert = settings.assistiveAutoInsert || AXIsProcessTrusted()
        
        if shouldAutoInsert {
            let isTrusted = AXIsProcessTrusted()
            if !isTrusted {
                isPasting = false
                let alert = NSAlert()
                alert.messageText = "Accessibility Permission Required for Auto-Paste"
                alert.informativeText = "Clipmory needs Accessibility permission to automatically insert (⌘+V) content into the active application. To enable this feature, please grant Accessibility permission in System Settings > Privacy & Security > Accessibility."
                alert.alertStyle = .informational
                alert.addButton(withTitle: "Open System Settings")
                alert.addButton(withTitle: "Cancel")
                
                let response = alert.runModal()
                if response == .alertFirstButtonReturn {
                    PermissionManager.shared.openAccessibilitySettings()
                }
                return
            }
        }
        #endif

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
        
        #if !APP_STORE
        if shouldAutoInsert && AXIsProcessTrusted() {
            // Fire Cmd+V for assistive insertion after the target app regains full focus
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                triggerCmdV()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    NotificationCenter.default.post(name: didWriteToPasteboard, object: nil)
                    isPasting = false
                }
            }
        } else {
            // Standard sandbox mode: Item is copied to pasteboard and focus restored
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                NotificationCenter.default.post(name: didWriteToPasteboard, object: nil)
                isPasting = false
            }
        }
        #else
        // Standard App Store sandbox mode: Item is copied to pasteboard and focus restored
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            NotificationCenter.default.post(name: didWriteToPasteboard, object: nil)
            isPasting = false
        }
        #endif
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

        #if !APP_STORE
        let shouldAutoInsert = settings.assistiveAutoInsert || AXIsProcessTrusted()

        if shouldAutoInsert {
            let isTrusted = AXIsProcessTrusted()
            if !isTrusted {
                isPasting = false
                let alert = NSAlert()
                alert.messageText = "Assistive Tools Permission Required"
                alert.informativeText = "Clipmory includes assistive single-action insertion for users with motor impairments or difficulty performing keyboard shortcuts (⌘+V). To enable this assistive feature, please grant Accessibility permission in System Settings > Privacy & Security > Accessibility."
                alert.alertStyle = .informational
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

            // 3. Multi-image, file, or media items
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

            let finalDelay = startDelay + (Double(items.count) * interval) + 0.15
            DispatchQueue.main.asyncAfter(deadline: .now() + finalDelay) {
                NotificationCenter.default.post(name: willWriteToPasteboard, object: nil)
                _ = writeToPasteboard(items, textSeparator: textSeparator)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NotificationCenter.default.post(name: didWriteToPasteboard, object: nil)
                    isPasting = false
                }
            }
        } else {
            // Standard copy to pasteboard without keystroke injection
            NotificationCenter.default.post(name: willWriteToPasteboard, object: nil)
            _ = writeToPasteboard(items, textSeparator: textSeparator)
            dismissAndRestoreFocus()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                NotificationCenter.default.post(name: didWriteToPasteboard, object: nil)
                isPasting = false
            }
        }
        #else
        // Standard App Store multi-item copy: Write all items to pasteboard without keystroke injection
        NotificationCenter.default.post(name: willWriteToPasteboard, object: nil)
        _ = writeToPasteboard(items, textSeparator: textSeparator)
        dismissAndRestoreFocus()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            NotificationCenter.default.post(name: didWriteToPasteboard, object: nil)
            isPasting = false
        }
        #endif
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
        guard !items.isEmpty else { return false }
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

        // 2. If all items are pure non-image files, write them as file URLs for Finder
        let isAllFiles = items.allSatisfy {
            $0.type == .file && $0.filePath != nil && $0.imagePath == nil
        }
        if isAllFiles {
            var fileURLs: [NSURL] = []
            for item in items {
                if let path = item.filePath, FileManager.default.fileExists(atPath: path) {
                    fileURLs.append(NSURL(fileURLWithPath: path))
                }
            }
            if !fileURLs.isEmpty {
                return pasteboard.writeObjects(fileURLs)
            }
        }

        // 3. Mixed content (Text + Images / Files):
        // Build rich attributed string combining text and inline image attachments (RTFD + HTML)
        let richText = NSMutableAttributedString()
        var textParts: [String] = []
        var firstImage: NSImage? = nil
        var fileURLs: [NSURL] = []
        var pbItems: [NSPasteboardItem] = []

        for (index, item) in items.enumerated() {
            if index > 0 && richText.length > 0 {
                richText.append(NSAttributedString(string: textSeparator))
            }

            if item.type == .image || item.imagePath != nil {
                // Image item
                if let path = item.imagePath ?? item.filePath,
                   let img = FileStorage.loadImage(at: path) ?? NSImage(contentsOfFile: path) {
                    if firstImage == nil {
                        firstImage = img
                    }
                    
                    let imgData: Data? = {
                        if let tiff = img.tiffRepresentation {
                            if let rep = NSBitmapImageRep(data: tiff),
                               let png = rep.representation(using: .png, properties: [:]) {
                                return png
                            }
                            return tiff
                        }
                        return nil
                    }()

                    if let data = imgData {
                        let wrapper = FileWrapper(regularFileWithContents: data)
                        wrapper.preferredFilename = "image_\(index).png"
                        let attach = NSTextAttachment(fileWrapper: wrapper)
                        richText.append(NSAttributedString(attachment: attach))
                    }
                } else if let txt = item.text {
                    richText.append(NSAttributedString(string: txt))
                    textParts.append(txt)
                }

                if let filePath = item.filePath, FileManager.default.fileExists(atPath: filePath) {
                    fileURLs.append(NSURL(fileURLWithPath: filePath))
                }
            } else if let txt = item.text {
                // Text item
                richText.append(NSAttributedString(string: txt))
                textParts.append(txt)
            } else if let filePath = item.filePath, FileManager.default.fileExists(atPath: filePath) {
                fileURLs.append(NSURL(fileURLWithPath: filePath))
            }

            if let pbItem = makePasteboardItem(for: item) {
                pbItems.append(pbItem)
            }
        }

        var wroteAny = false

        // Write RTFD and HTML so rich text applications (Notes, Pages, Word, Mail, Slack, Web editors)
        // paste both text and images inline in a single ⌘V action.
        let range = NSRange(location: 0, length: richText.length)
        if richText.length > 0 {
            if let rtfd = richText.rtfd(from: range, documentAttributes: [:]) {
                pasteboard.setData(rtfd, forType: .rtfd)
                pasteboard.setData(rtfd, forType: NSPasteboard.PasteboardType("com.apple.flat-rtfd"))
                wroteAny = true
            }
            if let html = try? richText.data(from: range, documentAttributes: [.documentType: NSAttributedString.DocumentType.html]) {
                pasteboard.setData(html, forType: .html)
                wroteAny = true
            }
        }

        // Write primary image flavors if image was included (for image paste targets)
        if let img = firstImage, let tiff = img.tiffRepresentation {
            pasteboard.setData(tiff, forType: .tiff)
            if let rep = NSBitmapImageRep(data: tiff),
               let png = rep.representation(using: .png, properties: [:]) {
                pasteboard.setData(png, forType: .png)
            }
            wroteAny = true
        }

        // Write file URLs if files were included (for Finder paste)
        if !fileURLs.isEmpty {
            pasteboard.writeObjects(fileURLs)
            wroteAny = true
        }

        // Plain text fallback (for terminal / plain text fields)
        let plainCombined = textParts.isEmpty ? richText.string : textParts.joined(separator: textSeparator)
        if !plainCombined.isEmpty {
            pasteboard.setString(plainCombined, forType: .string)
            wroteAny = true
        }

        if !pbItems.isEmpty && !wroteAny {
            wroteAny = pasteboard.writeObjects(pbItems)
        }

        return wroteAny
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
                            pbItem.setData(tiff, forType: .tiff)
                            addedAnyImage = true
                            
                            if let rep = NSBitmapImageRep(data: tiff),
                               let png = rep.representation(using: .png, properties: [:]) {
                                pbItem.setData(png, forType: .png)
                            }
                        }
                    }
                }
                
                // 2. Set fileURL ONLY if the item has an original file path on the user's filesystem
                // (Never expose private sandbox container paths to external apps)
                if let originalFilePath = item.filePath, FileManager.default.fileExists(atPath: originalFilePath) {
                    let originalURL = URL(fileURLWithPath: originalFilePath)
                    pbItem.setString(originalURL.absoluteString, forType: .fileURL)
                }
                
                // 3. Optional fallback text representation (filename or label)
                if let text = item.text {
                    pbItem.setString(text, forType: .string)
                }
                
                if addedAnyImage {
                    return pbItem
                }
            } else if item.type == .file {
                // Non-image file
                if let originalFilePath = item.filePath, FileManager.default.fileExists(atPath: originalFilePath) {
                    let originalURL = URL(fileURLWithPath: originalFilePath)
                    pbItem.setString(originalURL.absoluteString, forType: .fileURL)
                } else {
                    pbItem.setString(fileURL.absoluteString, forType: .fileURL)
                }
                if let text = item.text {
                    pbItem.setString(text, forType: .string)
                }
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
    
    #if !APP_STORE
    private static func triggerCmdV() {
        let vKeyCode: CGKeyCode = 0x09 // 'v'
        
        guard let source = CGEventSource(stateID: .combinedSessionState) ?? CGEventSource(stateID: .hidSystemState) else { return }
        
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true)
        let keyUp   = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false)
        
        let cmdFlag = CGEventFlags.maskCommand
        keyDown?.flags = cmdFlag
        keyUp?.flags   = cmdFlag
        
        // Post to cghidEventTap to send genuine hardware-level keystroke to frontmost active application
        keyDown?.post(tap: .cghidEventTap)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
            keyUp?.post(tap: .cghidEventTap)
        }
    }
    #endif
}
