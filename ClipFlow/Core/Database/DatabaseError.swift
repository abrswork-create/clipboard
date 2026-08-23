import Foundation

// MARK: - DatabaseError
// Error types for database operations.
// Implemented in TASK 7.

enum DatabaseError: LocalizedError {
    case connectionFailed(String)
    case queryFailed(String)
    case migrationFailed(String)
    case notFound

    var errorDescription: String? {
        switch self {
        case .connectionFailed(let reason): return "Database connection failed: \(reason)"
        case .queryFailed(let reason):      return "Query failed: \(reason)"
        case .migrationFailed(let reason):  return "Migration failed: \(reason)"
        case .notFound:                     return "Record not found."
        }
    }
}
