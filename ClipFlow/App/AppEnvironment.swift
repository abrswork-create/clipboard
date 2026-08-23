import Foundation

// MARK: - AppEnvironment
// Holds application-wide dependencies.
// Populated during startup and injected where needed.
// Concrete services are wired in later tasks.
//
// @unchecked Sendable: All stored properties are immutable (let) after init,
// making concurrent access safe. @unchecked is required because the class
// inherits from AnyObject which is not automatically Sendable.

final class AppEnvironment: @unchecked Sendable {

    // MARK: Shared Instance
    // AppEnvironment is used as a single source of truth for dependency
    // resolution. It is NOT a global singleton that services call into;
    // dependencies are injected at initialisation time.

    static let shared = AppEnvironment()

    // MARK: Properties

    /// Application version string read from the bundle.
    let appVersion: String = {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }()

    /// Build number read from the bundle.
    let buildNumber: String = {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }()

    /// File URL to the Application Support directory for ClipFlow.
    let applicationSupportURL: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("ClipFlow", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    // MARK: Init

    private init() {}
}
