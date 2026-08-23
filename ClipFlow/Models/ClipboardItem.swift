import Foundation

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

    var contentHash: String?
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
