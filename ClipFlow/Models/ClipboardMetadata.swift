import Foundation

// MARK: - ClipboardMetadata
// Additional metadata attached to a clipboard item.
// Implemented in TASK 3.

struct ClipboardMetadata: Codable, Hashable {
    var fileSize: Int?
    var previewText: String?
    var isSensitive: Bool = false
}
