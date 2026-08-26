import AppKit
import SwiftUI

// MARK: - AppDelegate
// Opens a standalone floating window on launch.
// The app appears in the Dock like a regular macOS application.

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {

    // MARK: Private Properties

    static let windowWillOpenNotification = Notification.Name("clipFlowWindowWillOpen")

    private var window: NSWindow?
    private var settingsWindow: NSWindow?
    private var onboardingWindow: NSWindow?
    private var hotkeyObserver: NSObjectProtocol?
    private var statusItem: NSStatusItem?

    // Core clipboard pipeline — owned here and injected downward
    private let clipboardStore   = ClipboardStore()
    private var clipboardMonitor: ClipboardMonitor?

    // MARK: NSApplicationDelegate

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupApplication()
        setupDatabase()
        setupClipboardPipeline()
        
        if UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
            openMainWindow()
        } else {
            openOnboardingWindow()
        }
        
        setupHotkey()
        
        // Hide the main window when the user clicks outside (app loses focus)
        NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.window?.orderOut(nil)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Re-show window if user clicks Dock icon while window is closed
        if !flag { openMainWindow() }
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardMonitor?.stop()
        GlobalHotkeyManager.shared.unregister()
        if let obs = hotkeyObserver { NotificationCenter.default.removeObserver(obs) }
    }

    // MARK: NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        // When the window is closed, hide it but keep the app running in the background.
        window?.orderOut(nil)
    }

    // MARK: - Setup

    private func setupApplication() {
        // Run as a Menu Bar accessory (no Dock icon)
        NSApp.setActivationPolicy(.accessory)
        
        let settings = SettingsRepository.shared.load()
        updateMenuBarIcon(show: settings.showInMenuBar)
        
        // Enforce system start at login preference
        LaunchAtLoginManager.shared.setLaunchAtLogin(settings.launchAtLogin)
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("clipFlowShowInMenuBarChanged"), object: nil, queue: .main) { @MainActor [weak self] _ in
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
                        button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "ClipFlow")
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
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp || (event.modifierFlags.contains(.control)) {
            // Right-click: Show native menu to allow quitting
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Quit ClipFlow", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
            statusItem?.popUpMenu(menu)
        } else {
            // Left-click: Toggle the main clipboard window
            toggleWindow()
        }
    }
    
    @objc private func openSettings() {
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
            forName: .clipFlowHotkeyFired,
            object: nil,
            queue: .main
        ) { @MainActor [weak self] _ in
            self?.toggleWindow()
        }
        
        NotificationCenter.default.addObserver(
            forName: .clipFlowCaptureHotkeyFired,
            object: nil,
            queue: .main
        ) { @MainActor [weak self] _ in
            self?.window?.orderOut(nil)
            ScreenCaptureService.shared.startCapture(forceImageOnly: false)
        }
        
        NotificationCenter.default.addObserver(
            forName: .clipFlowCaptureImageOnlyHotkeyFired,
            object: nil,
            queue: .main
        ) { @MainActor [weak self] _ in
            self?.window?.orderOut(nil)
            ScreenCaptureService.shared.startCapture(forceImageOnly: true)
        }
    }

    private func toggleWindow() {
        guard let win = window else {
            openMainWindow()
            return
        }
        if win.isVisible && NSApp.isActive {
            // Window is visible and app is front — hide it
            win.orderOut(nil)
        } else {
            // Reposition near cursor then bring forward
            moveWindowNearCursor(win)
            NotificationCenter.default.post(name: AppDelegate.windowWillOpenNotification, object: nil)
            win.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    private func openOnboardingWindow() {
        if let existing = onboardingWindow {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let viewModel = OnboardingViewModel()
        viewModel.onComplete = { [weak self] in
            self?.onboardingWindow?.close()
            self?.onboardingWindow = nil
            self?.openMainWindow()
        }
        
        let hostingController = NSHostingController(rootView: OnboardingView(viewModel: viewModel))
        
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        win.titlebarAppearsTransparent = true
        win.titleVisibility = .hidden
        win.isMovableByWindowBackground = true
        win.contentViewController = hostingController
        win.center()
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
        if let existing = window {
            existing.makeKeyAndOrderFront(nil)
            return
        }

        let panelView = MainPanelView(store: clipboardStore, onClose: { [weak self] in
            self?.window?.orderOut(nil)
        })

        let hostingController = NSHostingController(rootView: panelView)
        hostingController.view.setFrameSize(NSSize(width: 420, height: 560))

        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 560),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        win.title = "ClipFlow"
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

        // Hide all three traffic light buttons
        win.standardWindowButton(.closeButton)?.isHidden = true
        win.standardWindowButton(.miniaturizeButton)?.isHidden = true
        win.standardWindowButton(.zoomButton)?.isHidden = true

        moveWindowNearCursor(win)
        win.delegate = self
        NotificationCenter.default.post(name: AppDelegate.windowWillOpenNotification, object: nil)
        win.makeKeyAndOrderFront(nil)

        self.window = win
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
    
    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status == .notRegistered {
                    try SMAppService.mainApp.register()
                    print("Successfully registered to launch at login.")
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                    print("Successfully unregistered from launch at login.")
                }
            }
        } catch {
            print("Failed to set launch at login: \(error.localizedDescription)")
        }
    }
}
