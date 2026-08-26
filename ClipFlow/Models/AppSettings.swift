import Foundation
import Carbon

// MARK: - AppSettings
// User-configurable application settings.
// Persisted in TASK 19 (Settings).

enum AppTheme: String, Codable, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    case system = "System" // changed from "Auto" based on user spec
}

enum InterfaceStyle: String, Codable, CaseIterable {
    case compact = "Compact"
    case comfortable = "Comfortable"
    case spacious = "Spacious"
}

enum FileStorageMode: String, Codable, CaseIterable {
    case referenceOnly = "Store file reference only"
    case copyContents = "Copy file contents"
}

enum SensitiveContentAction: String, Codable, CaseIterable {
    case dontSave = "Don't save it"
    case saveTemporarily = "Save temporarily"
    case askMe = "Ask me"
}

enum AutoDeleteHistory: Int, Codable, CaseIterable {
    case never = 0
    case oneHour = 1
    case oneDay = 24
    case sevenDays = 168
    case thirtyDays = 720
    
    var label: String {
        switch self {
        case .never: return "Never"
        case .oneHour: return "After 1 hour"
        case .oneDay: return "After 1 day"
        case .sevenDays: return "After 7 days"
        case .thirtyDays: return "After 30 days"
        }
    }
}

struct AppSettings: Codable {

    // General
    var launchAtLogin: Bool = true
    var enableHistory: Bool = true // New
    var showInMenuBar: Bool = true // New

    // Clipboard
    var historyLimit: Int = 500
    var saveText: Bool = true // New
    var saveImages: Bool = true
    var saveFiles: Bool = true
    var fileStorageMode: FileStorageMode = .referenceOnly // New
    var deduplicateContent: Bool = true

    // Appearance
    var theme: AppTheme = .system
    var interfaceStyle: InterfaceStyle = .comfortable // New

    // Privacy
    var excludedBundleIdentifiers: [String] = []
    var sensitiveContentDetection: Bool = true // New
    var sensitiveContentAction: SensitiveContentAction = .dontSave // New
    
    // Auto-Delete
    var autoDeleteHistory: AutoDeleteHistory = .sevenDays // New

    // Shortcuts
    var quickClipboardShortcut: AppShortcut = AppShortcut(
        keyCode: 0x09, // V
        modifiers: UInt32(optionKey | cmdKey),
        displayString: "⌥⌘V"
    )
    
    var screenCaptureShortcut: AppShortcut = AppShortcut(
        keyCode: 0x08, // C
        modifiers: UInt32(optionKey | cmdKey),
        displayString: "⌥⌘C"
    )
}

struct AppShortcut: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: UInt32
    var displayString: String
}
