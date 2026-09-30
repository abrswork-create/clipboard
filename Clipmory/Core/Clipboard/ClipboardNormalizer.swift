import Foundation

// MARK: - ClipboardNormalizer
// Produces a normalized searchable representation of clipboard content.
// Used for deduplication checks and search indexing.
// NEVER modifies or replaces the original content.

enum ClipboardNormalizer {

    /// Lowercases and collapses all whitespace into single spaces.
    static func normalize(_ text: String) -> String {
        text.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
