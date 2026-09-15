import Foundation
import Sparkle

// MARK: - UpdateManager
// Handles app updates using Sparkle Framework (SPUStandardUpdaterController).

@MainActor
final class UpdateManager: NSObject, ObservableObject {
    static let shared = UpdateManager()
    
    let updaterController: SPUStandardUpdaterController
    
    @Published var canCheckForUpdates: Bool = false
    @Published var automaticallyChecksForUpdates: Bool = true
    
    private override init() {
        // SPUStandardUpdaterController automatically manages update UI, checks, and downloads
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
}
