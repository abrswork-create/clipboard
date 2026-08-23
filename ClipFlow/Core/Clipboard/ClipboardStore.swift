import Combine
import Foundation

// MARK: - ClipboardStore (TASK 6 + TASK 10)
// @MainActor ObservableObject that holds all clipboard items in memory.
// Acts as the single source of truth between ClipboardMonitor and the UI.
// Handles deduplication via SHA-256 content hash (TASK 10).

@MainActor
final class ClipboardStore: ObservableObject {

    // MARK: Published State

    @Published private(set) var items: [ClipboardItem] = []
    private let repository = ClipboardRepository()

    // MARK: - Init

    init() {
        loadFromDatabase()
    }

    private func loadFromDatabase() {
        do {
            items = try repository.fetchAll()
        } catch {
            print("Failed to load from database: \(error)")
        }
    }

    // MARK: - Add (with deduplication)

    /// Inserts a new item, or bubbles an existing duplicate to the top.
    func add(_ item: ClipboardItem) {
        // Deduplicate: same content hash → move existing entry to top, update timestamp
        if let hash = item.contentHash,
           let existingIndex = items.firstIndex(where: { $0.contentHash == hash }) {
            var existing = items.remove(at: existingIndex)
            existing.updatedAt = Date()
            items.insert(existing, at: 0)
            
            do { try repository.insert(existing) }
            catch { print("Failed to update item in DB: \(error)") }
            
            return
        }
        // New item: insert newest-first
        items.insert(item, at: 0)
        
        do { try repository.insert(item) }
        catch { print("Failed to insert item to DB: \(error)") }
    }

    // MARK: - Delete

    func delete(_ id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        // Also clean up image file from disk if present
        if let path = items[index].imagePath {
            FileStorage.delete(at: path)
        }
        
        do { try repository.delete(id) }
        catch { print("Failed to delete item from DB: \(error)") }
        
        items.remove(at: index)
    }

    // MARK: - Pin

    func togglePin(_ id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        
        var updatedItems = items
        updatedItems[index].isPinned.toggle()
        self.items = updatedItems
        
        do { try repository.updatePinned(id: id, isPinned: items[index].isPinned) }
        catch { print("Failed to update pin in DB: \(error)") }
    }

    // MARK: - Favorite

    func toggleFavorite(_ id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        
        var updatedItems = items
        updatedItems[index].isFavorite.toggle()
        self.items = updatedItems
        
        do { try repository.updateFavorite(id: id, isFavorite: items[index].isFavorite) }
        catch { print("Failed to update favorite in DB: \(error)") }
    }

    // MARK: - Clear

    /// Removes all non-pinned items. Pinned items are preserved.
    func clearAll() {
        let toDelete = items.filter { !$0.isPinned }
        toDelete.forEach { item in
            if let path = item.imagePath { FileStorage.delete(at: path) }
            do { try repository.delete(item.id) }
            catch { print("Failed to delete item from DB on clear: \(error)") }
        }
        items.removeAll { !$0.isPinned }
    }
}
