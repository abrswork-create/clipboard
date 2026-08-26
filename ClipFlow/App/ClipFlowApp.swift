import SwiftUI

@main
struct ClipFlowApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // ClipFlow is a menu bar only app.
        // The Settings window is managed programmatically via AppDelegate.
    }
}
