import Foundation

// MARK: - ClipboardType
// Classifies the content type of a clipboard item.
// V1 supports: text, richText, url, image, file, unknown.

enum ClipboardType: String, Codable, CaseIterable {
    case text
    case richText
    case url
    case image
    case file
    case unknown
}
