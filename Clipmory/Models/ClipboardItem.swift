import Foundation
import AppKit

// MARK: - ClipboardItem
// Core data model representing a single clipboard history entry.

struct ClipboardItem: Identifiable, Codable, Hashable {
    let id: UUID
    let type: ClipboardType
    let createdAt: Date
    var updatedAt: Date

    var text: String?
    var imagePath: String?
    var filePath: String?

    var sourceAppName: String?
    var sourceBundleIdentifier: String?

    var isPinned: Bool
    var isFavorite: Bool
    var isSensitive: Bool
    var contentHash: String?

    init(
        id: UUID = UUID(),
        type: ClipboardType,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        text: String? = nil,
        imagePath: String? = nil,
        filePath: String? = nil,
        sourceAppName: String? = nil,
        sourceBundleIdentifier: String? = nil,
        isPinned: Bool = false,
        isFavorite: Bool = false,
        isSensitive: Bool = false,
        contentHash: String? = nil
    ) {
        self.id = id
        self.type = type
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.text = text
        self.imagePath = imagePath
        self.filePath = filePath
        self.sourceAppName = sourceAppName
        self.sourceBundleIdentifier = sourceBundleIdentifier
        self.isPinned = isPinned
        self.isFavorite = isFavorite
        self.isSensitive = isSensitive
        self.contentHash = contentHash
    }
}

// MARK: - GIF Helpers

extension ClipboardItem {
    var isGif: Bool {
        if let path = imagePath, path.lowercased().hasSuffix(".gif") {
            return true
        }
        return gifURLString != nil
    }

    var gifURLString: String? {
        guard let text = text?.trimmingCharacters(in: .whitespacesAndNewlines) else { return nil }
        let lower = text.lowercased()
        guard lower.hasPrefix("http://") || lower.hasPrefix("https://") else { return nil }
        if lower.hasSuffix(".gif") ||
           lower.contains(".gif?") ||
           lower.contains("media.giphy.com/media/") ||
           lower.contains("i.giphy.com/") ||
           lower.contains("c.tenor.com/") ||
           lower.contains("tenor.com/view/") {
            return text
        }
        return nil
    }
}

// MARK: - Drag and Drop Support

extension ClipboardItem {
    func makeItemProvider() -> NSItemProvider {
        // 1. Files or local images on disk
        if let path = self.filePath ?? self.imagePath, FileManager.default.fileExists(atPath: path) {
            let fileURL = URL(fileURLWithPath: path)
            let provider = NSItemProvider(contentsOf: fileURL) ?? NSItemProvider()
            
            // Also register NSImage for drop targets that accept image objects directly
            if let image = FileStorage.loadImage(at: path) ?? NSImage(contentsOfFile: path) {
                provider.registerObject(image, visibility: .all)
            }
            
            // Register text fallback
            if let text = self.text, !text.isEmpty {
                provider.registerObject(text as NSString, visibility: .all)
            }
            
            return provider
        }
        
        // 2. Web URLs or remote GIFs
        if (self.type == .url || self.isGif), let text = self.text, let url = URL(string: text), url.scheme != nil {
            let provider = NSItemProvider(object: url as NSURL)
            provider.registerObject(text as NSString, visibility: .all)
            return provider
        }
        
        // 3. Plain Text / Code / General strings
        if let text = self.text {
            return NSItemProvider(object: text as NSString)
        }
        
        return NSItemProvider()
    }
    
    static func makeItemProvider(for items: [ClipboardItem]) -> NSItemProvider {
        guard !items.isEmpty else { return NSItemProvider() }
        if items.count == 1 {
            return items[0].makeItemProvider()
        }
        
        // 1. Files / Local Images on disk
        let fileURLs: [URL] = items.compactMap { item in
            if let path = item.filePath ?? item.imagePath, FileManager.default.fileExists(atPath: path) {
                return URL(fileURLWithPath: path)
            }
            return nil
        }
        
        // 2. Texts / URLs
        let texts: [String] = items.compactMap { item in
            if let text = item.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return text
            }
            return nil
        }
        
        // Pure text collection: provide direct plain text provider so all target apps paste all items
        if fileURLs.isEmpty && !texts.isEmpty {
            let combined = texts.joined(separator: "\n")
            return NSItemProvider(object: combined as NSString)
        }
        
        // Mixed or file collection
        let provider = NSItemProvider()
        for url in fileURLs {
            provider.registerObject(url as NSURL, visibility: .all)
        }
        
        if !texts.isEmpty {
            let combined = texts.joined(separator: "\n")
            provider.registerObject(combined as NSString, visibility: .all)
        }
        
        return provider
    }
}

// MARK: - Mock Data

extension ClipboardItem {
    static let mockItems: [ClipboardItem] = [
        ClipboardItem(
            id: UUID(),
            type: .text,
            createdAt: Date().addingTimeInterval(-60),
            updatedAt: Date().addingTimeInterval(-60),
            text: "Microsoft 365\nTurn your ideas into reality, stay safer online and off, and focus on what matters most",
            sourceAppName: "Safari",
            sourceBundleIdentifier: "com.apple.Safari",
            isPinned: true,
            isFavorite: false
        ),
        ClipboardItem(
            id: UUID(),
            type: .text,
            createdAt: Date().addingTimeInterval(-300),
            updatedAt: Date().addingTimeInterval(-300),
            text: "Sales Rep\tJan\tFeb\tMar\tApr\tMay",
            sourceAppName: "Numbers",
            sourceBundleIdentifier: "com.apple.Numbers",
            isPinned: false,
            isFavorite: false
        ),
        ClipboardItem(
            id: UUID(),
            type: .text,
            createdAt: Date().addingTimeInterval(-900),
            updatedAt: Date().addingTimeInterval(-900),
            text: "Apple Keynote Topic Outline for Accelerating Growth in Q4 — draft v2",
            sourceAppName: "Keynote",
            sourceBundleIdentifier: "com.apple.Keynote",
            isPinned: false,
            isFavorite: true
        ),
        ClipboardItem(
            id: UUID(),
            type: .url,
            createdAt: Date().addingTimeInterval(-1800),
            updatedAt: Date().addingTimeInterval(-1800),
            text: "https://developer.apple.com/documentation/swiftui",
            sourceAppName: "Safari",
            sourceBundleIdentifier: "com.apple.Safari",
            isPinned: false,
            isFavorite: false
        ),
        ClipboardItem(
            id: UUID(),
            type: .text,
            createdAt: Date().addingTimeInterval(-3600),
            updatedAt: Date().addingTimeInterval(-3600),
            text: "let greeting = \"Hello, World!\"\nprint(greeting)",
            sourceAppName: "Xcode",
            sourceBundleIdentifier: "com.apple.dt.Xcode",
            isPinned: false,
            isFavorite: false
        ),
        ClipboardItem(
            id: UUID(),
            type: .text,
            createdAt: Date().addingTimeInterval(-7200),
            updatedAt: Date().addingTimeInterval(-7200),
            text: "Meeting notes: Discussed Q4 roadmap, assigned action items to design and engineering teams.",
            sourceAppName: "Notes",
            sourceBundleIdentifier: "com.apple.Notes",
            isPinned: false,
            isFavorite: false
        ),
    ]
}
