import Foundation

// MARK: - HotkeyError
// Error types for hotkey registration failures.
// Implemented in TASK 16.

enum HotkeyError: LocalizedError {
    case registrationFailed
    case conflictingShortcut

    var errorDescription: String? {
        switch self {
        case .registrationFailed:    return "Failed to register global hotkey."
        case .conflictingShortcut:   return "The selected shortcut conflicts with another application."
        }
    }
}
