import Foundation

// MARK: - PermissionStatus
// Represents the current status of a macOS permission.

enum PermissionStatus {
    case notDetermined
    case granted
    case denied
    case restricted
}
