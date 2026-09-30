import Foundation

#if !APP_STORE
import Sparkle
#endif

// MARK: - UpdateManager
// Handles app updates using Sparkle Framework (Direct Web releases only).
// In Mac App Store releases, updates are managed exclusively by macOS App Store.

@MainActor
final class UpdateManager: NSObject, ObservableObject {
    static let shared = UpdateManager()
    
    @Published var canCheckForUpdates: Bool = false
    @Published var automaticallyChecksForUpdates: Bool = true
    
#if !APP_STORE
    let updaterController: SPUStandardUpdaterController
    
    private override init() {
        self.updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        super.init()
        
        self.automaticallyChecksForUpdates = updaterController.updater.automaticallyChecksForUpdates
        
        updaterController.updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }
    
    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
    
    func setAutomaticallyChecksForUpdates(_ enabled: Bool) {
        automaticallyChecksForUpdates = enabled
        updaterController.updater.automaticallyChecksForUpdates = enabled
    }
#else
    private override init() {
        super.init()
        self.canCheckForUpdates = false
        self.automaticallyChecksForUpdates = false
    }
    
    func checkForUpdates() {}
    func setAutomaticallyChecksForUpdates(_ enabled: Bool) {}
#endif
}
