import Foundation

// MARK: - ClipboardCollection
// Named groups of clipboard items (V2 feature).
// Defined here as a stub to reserve the namespace.

struct ClipboardCollection: Identifiable, Codable {
    let id: UUID
    var name: String
    var itemIDs: [UUID]
    let createdAt: Date
}
