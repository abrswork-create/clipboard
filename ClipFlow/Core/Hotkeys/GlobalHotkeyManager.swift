import AppKit
import Carbon

// MARK: - GlobalHotkeyManager
// Registers a system-wide hotkey using the Carbon Event Manager.
// Works even when the app is in the background or hidden.
//
// Usage:
//   GlobalHotkeyManager.shared.register()
//
// Listen for activations via NotificationCenter:
//   .clipFlowHotkeyFired

final class GlobalHotkeyManager: @unchecked Sendable {

    // MARK: Shared Instance

    static let shared = GlobalHotkeyManager()

    // MARK: Private

    private var hotKeyRefs: [UInt32: EventHotKeyRef] = [:]
    private var eventHandlerRef: EventHandlerRef?

    // Carbon hotkey IDs
    private let quickClipboardID = EventHotKeyID(signature: OSType(0x434C4950), id: 1) // "CLIP"
    private let screenCaptureID = EventHotKeyID(signature: OSType(0x434C4950), id: 2)

    private init() {}

    // MARK: - Public API

    func register() {
        let settings = SettingsRepository.shared.load()
        
        installEventHandler()
        
        // Register Quick Clipboard
        let qc = settings.quickClipboardShortcut
        registerHotKey(id: quickClipboardID, keyCode: qc.keyCode, modifiers: qc.modifiers)
        
        // Register Screen Capture
        let sc = settings.screenCaptureShortcut
        registerHotKey(id: screenCaptureID, keyCode: sc.keyCode, modifiers: sc.modifiers)
    }

    func unregister() {
        for (_, ref) in hotKeyRefs {
            UnregisterEventHotKey(ref)
        }
        hotKeyRefs.removeAll()
        
        if let ref = eventHandlerRef {
            RemoveEventHandler(ref)
            eventHandlerRef = nil
        }
    }
    
    func rebind() {
        unregister()
        register()
    }

    // MARK: - Private

    private func installEventHandler() {
        guard eventHandlerRef == nil else { return }
        
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                     eventKind:  OSType(kEventHotKeyPressed))

        // Use a C-compatible trampoline via a global function pointer
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ -> OSStatus in
                GlobalHotkeyManager.shared.handleHotKeyEvent(event)
                return noErr
            },
            1,
            &eventType,
            nil,
            &eventHandlerRef
        )
    }

    private func registerHotKey(id: EventHotKeyID, keyCode: UInt32, modifiers: UInt32) {
        var ref: EventHotKeyRef?
        RegisterEventHotKey(keyCode, modifiers, id, GetApplicationEventTarget(), 0, &ref)
        if let ref = ref {
            hotKeyRefs[id.id] = ref
        }
    }

    private func handleHotKeyEvent(_ event: EventRef?) {
        var firedID = EventHotKeyID()
        guard let event,
              GetEventParameter(event,
                                EventParamName(kEventParamDirectObject),
                                EventParamType(typeEventHotKeyID),
                                nil,
                                MemoryLayout<EventHotKeyID>.size,
                                nil,
                                &firedID) == noErr
        else { return }

        DispatchQueue.main.async {
            if firedID.id == self.quickClipboardID.id {
                NotificationCenter.default.post(name: .clipFlowHotkeyFired, object: nil)
            } else if firedID.id == self.screenCaptureID.id {
                NotificationCenter.default.post(name: .clipFlowCaptureHotkeyFired, object: nil)
            }
        }
    }
}

// MARK: - Notification Name

extension Notification.Name {
    static let clipFlowHotkeyFired = Notification.Name("com.clipflow.hotkeyFired")
    static let clipFlowCaptureHotkeyFired = Notification.Name("com.clipflow.captureHotkeyFired")
}
