import AppKit
import Foundation

// MARK: - ClipboardClassifier
// Inspects an NSPasteboard and determines the best ClipboardType.
// Priority: image > richText > url > text > file > unknown.

enum ClipboardClassifier {

    static func classify(pasteboard: NSPasteboard) -> ClipboardType {
        let types = Set(pasteboard.types ?? [])

        // Image — TIFF, PNG
        if types.contains(.tiff) || types.contains(.png) {
            return .image
        }

        // Rich text — RTF
        if types.contains(.rtf) || types.contains(NSPasteboard.PasteboardType("public.rtf")) {
            return .richText
        }

        // URL — check string content
        if let string = pasteboard.string(forType: .string), isHTTPURL(string) {
            return .url
        }

        // Plain text
        if types.contains(.string) {
            return .text
        }

        // File URL
        if types.contains(.fileURL) {
            return .file
        }

        return .unknown
    }

    // MARK: - Helpers

    static func isHTTPURL(_ string: String) -> Bool {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed) else { return false }
        return url.scheme == "http" || url.scheme == "https" || url.scheme == "ftp"
    }
}
