import AppKit
import Foundation

// MARK: - ClipboardMonitor (TASK 5)
// Polls NSPasteboard.changeCount every 0.5 s to detect clipboard changes.
// On detection: reads content via ClipboardReader and passes it to ClipboardStore.
//
// isWritingToPasteboard — must be set true by PasteService before writing to
// NSPasteboard and false immediately after, so Clipmory does not record its
// own paste operations as new history entries (TASK 17 contract).

@MainActor
final class ClipboardMonitor {

    // MARK: Properties

    /// Set to true by PasteService while Clipmory is writing to NSPasteboard.
    var isWritingToPasteboard = false

    private let store: ClipboardStore
    private let reader = ClipboardReader()
    private var timer: Timer?
    private var lastChangeCount: Int

    // MARK: Init

    init(store: ClipboardStore) {
        self.store = store
        self.lastChangeCount = NSPasteboard.general.changeCount
        
        NotificationCenter.default.addObserver(forName: PasteService.willWriteToPasteboard, object: nil, queue: .main) { @MainActor [weak self] _ in
            self?.isWritingToPasteboard = true
        }
        
        NotificationCenter.default.addObserver(forName: PasteService.didWriteToPasteboard, object: nil, queue: .main) { @MainActor [weak self] _ in
            self?.isWritingToPasteboard = false
            self?.lastChangeCount = NSPasteboard.general.changeCount // Reset count to ignore the write
        }
    }

    // MARK: - Lifecycle

    func start() {
        guard timer == nil else { return }
        let t = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.checkPasteboard() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Private

    private func checkPasteboard() {
        guard !isWritingToPasteboard else { return }

        let settings = SettingsRepository.shared.load()
        guard settings.enableHistory else { return }

        let pasteboard  = NSPasteboard.general
        let changeCount = pasteboard.changeCount
        guard changeCount != lastChangeCount else { return }
        lastChangeCount = changeCount
        
        // Background housekeeping: enforce retention policy
        store.enforceRetention(hours: settings.autoDeleteHistory.rawValue)

        // Capture the frontmost app at the moment of copy.
        // Filter out Clipmory itself to avoid self-attribution.
        let workspace  = NSWorkspace.shared
        let frontmost  = workspace.frontmostApplication
        let selfBundle = Bundle.main.bundleIdentifier
        let sourceApp  = (frontmost?.bundleIdentifier == selfBundle) ? nil : frontmost

        // Enforce Privacy (Private Mode and Excluded Apps)
        guard PrivacyManager.shared.canRecord(sourceAppBundleId: sourceApp?.bundleIdentifier) else { return }

        let isFieldEntry = ClipboardClassifier.isFieldEntryOrPassword(pasteboard: pasteboard, sourceApp: sourceApp)

        guard var item = reader.read(from: pasteboard, sourceApp: sourceApp) else { return }
        
        // If from a secure field entry or password source, explicitly mark as sensitive
        if isFieldEntry {
            item.isSensitive = true
        }

        // 1. Sensitive Content & Password Interception
        let isSensitive = item.isSensitive || (item.text != nil && PrivacyManager.shared.containsSensitiveContent(item.text!, sourceBundleId: sourceApp?.bundleIdentifier))
        
        if isSensitive {
            item.isSensitive = true
            if settings.sensitiveContentDetection && settings.sensitiveContentAction == .dontCopy {
                #if DEBUG
                print("Intercepted sensitive content / password. Dropping per privacy setting.")
                #endif
                return
            }
        }
        
        // 2. Data Type Exclusions
        if (item.type == .text || item.type == .richText) && !settings.saveText { return }
        if item.type == .image && !settings.saveImages { return }
        if item.type == .file && !settings.saveFiles { return }
        
        // Store the item
        store.add(item)
        
        // 3. Enforce Capacity Limits
        if settings.historyLimit > 0 {
            store.enforceLimit(settings.historyLimit)
        }
    }
}
