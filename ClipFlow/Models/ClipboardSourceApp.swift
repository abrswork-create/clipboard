import Foundation

// MARK: - ClipboardSourceApp
// Represents the application that was active when a clipboard item was captured.

struct ClipboardSourceApp: Codable, Hashable {
    let name: String
    let bundleIdentifier: String
}
