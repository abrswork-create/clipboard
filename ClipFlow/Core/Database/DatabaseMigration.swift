import Foundation
import SQLite3

// MARK: - DatabaseMigration
// Handles versioned SQLite schema migrations.
// Implemented in TASK 8.

enum DatabaseMigration {

    /// Runs all necessary migrations to bring the database up to the current schema.
    static func migrate(db: OpaquePointer?) throws {
        guard let db = db else { throw DatabaseError.connectionFailed("No database connection") }

        let currentVersion = try getUserVersion(db: db)
        
        if currentVersion < 1 {
            try runMigration1(db: db)
            try setUserVersion(db: db, version: 1)
        }
        
        // Future migrations go here: if currentVersion < 2, etc.
    }

    private static func getUserVersion(db: OpaquePointer?) throws -> Int {
        var statement: OpaquePointer?
        let query = "PRAGMA user_version;"
        
        defer { sqlite3_finalize(statement) }
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                return Int(sqlite3_column_int(statement, 0))
            }
        }
        throw DatabaseError.queryFailed("Could not read user_version")
    }

    private static func setUserVersion(db: OpaquePointer?, version: Int) throws {
        var errorMsg: UnsafeMutablePointer<CChar>?
        let query = "PRAGMA user_version = \(version);"
        
        if sqlite3_exec(db, query, nil, nil, &errorMsg) != SQLITE_OK {
            let errorString = errorMsg.map { String(cString: $0) } ?? "Unknown error"
            sqlite3_free(errorMsg)
            throw DatabaseError.migrationFailed("Could not set user_version: \(errorString)")
        }
    }

    // MARK: - Migrations

    private static func runMigration1(db: OpaquePointer?) throws {
        let query = """
        CREATE TABLE IF NOT EXISTS clipboard_items (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            text_content TEXT,
            image_path TEXT,
            file_path TEXT,
            created_at REAL NOT NULL,
            updated_at REAL NOT NULL,
            source_app_name TEXT,
            source_bundle_id TEXT,
            content_hash TEXT,
            is_pinned INTEGER NOT NULL DEFAULT 0,
            is_favorite INTEGER NOT NULL DEFAULT 0,
            file_size INTEGER,
            preview_text TEXT
        );
        
        CREATE INDEX IF NOT EXISTS idx_created_at ON clipboard_items(created_at);
        CREATE INDEX IF NOT EXISTS idx_content_hash ON clipboard_items(content_hash);
        CREATE INDEX IF NOT EXISTS idx_type ON clipboard_items(type);
        CREATE INDEX IF NOT EXISTS idx_source_bundle_id ON clipboard_items(source_bundle_id);
        CREATE INDEX IF NOT EXISTS idx_is_pinned ON clipboard_items(is_pinned);
        CREATE INDEX IF NOT EXISTS idx_is_favorite ON clipboard_items(is_favorite);
        """
        
        var errorMsg: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(db, query, nil, nil, &errorMsg) != SQLITE_OK {
            let errorString = errorMsg.map { String(cString: $0) } ?? "Unknown error"
            sqlite3_free(errorMsg)
            throw DatabaseError.migrationFailed("Migration 1 failed: \(errorString)")
        }
    }
}
