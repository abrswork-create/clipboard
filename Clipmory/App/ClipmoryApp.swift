import SwiftUI

@main
struct ClipmoryApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Clipmory is a menu bar only app.
        // The Settings window is managed programmatically via AppDelegate.
    }
}
