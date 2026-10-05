import AppKit
import SwiftUI

// MARK: - AppDelegate
// Opens a standalone floating window on launch.
// The app appears in the Dock like a regular macOS application.

// MARK: - ClipboardPanel
// Custom NSWindow subclass ensuring the floating panel can always become key and main,
// allowing proper focus handling and click-outside dismissal in accessory mode.
final class ClipboardPanel: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {

    // MARK: - Singleton & State
    static private(set) var shared: AppDelegate?
    var previousApp: NSRunningApplication?

    override init() {
        super.init()
        AppDelegate.shared = self
    }

    func recordPreviousApp() {
        if let current = NSWorkspace.shared.frontmostApplication,
           current.bundleIdentifier != Bundle.main.bundleIdentifier {
            self.previousApp = current
        }
    }

    // MARK: Private Properties

    static let windowWillOpenNotification = Notification.Name("clipmoryWindowWillOpen")
    static let clipFlowWindowWillOpen = windowWillOpenNotification

    private var window: NSWindow?
    private var settingsWindow: NSWindow?
    private var onboardingWindow: NSWindow?
    private var hotkeyObserver: NSObjectProtocol?
    private var statusItem: NSStatusItem?
    private var clickOutsideMonitor: Any?

    // Core clipboard pipeline — owned here and injected downward
    private let clipboardStore   = ClipboardStore()
    private var clipboardMonitor: ClipboardMonitor?

    // MARK: NSApplicationDelegate

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupURLHandler()
        setupApplication()
        setupDatabase()
        setupClipboardPipeline()
        
        // Only present the onboarding window on first launch.
        // For normal launches (including system restart / launch-at-login),
        // run silently in the background and only show when invoked by the user.
        if !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
            openOnboardingWindow()
        }
        
        setupHotkey()
        
        // Hide the main window when the user clicks outside (app loses focus),
        // but keep it visible if the system Touch ID / Password prompt is active.
        NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.closeMainWindow()
        }

        NotificationCenter.default.addObserver(
            forName: NSApplication.willHideNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.stopClickOutsideMonitor()
        }
    }

    private func setupURLHandler() {
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURL(event:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    @objc private func handleGetURL(event: NSAppleEventDescriptor, withReplyEvent reply: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
              let url = URL(string: urlString) else {
            return
        }
        handleIncomingURL(url)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Re-show window if user clicks Dock icon while window is closed
        if !flag { openMainWindow() }
        return true
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            handleIncomingURL(url)
        }
    }

    private func handleIncomingURL(_ url: URL) {
        guard url.scheme?.lowercased() == "clipmory" else { return }
        
        var extractedKey: String? = nil
        let host = url.host?.lowercased() ?? ""
        let path = url.path.lowercased()
        
        if host == "activate" || host == "license" || host == "pro" || path.contains("activate") || path.contains("license") {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            if let keyItem = components?.queryItems?.first(where: { $0.name.lowercased() == "key" || $0.name.lowercased() == "license" }),
               let rawKey = keyItem.value {
                extractedKey = rawKey
            } else {
                let last = url.lastPathComponent
                if !last.isEmpty && last != "/" && last != "activate" && last != "license" {
                    extractedKey = last
                }
            }
        }
        
        // 1. Always bring app to front and open window
        NSApp.activate(ignoringOtherApps: true)
        openMainWindow()

        // 2. If key was not in URL, try reading license key from system clipboard
        if extractedKey == nil {
            if let clipText = NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines),
               clipText.count >= 10 && clipText.count <= 64 {
                let safeCharset = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_")
                if clipText.unicodeScalars.allSatisfy({ safeCharset.contains($0) }) {
                    extractedKey = clipText
                }
            }
        }
        
        guard let rawKey = extractedKey else { return }
        let key = rawKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Security Sanitization:
        guard key.count >= 10 && key.count <= 64 else {
            NSLog("Security Warning: Rejected invalid activation key length: \(key.count) characters")
            return
        }
        
        let safeCharset = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_")
        guard key.unicodeScalars.allSatisfy({ safeCharset.contains($0) }) else {
            NSLog("Security Warning: Rejected activation key containing unsafe characters")
            return
        }
        
        // 2. Activate asynchronously with Creem
        Task { @MainActor in
            let success = await ProManager.shared.activateLicenseAsync(key: key)
            if success {
                ProManager.shared.showPaywall = false
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardMonitor?.stop()
        GlobalHotkeyManager.shared.unregister()
        if let obs = hotkeyObserver { NotificationCenter.default.removeObserver(obs) }
    }

    // MARK: NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        closeMainWindow()
    }

    func windowDidResignKey(_ notification: Notification) {
        if let win = notification.object as? NSWindow, win == self.window {
            closeMainWindow()
        }
    }

    func windowDidResignMain(_ notification: Notification) {
        if let win = notification.object as? NSWindow, win == self.window {
            closeMainWindow()
        }
    }

    func closeMainWindow() {
        guard !PrivacyManager.shared.isAuthenticating else { return }
        stopClickOutsideMonitor()
        window?.orderOut(nil)
    }

    private func startClickOutsideMonitor() {
        stopClickOutsideMonitor()
        clickOutsideMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self = self, let win = self.window, win.isVisible else { return }
            guard !PrivacyManager.shared.isAuthenticating else { return }
            let clickLocation = NSEvent.mouseLocation
            if !win.frame.contains(clickLocation) {
                self.closeMainWindow()
            }
        }
    }

    private func stopClickOutsideMonitor() {
        if let monitor = clickOutsideMonitor {
            NSEvent.removeMonitor(monitor)
            clickOutsideMonitor = nil
        }
    }

    // MARK: - Setup

    private func setupApplication() {
        // Run as a regular app during onboarding so the user doesn't lose the window,
        // otherwise run as an accessory (menu bar only) app.
        if UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
            NSApp.setActivationPolicy(.accessory)
        } else {
            NSApp.setActivationPolicy(.regular)
        }
        
        let settings = SettingsRepository.shared.load()
        updateMenuBarIcon(show: settings.showInMenuBar)
        
        // Enforce system start at login preference
        LaunchAtLoginManager.shared.setLaunchAtLogin(settings.launchAtLogin)
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("clipmoryShowInMenuBarChanged"), object: nil, queue: .main) { @MainActor [weak self] _ in
            let show = SettingsRepository.shared.load().showInMenuBar
            self?.updateMenuBarIcon(show: show)
        }
    }
    
    private func updateMenuBarIcon(show: Bool) {
        if show {
            if statusItem == nil {
                statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
                if let button = statusItem?.button {
                    if let customIcon = NSImage(named: "MenuBarIcon") {
                        customIcon.isTemplate = true
                        button.image = customIcon
                    } else {
                        button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipmory")
                    }
                    button.action = #selector(statusBarButtonClicked(_:))
                    button.target = self
                    button.sendAction(on: [.leftMouseUp, .rightMouseUp])
                }
            }
        } else {
            if let item = statusItem {
                NSStatusBar.system.removeStatusItem(item)
                statusItem = nil
            }
        }
    }
    
    @objc @MainActor private func statusBarButtonClicked(_ sender: Any) {
        // Hide the floating clipboard window if open
        closeMainWindow()
        
        // Pop up the menu with Open Clipmory, Settings, Check for Updates, and Quit Clipmory
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open Clipmory", action: #selector(openMainWindowAction), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
#if !APP_STORE
        menu.addItem(NSMenuItem(title: "Check for Updates...", action: #selector(checkForUpdates), keyEquivalent: "u"))
#endif
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Clipmory", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem?.popUpMenu(menu)
    }

    @objc private func openMainWindowAction() {
        openMainWindow()
    }
    
    @objc private func checkForUpdates() {
        UpdateManager.shared.checkForUpdates()
    }
    
    @objc private func openSettings() {
        closeMainWindow()
        if let existing = settingsWindow {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let settingsView = SettingsView(store: clipboardStore)
        let hostingController = NSHostingController(rootView: settingsView)
        
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 750, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView, .resizable],
            backing: .buffered,
            defer: false
        )
        win.titlebarAppearsTransparent = true
        win.titleVisibility = .hidden
        win.contentViewController = hostingController
        win.center()
        win.isReleasedWhenClosed = false
        win.minSize = NSSize(width: 700, height: 500)
        win.collectionBehavior = [.moveToActiveSpace]
        
        settingsWindow = win
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func setupDatabase() {
        do {
            try DatabaseManager.shared.open()
            try DatabaseMigration.migrate(db: DatabaseManager.shared.db)
            print("Database initialized and migrated successfully.")
        } catch {
            print("CRITICAL ERROR: Failed to initialize database: \(error)")
            // Fallback: app still runs but history won't persist
        }
    }

    private func setupClipboardPipeline() {
        let monitor = ClipboardMonitor(store: clipboardStore)
        monitor.start()
        clipboardMonitor = monitor
    }

    private func setupHotkey() {
        GlobalHotkeyManager.shared.register()
        
        hotkeyObserver = NotificationCenter.default.addObserver(
            forName: .clipmoryHotkeyFired,
            object: nil,
            queue: .main
        ) { @MainActor [weak self] _ in
            self?.toggleWindow()
        }
        
        NotificationCenter.default.addObserver(
            forName: .clipmoryCaptureHotkeyFired,
            object: nil,
            queue: .main
        ) { @MainActor [weak self] _ in
            self?.closeMainWindow()
            ScreenCaptureService.shared.startCapture(forceImageOnly: false)
        }
        
        NotificationCenter.default.addObserver(
            forName: .clipmoryCaptureImageOnlyHotkeyFired,
            object: nil,
            queue: .main
        ) { @MainActor [weak self] _ in
            self?.closeMainWindow()
            ScreenCaptureService.shared.startCapture(forceImageOnly: true)
        }
    }

    private func toggleWindow() {
        guard let win = window else {
            openMainWindow()
            return
        }
        if win.isVisible {
            closeMainWindow()
        } else {
            recordPreviousApp()
            openMainWindow()
        }
    }
    
    private func openOnboardingWindow() {
        NSApp.setActivationPolicy(.regular)
        if let existing = onboardingWindow {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let viewModel = OnboardingViewModel()
        viewModel.onComplete = { [weak self] in
            NSApp.setActivationPolicy(.accessory)
            self?.onboardingWindow?.close()
            self?.onboardingWindow = nil
            self?.openMainWindow()
        }
        
        let hostingController = NSHostingController(rootView: OnboardingView(viewModel: viewModel))
        
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 900),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        win.titlebarAppearsTransparent = true
        win.titleVisibility = .hidden
        win.isMovableByWindowBackground = true
        win.contentViewController = hostingController
        win.hidesOnDeactivate = false
        win.level = .normal
        
        // Ensure it always spawns in the exact center of the main screen
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let newX = screenRect.midX - 450 // 900 / 2
            let newY = screenRect.midY - 450 // 900 / 2
            win.setFrameOrigin(NSPoint(x: newX, y: newY))
        } else {
            win.center()
        }
        
        win.isReleasedWhenClosed = false
        win.backgroundColor = .clear
        win.isOpaque = false
        
        // Hide window buttons
        win.standardWindowButton(.closeButton)?.isHidden = true
        win.standardWindowButton(.miniaturizeButton)?.isHidden = true
        win.standardWindowButton(.zoomButton)?.isHidden = true
        
        onboardingWindow = win
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func openMainWindow() {
        recordPreviousApp()
        PrivacyManager.shared.resetSessionAuth()
        if let existing = window {
            if NSApp.isHidden {
                NSApp.unhideWithoutActivation()
            }
            moveWindowNearCursor(existing)
            NotificationCenter.default.post(name: AppDelegate.windowWillOpenNotification, object: nil)
            existing.orderFrontRegardless()
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            startClickOutsideMonitor()
            return
        }

        let panelView = MainPanelView(store: clipboardStore, onClose: { [weak self] in
            self?.closeMainWindow()
        })

        let hostingController = NSHostingController(rootView: panelView)
        hostingController.view.setFrameSize(NSSize(width: 420, height: 560))

        let win = ClipboardPanel(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 560),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        win.title = "Clipmory"
        win.titlebarAppearsTransparent = true
        win.titleVisibility = .hidden
        win.isMovableByWindowBackground = true
        win.contentViewController = hostingController
        win.setContentSize(NSSize(width: 420, height: 560))
        win.minSize = NSSize(width: 420, height: 560)
        win.maxSize = NSSize(width: 420, height: 560)
        
        // Setup window for transparent blur effect
        win.backgroundColor = .clear
        win.isOpaque = false
        win.hasShadow = true
        win.level = .floating
        win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Hide all three traffic light buttons
        win.standardWindowButton(.closeButton)?.isHidden = true
        win.standardWindowButton(.miniaturizeButton)?.isHidden = true
        win.standardWindowButton(.zoomButton)?.isHidden = true

        moveWindowNearCursor(win)
        win.delegate = self
        NotificationCenter.default.post(name: AppDelegate.windowWillOpenNotification, object: nil)
        win.orderFrontRegardless()
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.window = win
        startClickOutsideMonitor()
    }

    // MARK: - Cursor Positioning

    /// Positions the window so its top-left corner appears just below-right
    /// of the cursor, clamped so the window never goes off-screen.
    private func moveWindowNearCursor(_ win: NSWindow) {
        let cursor = NSEvent.mouseLocation          // global screen coords (bottom-left origin)
        let size   = win.frame.size
        let offset: CGFloat = 12                   // gap between cursor tip and window edge

        // Determine which screen the cursor is on (fall back to main screen)
        let screen = NSScreen.screens.first(where: { NSMouseInRect(cursor, $0.frame, false) })
                  ?? NSScreen.main
                  ?? NSScreen.screens[0]

        let visible = screen.visibleFrame          // excludes menu bar & Dock

        // Start with cursor just below-right
        var x = cursor.x + offset
        var y = cursor.y - size.height - offset    // macOS y-axis: 0 = bottom

        // Clamp horizontally
        x = max(visible.minX, min(x, visible.maxX - size.width))
        // Clamp vertically
        y = max(visible.minY, min(y, visible.maxY - size.height))

        win.setFrameOrigin(NSPoint(x: x, y: y))
    }
}

// MARK: - LaunchAtLoginManager
import ServiceManagement

final class LaunchAtLoginManager {
    static let shared = LaunchAtLoginManager()
    
    private init() {}
    
    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }
    
    var statusDescription: String {
        switch SMAppService.mainApp.status {
        case .enabled: return "enabled"
        case .notRegistered: return "notRegistered"
        case .requiresApproval: return "requiresApproval"
        case .notFound: return "notFound"
        @unknown default: return "unknown(\(SMAppService.mainApp.status.rawValue))"
        }
    }
    
    @discardableResult
    func setLaunchAtLogin(_ enabled: Bool) -> Bool {
        let currentStatus = SMAppService.mainApp.status
        NSLog("[LaunchAtLogin] Target enabled: %d, Current SMAppService status: %@", enabled, statusDescription)
        do {
            if enabled {
                if currentStatus == .requiresApproval {
                    SMAppService.openSystemSettingsLoginItems()
                } else if currentStatus != .enabled {
                    try SMAppService.mainApp.register()
                    NSLog("[LaunchAtLogin] Successfully registered to launch at login. New status: %@", statusDescription)
                }
            } else {
                if currentStatus == .enabled || currentStatus == .requiresApproval {
                    try SMAppService.mainApp.unregister()
                    NSLog("[LaunchAtLogin] Successfully unregistered from launch at login. New status: %@", statusDescription)
                }
            }
            return true
        } catch {
            NSLog("[LaunchAtLogin] Failed to set launch at login: %@", error.localizedDescription)
            if SMAppService.mainApp.status == .requiresApproval {
                SMAppService.openSystemSettingsLoginItems()
            }
            return false
        }
    }
}
