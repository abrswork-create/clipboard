import AppKit
import CryptoKit
import Foundation

// MARK: - ContentHasher (TASK 10)
// Generates a SHA-256 hex digest used for deduplication.
// Identical clipboard content produces identical hashes.

enum ContentHasher {

    static func hash(string: String) -> String {
        hash(data: Data(string.utf8))
    }

    static func hash(data: Data) -> String {
        SHA256.hash(data: data)
            .map { String(format: "%02x", $0) }
            .joined()
    }
}

// MARK: - ClipboardReader (TASK 4)
// Reads the current NSPasteboard state and returns a typed ClipboardItem.
// Must be called on the main thread (NSPasteboard is not thread-safe).
// Priority order: image > richText > url > text > file.

@MainActor
final class ClipboardReader {

    func read(from pasteboard: NSPasteboard,
              sourceApp: NSRunningApplication?) -> ClipboardItem? {

        let type = ClipboardClassifier.classify(pasteboard: pasteboard)

        switch type {
        case .image:    return readImage(from: pasteboard, sourceApp: sourceApp)
        case .richText: return readRichText(from: pasteboard, sourceApp: sourceApp)
        case .url:      return readText(from: pasteboard, type: .url, sourceApp: sourceApp)
        case .text:     return readText(from: pasteboard, type: .text, sourceApp: sourceApp)
        case .file:     return readFile(from: pasteboard, sourceApp: sourceApp)
        case .unknown:  return nil
        }
    }

    // MARK: - Text / URL

    private func readText(from pasteboard: NSPasteboard,
                          type: ClipboardType,
                          sourceApp: NSRunningApplication?) -> ClipboardItem? {

        guard let text = pasteboard.string(forType: .string),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return nil }

        let now = Date()
        return ClipboardItem(
            id: UUID(),
            type: type,
            createdAt: now,
            updatedAt: now,
            text: text,
            sourceAppName: sourceApp?.localizedName,
            sourceBundleIdentifier: sourceApp?.bundleIdentifier,
            isPinned: false,
            isFavorite: false,
            contentHash: ContentHasher.hash(string: text)
        )
    }

    // MARK: - Rich Text

    private func readRichText(from pasteboard: NSPasteboard,
                              sourceApp: NSRunningApplication?) -> ClipboardItem? {

        let plainText: String?

        if let rtfData = pasteboard.data(forType: .rtf),
           let attributed = NSAttributedString(rtf: rtfData, documentAttributes: nil) {
            plainText = attributed.string
        } else {
            plainText = pasteboard.string(forType: .string)
        }

        guard let text = plainText,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return nil }

        let now = Date()
        return ClipboardItem(
            id: UUID(),
            type: .richText,
            createdAt: now,
            updatedAt: now,
            text: text,
            sourceAppName: sourceApp?.localizedName,
            sourceBundleIdentifier: sourceApp?.bundleIdentifier,
            isPinned: false,
            isFavorite: false,
            contentHash: ContentHasher.hash(string: text)
        )
    }

    // MARK: - Image

    private func readImage(from pasteboard: NSPasteboard,
                           sourceApp: NSRunningApplication?) -> ClipboardItem? {

        guard let image = NSImage(pasteboard: pasteboard) else { return nil }

        let savedPath = FileStorage.saveImage(image)
        let hash: String? = image.tiffRepresentation.map { ContentHasher.hash(data: $0) }
        let now = Date()

        return ClipboardItem(
            id: UUID(),
            type: .image,
            createdAt: now,
            updatedAt: now,
            imagePath: savedPath,
            sourceAppName: sourceApp?.localizedName,
            sourceBundleIdentifier: sourceApp?.bundleIdentifier,
            isPinned: false,
            isFavorite: false,
            contentHash: hash
        )
    }

    // MARK: - File

    private func readFile(from pasteboard: NSPasteboard,
                          sourceApp: NSRunningApplication?) -> ClipboardItem? {

        guard let urls = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL],
              let url = urls.first
        else { return nil }

        let path = url.path
        let now  = Date()

        return ClipboardItem(
            id: UUID(),
            type: .file,
            createdAt: now,
            updatedAt: now,
            text: url.lastPathComponent,
            filePath: path,
            sourceAppName: sourceApp?.localizedName,
            sourceBundleIdentifier: sourceApp?.bundleIdentifier,
            isPinned: false,
            isFavorite: false,
            contentHash: ContentHasher.hash(string: path)
        )
    }
}
