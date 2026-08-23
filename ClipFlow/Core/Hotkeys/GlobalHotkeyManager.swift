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

final class GlobalHotkeyManager {

    // MARK: Shared Instance

    static let shared = GlobalHotkeyManager()

    // MARK: Private

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    // Carbon hotkey ID
    private let hotkeyID = EventHotKeyID(signature: OSType(0x434C4950), id: 1) // "CLIP"

    // Option (⌥) + Command (⌘) + V
    // kVK_ANSI_V = 0x09
    private let keyCode:   UInt32 = 0x09
    private let modifiers: UInt32 = UInt32(optionKey | cmdKey)

    private init() {}

    // MARK: - Public API

    func register() {
        installEventHandler()
        registerHotKey()
    }

    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let ref = eventHandlerRef {
            RemoveEventHandler(ref)
            eventHandlerRef = nil
        }
    }

    // MARK: - Private

    private func installEventHandler() {
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

    private func registerHotKey() {
        var id = hotkeyID
        RegisterEventHotKey(keyCode, modifiers, id, GetApplicationEventTarget(), 0, &hotKeyRef)
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
                                &firedID) == noErr,
              firedID.id == hotkeyID.id
        else { return }

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .clipFlowHotkeyFired, object: nil)
        }
    }
}

// MARK: - Notification Name

extension Notification.Name {
    static let clipFlowHotkeyFired = Notification.Name("com.clipflow.hotkeyFired")
}
