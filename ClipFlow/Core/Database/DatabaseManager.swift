import Foundation
import SQLite3

// MARK: - DatabaseManager
// Manages the SQLite connection and schema setup via the C API.
// Implemented in TASK 7.

final class DatabaseManager {
    static let shared = DatabaseManager()

    private(set) var db: OpaquePointer?

    private init() {}

    deinit {
        if let db = db {
            sqlite3_close(db)
        }
    }

    /// Opens the database connection.
    func open() throws {
        guard db == nil else { return }

        let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ClipFlow", isDirectory: true)

        if !FileManager.default.fileExists(atPath: supportDir.path) {
            try FileManager.default.createDirectory(at: supportDir, withIntermediateDirectories: true)
        }

        let dbPath = supportDir.appendingPathComponent("ClipFlow.sqlite").path

        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            let error = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.connectionFailed(error)
        }
    }
}
