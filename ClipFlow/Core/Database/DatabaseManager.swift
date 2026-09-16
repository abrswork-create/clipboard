import Foundation
import SQLite3

// MARK: - DatabaseManager
// Manages the SQLite connection and schema setup via the C API.
// Implemented in TASK 7.

final class DatabaseManager: @unchecked Sendable {
    static let shared = DatabaseManager()

    private(set) var db: OpaquePointer?

    private init() {}

    deinit {
        if let db = db {
            sqlite3_close(db)
        }
    }

    /// Opens the database connection with WAL mode and concurrency protections.
    func open() throws {
        guard db == nil else { return }

        guard let supportBase = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw DatabaseError.connectionFailed("Application Support directory not accessible")
        }
        
        let supportDir = supportBase.appendingPathComponent("ClipFlow", isDirectory: true)

        if !FileManager.default.fileExists(atPath: supportDir.path) {
            try FileManager.default.createDirectory(at: supportDir, withIntermediateDirectories: true, attributes: [
                .posixPermissions: 0o700 // Restricted strictly to current macOS user
            ])
        } else {
            try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: supportDir.path)
        }

        let dbPath = supportDir.appendingPathComponent("ClipFlow.sqlite").path

        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            let error = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.connectionFailed(error)
        }
        
        // Secure database file permissions (owner read/write only: 0600)
        try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: dbPath)
        
        // Optimize for multi-threaded performance & prevent database lock errors
        sqlite3_exec(db, "PRAGMA journal_mode = WAL;", nil, nil, nil)
        sqlite3_exec(db, "PRAGMA busy_timeout = 5000;", nil, nil, nil)
        sqlite3_exec(db, "PRAGMA synchronous = NORMAL;", nil, nil, nil)
    }
}
