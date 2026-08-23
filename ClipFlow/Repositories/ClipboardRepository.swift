import Foundation
import SQLite3

// MARK: - ClipboardRepository
// Reads and writes ClipboardItem records to the local database.
// Implemented in TASK 7.

final class ClipboardRepository {
    private let db: OpaquePointer?

    init(db: OpaquePointer? = DatabaseManager.shared.db) {
        self.db = db
    }

    // MARK: - Insert

    func insert(_ item: ClipboardItem) throws {
        guard let db = db else { throw DatabaseError.connectionFailed("No DB") }

        let query = """
        INSERT INTO clipboard_items (
            id, type, text_content, image_path, file_path, 
            created_at, updated_at, source_app_name, source_bundle_id, 
            content_hash, is_pinned, is_favorite
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
            updated_at = excluded.updated_at,
            is_pinned = excluded.is_pinned,
            is_favorite = excluded.is_favorite;
        """

        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }

        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) != SQLITE_OK {
            throw DatabaseError.queryFailed("Prepare insert failed")
        }

        let typeStr = String(describing: item.type)

        sqlite3_bind_text(stmt, 1, (item.id.uuidString as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 2, (typeStr as NSString).utf8String, -1, nil)
        
        bindText(stmt, 3, item.text)
        bindText(stmt, 4, item.imagePath)
        bindText(stmt, 5, item.filePath)
        
        sqlite3_bind_double(stmt, 6, item.createdAt.timeIntervalSince1970)
        sqlite3_bind_double(stmt, 7, item.updatedAt.timeIntervalSince1970)
        
        bindText(stmt, 8, item.sourceAppName)
        bindText(stmt, 9, item.sourceBundleIdentifier)
        bindText(stmt, 10, item.contentHash)
        
        sqlite3_bind_int(stmt, 11, item.isPinned ? 1 : 0)
        sqlite3_bind_int(stmt, 12, item.isFavorite ? 1 : 0)

        if sqlite3_step(stmt) != SQLITE_DONE {
            throw DatabaseError.queryFailed("Execute insert failed")
        }
    }

    // MARK: - Fetch All

    func fetchAll() throws -> [ClipboardItem] {
        guard let db = db else { throw DatabaseError.connectionFailed("No DB") }

        let query = "SELECT * FROM clipboard_items ORDER BY updated_at DESC;"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }

        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) != SQLITE_OK {
            throw DatabaseError.queryFailed("Prepare fetchAll failed")
        }

        var items: [ClipboardItem] = []

        while sqlite3_step(stmt) == SQLITE_ROW {
            if let idStr = text(stmt, 0), let id = UUID(uuidString: idStr),
               let typeStr = text(stmt, 1) {
                
                let type: ClipboardType
                switch typeStr {
                case "text": type = .text
                case "richText": type = .richText
                case "url": type = .url
                case "image": type = .image
                case "file": type = .file
                default: type = .unknown
                }

                let item = ClipboardItem(
                    id: id,
                    type: type,
                    createdAt: Date(timeIntervalSince1970: sqlite3_column_double(stmt, 5)),
                    updatedAt: Date(timeIntervalSince1970: sqlite3_column_double(stmt, 6)),
                    text: text(stmt, 2),
                    imagePath: text(stmt, 3),
                    filePath: text(stmt, 4),
                    sourceAppName: text(stmt, 7),
                    sourceBundleIdentifier: text(stmt, 8),
                    isPinned: sqlite3_column_int(stmt, 10) == 1,
                    isFavorite: sqlite3_column_int(stmt, 11) == 1,
                    contentHash: text(stmt, 9)
                )
                items.append(item)
            }
        }
        return items
    }

    // MARK: - Delete

    func delete(_ id: UUID) throws {
        guard let db = db else { throw DatabaseError.connectionFailed("No DB") }

        let query = "DELETE FROM clipboard_items WHERE id = ?;"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }

        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) != SQLITE_OK {
            throw DatabaseError.queryFailed("Prepare delete failed")
        }

        sqlite3_bind_text(stmt, 1, (id.uuidString as NSString).utf8String, -1, nil)

        if sqlite3_step(stmt) != SQLITE_DONE {
            throw DatabaseError.queryFailed("Execute delete failed")
        }
    }

    // MARK: - Update Flags

    func updatePinned(id: UUID, isPinned: Bool) throws {
        try updateFlag(id: id, column: "is_pinned", value: isPinned)
    }

    func updateFavorite(id: UUID, isFavorite: Bool) throws {
        try updateFlag(id: id, column: "is_favorite", value: isFavorite)
    }

    private func updateFlag(id: UUID, column: String, value: Bool) throws {
        guard let db = db else { throw DatabaseError.connectionFailed("No DB") }

        let query = "UPDATE clipboard_items SET \(column) = ? WHERE id = ?;"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }

        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) != SQLITE_OK {
            throw DatabaseError.queryFailed("Prepare update \(column) failed")
        }

        sqlite3_bind_int(stmt, 1, value ? 1 : 0)
        sqlite3_bind_text(stmt, 2, (id.uuidString as NSString).utf8String, -1, nil)

        if sqlite3_step(stmt) != SQLITE_DONE {
            throw DatabaseError.queryFailed("Execute update \(column) failed")
        }
    }

    // MARK: - Helpers

    private func bindText(_ stmt: OpaquePointer?, _ index: Int32, _ value: String?) {
        if let value = value {
            sqlite3_bind_text(stmt, index, (value as NSString).utf8String, -1, nil)
        } else {
            sqlite3_bind_null(stmt, index)
        }
    }

    private func text(_ stmt: OpaquePointer?, _ index: Int32) -> String? {
        if let cString = sqlite3_column_text(stmt, index) {
            return String(cString: cString)
        }
        return nil
    }
}
