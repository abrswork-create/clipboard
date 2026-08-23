import Foundation

// MARK: - AppSettings
// User-configurable application settings.
// Persisted in TASK 19 (Settings).

struct AppSettings: Codable {

    // General
    var launchAtLogin: Bool = false

    // Clipboard
    var historyLimit: Int = 500
    var saveImages: Bool = true
    var saveFiles: Bool = true
    var deduplicateContent: Bool = true

    // Privacy
    var privateModeEnabled: Bool = false
    var excludedBundleIdentifiers: [String] = []
    var warnOnSensitiveContent: Bool = true

    // Storage
    var historyRetentionDays: Int? = 30   // nil = never auto-delete

    // Shortcuts — stored as raw values; GlobalHotkeyManager interprets them.
    var quickClipboardShortcut: String = "cmd+shift+v"
}
