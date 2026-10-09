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

enum WindowShape: String, Codable, CaseIterable {
    case tall = "Tall"
    case broad = "Broad"
    
    var icon: String {
        switch self {
        case .tall: return "rectangle.portrait"
        case .broad: return "rectangle"
        }
    }
    
    var label: String {
        switch self {
        case .tall: return "Tall"
        case .broad: return "Broad"
        }
    }
    
    func dimensions(scale: Double) -> CGSize {
        let s = max(0.8, min(1.35, scale))
        switch self {
        case .tall:
            return CGSize(
                width: round(max(360, min(750, 420 * s))),
                height: round(max(460, min(900, 560 * s)))
            )
        case .broad:
            return CGSize(
                width: round(max(440, min(750, 560 * s))),
                height: round(max(420, min(900, 470 * s)))
            )
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try? container.decode(String.self)
        if raw == "Broad" {
            self = .broad
        } else {
            self = .tall
        }
    }
}

enum FileStorageMode: String, Codable, CaseIterable {
    case referenceOnly = "Store file reference only"
    case copyContents = "Copy file contents"
}

enum SensitiveContentAction: String, Codable, CaseIterable {
    case show = "Show"
    case hide = "Hide"
    case showFirstThree = "Show first 3 characters"
    case dontCopy = "Don't copy it"
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        switch raw {
        case "Show": self = .show
        case "Hide": self = .hide
        case "Show first 3 characters": self = .showFirstThree
        case "Don't copy it", "Don't save it", "Save temporarily", "Ask me": self = .dontCopy
        default: self = .dontCopy
        }
    }
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
    var windowShape: WindowShape = .tall
    var windowScale: Double = 1.0
    
    var effectiveWindowSize: CGSize {
        windowShape.dimensions(scale: windowScale)
    }

    // Privacy
    var excludedBundleIdentifiers: [String] = []
    var sensitiveContentDetection: Bool = true
    var sensitiveContentAction: SensitiveContentAction = .hide
    var requireAuthForSensitiveContent: Bool = true
    
    // Accessibility & Assistive
    var assistiveAutoInsert: Bool = true

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
    
    var screenCaptureImageOnlyShortcut: AppShortcut = AppShortcut(
        keyCode: 0x08, // C
        modifiers: UInt32(controlKey | optionKey | cmdKey),
        displayString: "⌃⌥⌘C"
    )

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        launchAtLogin = try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? true
        enableHistory = try container.decodeIfPresent(Bool.self, forKey: .enableHistory) ?? true
        showInMenuBar = try container.decodeIfPresent(Bool.self, forKey: .showInMenuBar) ?? true
        historyLimit = try container.decodeIfPresent(Int.self, forKey: .historyLimit) ?? 500
        saveText = try container.decodeIfPresent(Bool.self, forKey: .saveText) ?? true
        saveImages = try container.decodeIfPresent(Bool.self, forKey: .saveImages) ?? true
        saveFiles = try container.decodeIfPresent(Bool.self, forKey: .saveFiles) ?? true
        fileStorageMode = try container.decodeIfPresent(FileStorageMode.self, forKey: .fileStorageMode) ?? .referenceOnly
        deduplicateContent = try container.decodeIfPresent(Bool.self, forKey: .deduplicateContent) ?? true
        theme = try container.decodeIfPresent(AppTheme.self, forKey: .theme) ?? .system
        interfaceStyle = try container.decodeIfPresent(InterfaceStyle.self, forKey: .interfaceStyle) ?? .comfortable
        windowShape = try container.decodeIfPresent(WindowShape.self, forKey: .windowShape) ?? .tall
        windowScale = try container.decodeIfPresent(Double.self, forKey: .windowScale) ?? 1.0
        excludedBundleIdentifiers = try container.decodeIfPresent([String].self, forKey: .excludedBundleIdentifiers) ?? []
        sensitiveContentDetection = try container.decodeIfPresent(Bool.self, forKey: .sensitiveContentDetection) ?? true
        sensitiveContentAction = try container.decodeIfPresent(SensitiveContentAction.self, forKey: .sensitiveContentAction) ?? .hide
        requireAuthForSensitiveContent = try container.decodeIfPresent(Bool.self, forKey: .requireAuthForSensitiveContent) ?? true
        assistiveAutoInsert = try container.decodeIfPresent(Bool.self, forKey: .assistiveAutoInsert) ?? false
        autoDeleteHistory = try container.decodeIfPresent(AutoDeleteHistory.self, forKey: .autoDeleteHistory) ?? .sevenDays
        quickClipboardShortcut = try container.decodeIfPresent(AppShortcut.self, forKey: .quickClipboardShortcut) ?? AppShortcut(keyCode: 0x09, modifiers: UInt32(optionKey | cmdKey), displayString: "⌥⌘V")
        screenCaptureShortcut = try container.decodeIfPresent(AppShortcut.self, forKey: .screenCaptureShortcut) ?? AppShortcut(keyCode: 0x08, modifiers: UInt32(optionKey | cmdKey), displayString: "⌥⌘C")
        screenCaptureImageOnlyShortcut = try container.decodeIfPresent(AppShortcut.self, forKey: .screenCaptureImageOnlyShortcut) ?? AppShortcut(keyCode: 0x08, modifiers: UInt32(controlKey | optionKey | cmdKey), displayString: "⌃⌥⌘C")
    }
}

struct AppShortcut: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: UInt32
    var displayString: String
}
