import SwiftUI
import AppKit
import Carbon

struct ShortcutRecorderView: View {
    @Binding var shortcut: AppShortcut
    let onShortcutChanged: () -> Void
    
    @State private var isRecording = false
    @State private var eventMonitor: Any?
    
    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                if isRecording {
                    Text("Recording...")
                        .foregroundColor(.secondary)
                } else {
                    Text(shortcut.displayString)
                }
            }
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isRecording ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: isRecording ? 2 : 1)
            )
            
            Button(isRecording ? "Cancel" : "Change...") {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            }
        }
        .onDisappear {
            stopRecording()
        }
    }
    
    private func startRecording() {
        isRecording = true
        
        // Listen to local key down events
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handleKeyPress(event)
            return nil // Consume event
        }
    }
    
    private func stopRecording() {
        isRecording = false
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
    
    private func handleKeyPress(_ event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        
        // We require at least one modifier (Command, Option, or Control) so the user doesn't bind a plain character
        let hasModifier = flags.contains(.command) || flags.contains(.option) || flags.contains(.control)
        
        if !hasModifier {
            // If they pressed Escape without modifiers, cancel recording
            if event.keyCode == 53 {
                stopRecording()
            } else {
                NSSound.beep() // invalid shortcut
            }
            return
        }
        
        // Extract Carbon modifiers
        var carbonFlags: UInt32 = 0
        var displayString = ""
        
        if flags.contains(.control) {
            carbonFlags |= UInt32(controlKey)
            displayString += "⌃"
        }
        if flags.contains(.option) {
            carbonFlags |= UInt32(optionKey)
            displayString += "⌥"
        }
        if flags.contains(.shift) {
            carbonFlags |= UInt32(shiftKey)
            displayString += "⇧"
        }
        if flags.contains(.command) {
            carbonFlags |= UInt32(cmdKey)
            displayString += "⌘"
        }
        
        // Get the character for the key code
        let characters = event.charactersIgnoringModifiers?.uppercased() ?? ""
        displayString += characters
        
        let newShortcut = AppShortcut(
            keyCode: UInt32(event.keyCode),
            modifiers: carbonFlags,
            displayString: displayString
        )
        
        self.shortcut = newShortcut
        self.onShortcutChanged()
        
        stopRecording()
    }
}
