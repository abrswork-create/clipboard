import SwiftUI

@main
struct ClipFlowApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // ClipFlow is a menu bar only app.
        // The Settings window is opened programmatically from AppDelegate.
        Settings {
            EmptyView()
        }
    }
}
